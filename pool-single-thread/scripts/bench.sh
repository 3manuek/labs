#!/usr/bin/env bash
# =============================================================================
# pool-single-thread benchmark runner (bash 3.2 compatible -> stock macOS bash)
#
#   bench.sh run       run every pending cell of the matrix (idempotent, resumable)
#   bench.sh status    show the ledger of a run
#   bench.sh pause     graceful pause: finish current cell, then stop   (NOW=1: abort cell)
#   bench.sh resume    clear the pause flag and continue `run`
#   bench.sh summary   rebuild results/<RUN>/summary.csv from the cell results
#
# A "cell" = one (workload, clients, repeat, target) combination. Its state lives in
# results/<RUN>/state.tsv  (cell <TAB> status <TAB> attempts <TAB> updated_at)
#   pending -> running -> done | failed       (running/aborted cells fall back to pending)
# =============================================================================
set -euo pipefail

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$LAB_DIR"

# --------------------------------------------------------------------- config
# Infra settings (.env) — only for vars not already exported (Makefile exports them)
if [ -f .env ]; then
  while IFS='=' read -r k v; do
    case "$k" in ''|\#*) continue ;; esac
    eval "cur=\${$k:-}"
    [ -z "$cur" ] && export "$k=$v"
  done < .env
fi

RUN="${RUN:-default}"
RUN_DIR="results/${RUN}"
STATE="${RUN_DIR}/state.tsv"
CFG="${RUN_DIR}/config.env"
PAUSE_FLAG="${RUN_DIR}/.pause"
LOCK="${RUN_DIR}/.lock"
BENCH_PARAMS="TARGETS WORKLOADS CLIENTS REPEATS PROTOCOL DURATION WARMUP JOBS SAMPLING W3_SPAN W3_SLEEP_MS MAX_TRIES"

# Parameters: command line/env  >  saved run config  >  defaults
# allow comma separated lists (make bench CLIENTS=32,128)
TARGETS="${TARGETS:-}"; WORKLOADS="${WORKLOADS:-}"; CLIENTS="${CLIENTS:-}"
TARGETS="${TARGETS//,/ }"; WORKLOADS="${WORKLOADS//,/ }"; CLIENTS="${CLIENTS//,/ }"
if [ -f "$CFG" ]; then
  while IFS='=' read -r k v; do
    [ -z "$k" ] && continue
    eval "cur=\${$k:-}"
    if [ -z "$cur" ]; then eval "$k=\$v"
    elif [ "$cur" != "$v" ]; then echo "!! $k changed for run '$RUN': '$v' -> '$cur' (cells already done keep the old value)"; fi
  done < "$CFG"
fi
TARGETS="${TARGETS:-direct pgbouncer proxysql}"
WORKLOADS="${WORKLOADS:-W1 W2 W3}"
CLIENTS="${CLIENTS:-32 128 512}"
REPEATS="${REPEATS:-1}"
PROTOCOL="${PROTOCOL:-simple}"
DURATION="${DURATION:-60}"
WARMUP="${WARMUP:-10}"
JOBS="${JOBS:-4}"
SAMPLING="${SAMPLING:-0.05}"
W3_SPAN="${W3_SPAN:-2000}"
W3_SLEEP_MS="${W3_SLEEP_MS:-2}"
MAX_TRIES="${MAX_TRIES:-5}"
FORCE="${FORCE:-0}"
NOW="${NOW:-0}"
KEEP_TXLOG="${KEEP_TXLOG:-0}"
VACUUM="${VACUUM:-1}"   # VACUUM (ANALYZE) on `bench` after reset and after warm-up (0 = skip)

SCALE="${SCALE:-10}"
POSTGRES_IMAGE="${POSTGRES_IMAGE:-postgres:18}"
BENCH_CPUSET="${BENCH_CPUSET:-6-7}"
GRAFANA_URL="http://localhost:${GRAFANA_PORT:-13000}"
PUSHGW_URL="http://localhost:${PUSHGATEWAY_PORT:-19091}"
NET="pst-net"
BENCH_CTR="pst-pgbench"

log() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*"; }
now_ms() { echo $(( $(date +%s) * 1000 )); }

target_endpoint() {   # -> "host port container"
  case "$1" in
    direct)    echo "postgres 5432 pst-postgres" ;;
    pgbouncer) echo "pgbouncer 6432 pst-pgbouncer" ;;
    proxysql)  echo "proxysql 6133 pst-proxysql" ;;
    *) echo "unknown target $1" >&2; exit 1 ;;
  esac
}

# --------------------------------------------------------------------- ledger
cell_ids() {   # matrix order: targets interleaved so they run close in time
  local w c r t
  for w in $WORKLOADS; do for c in $CLIENTS; do
    r=1; while [ "$r" -le "$REPEATS" ]; do
      for t in $TARGETS; do echo "${w}_${t}_c${c}_${PROTOCOL}_r${r}"; done
      r=$((r + 1))
    done
  done; done
}

ledger_get() { awk -F'\t' -v c="$1" '$1==c {print $2; exit}' "$STATE"; }

ledger_set() {   # cell status [inc_attempt]
  local tmp="${STATE}.tmp"
  awk -F'\t' -v OFS='\t' -v c="$1" -v s="$2" -v inc="${3:-0}" -v ts="$(date '+%Y-%m-%dT%H:%M:%S')" '
    $1==c { $2=s; $3=$3+inc; $4=ts; found=1 } { print }
    END { if (!found) print c, s, inc, ts }' "$STATE" > "$tmp"
  mv "$tmp" "$STATE"
}

ledger_init() {
  mkdir -p "$RUN_DIR/cells"
  [ -f "$STATE" ] || : > "$STATE"
  # crash recovery: anything left "running" goes back to pending
  awk -F'\t' -v OFS='\t' '$2=="running"{$2="pending"} {print}' "$STATE" > "${STATE}.tmp" && mv "${STATE}.tmp" "$STATE"
  local id st
  for id in $(cell_ids); do
    st="$(ledger_get "$id")"
    if [ -z "$st" ]; then ledger_set "$id" pending
    elif [ "$FORCE" = "1" ]; then ledger_set "$id" pending; fi
  done
  # persist effective parameters for later resumes
  : > "$CFG"
  for k in $BENCH_PARAMS; do eval "echo \"$k=\${$k}\"" >> "$CFG"; done
}

# --------------------------------------------------------------------- helpers
wait_healthy() {
  local c="$1" i=0 s
  while [ $i -lt 90 ]; do
    s="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$c" 2>/dev/null || echo missing)"
    [ "$s" = "healthy" ] && return 0
    sleep 1; i=$((i + 1))
  done
  echo "container $c not healthy (status: $s)" >&2; return 1
}

check_stack() {
  local c
  for c in pst-postgres pst-pgbouncer pst-proxysql; do
    wait_healthy "$c" || { echo "Stack not ready. Run 'make up' first." >&2; exit 1; }
  done
  # the workloads need the scale the database was actually seeded with (not what .env says now)
  local s
  s="$(docker exec pst-postgres psql -U postgres -d bench -tAc 'select scale from lab_seed limit 1' 2>/dev/null || true)"
  if [ -n "$s" ]; then
    [ "$s" != "$SCALE" ] && log "note: database seeded with scale=$s (.env says $SCALE) -> using $s"
    SCALE="$s"
  fi
}

vacuum_db() {   # celldir label
  [ "$VACUUM" = "1" ] || return 0
  local t0; t0=$(date +%s)
  echo "-- VACUUM (ANALYZE) $2 @ $(date '+%H:%M:%S')" >> "$1/vacuum.log"
  docker exec pst-postgres psql -U postgres -d bench -v ON_ERROR_STOP=1 -c "VACUUM (ANALYZE)" >> "$1/vacuum.log" 2>&1
  log "  vacuum analyze ($2) $(( $(date +%s) - t0 ))s"
}

grafana_annotation() {   # start_ms end_ms text tags_json
  curl -s -m 3 -u admin:admin -H 'Content-Type: application/json' -X POST "${GRAFANA_URL}/api/annotations" \
    -d "{\"time\":$1,\"timeEnd\":$2,\"text\":\"$3\",\"tags\":$4}" >/dev/null 2>&1 || true
}

push_metrics() {   # group_path  (metrics on stdin)
  curl -s -m 3 --data-binary @- "${PUSHGW_URL}/metrics/$1" >/dev/null 2>&1 || true
}

delete_metrics() { curl -s -m 3 -X DELETE "${PUSHGW_URL}/metrics/$1" >/dev/null 2>&1 || true; }

# docker stats sampler (CPU% where 100% == one full core)
start_sampler() {
  local out="$1"
  ( while :; do
      docker stats --no-stream --format '{{.Name}},{{.CPUPerc}},{{.MemUsage}}' \
        pst-postgres pst-pgbouncer pst-proxysql 2>/dev/null \
        | sed "s/^/$(date +%s),/" >> "$out" || true
    done ) &
  SAMPLER_PID=$!
}
stop_sampler() {
  if [ -n "${SAMPLER_PID:-}" ]; then
    kill "$SAMPLER_PID" 2>/dev/null || true
    wait "$SAMPLER_PID" 2>/dev/null || true
  fi
  SAMPLER_PID=""
}

cpu_stats() {   # file container -> "avg max"
  awk -F',' -v c="$2" '$2==c { v=$3; sub(/%/,"",v); s+=v; n++; if (v>m) m=v }
    END { if (n) printf "%.1f %.1f", s/n, m; else printf "NA NA" }' "$1"
}

pgbench_cmd() {   # host port workload clients duration logprefix
  local jobs="$JOBS"; [ "$4" -lt "$jobs" ] && jobs="$4"
  local extra=""
  [ -n "$6" ] && extra="-l --sampling-rate=${SAMPLING} --log-prefix=$6"
  echo "pgbench -h $1 -p $2 -U bench -n -c $4 -j $jobs -T $5 -P 5 --progress-timestamp -M ${PROTOCOL} \
    --max-tries=${MAX_TRIES} -f /workloads/$3.sql -D scale=${SCALE} -D span=${W3_SPAN} -D sleep_ms=${W3_SLEEP_MS} \
    ${extra} bench"
}

run_pgbench() {   # celldir cmd...
  local dir="$1"; shift
  docker run --rm --name "$BENCH_CTR" --network "$NET" --cpuset-cpus "$BENCH_CPUSET" \
    --user "$(id -u):$(id -g)" --ulimit nofile=65536:65536 \
    -e PGPASSWORD=bench -e PGAPPNAME=pst-bench -e PGSSLMODE=disable \
    -v "$LAB_DIR/workloads:/workloads:ro" -v "$LAB_DIR/$dir:/out" \
    --entrypoint sh "$POSTGRES_IMAGE" -c "$*"
}

# live progress -> Pushgateway (job=bench_live)
progress_pusher() {   # target workload clients
  local line ts tps lat std
  while IFS= read -r line; do
    echo "$line"
    case "$line" in
      progress:*)
        set -- $line "" "" "" "" "" "" "" "" ""
        # progress: <epoch> s, <tps> tps, lat <ms> ms stddev <ms>, <n> failed ...
        tps="$4"; lat="$7"; std="${10}"
        printf 'bench_live_tps{target="%s",workload="%s",clients="%s"} %s\nbench_live_latency_ms{target="%s",workload="%s",clients="%s"} %s\nbench_live_latency_stddev_ms{target="%s",workload="%s",clients="%s"} %s\n' \
          "$T" "$W" "$C" "$tps" "$T" "$W" "$C" "$lat" "$T" "$W" "$C" "${std%,}" \
          | push_metrics "job/bench_live"
        ;;
    esac
  done
}

# --------------------------------------------------------------------- one cell
CURRENT_CELL=""
run_cell() {
  local id="$1"
  W="${id%%_*}"; local rest="${id#*_}"; T="${rest%%_*}"; rest="${rest#*_}"
  C="${rest%%_*}"; C="${C#c}"; local R="${id##*_r}"
  local ep host port ctr dir rc start_ms end_ms
  ep="$(target_endpoint "$T")"; set -- $ep; host="$1"; port="$2"; ctr="$3"
  dir="${RUN_DIR}/cells/${id}"

  CURRENT_CELL="$id"
  ledger_set "$id" running 1
  rm -rf "$dir"; mkdir -p "$dir"
  log "▶ ${id}  (target=${T} workload=${W} clients=${C} repeat=${R} ${DURATION}s)"

  # 1. idempotent reset: fresh DB from template + clean pooler state/stats
  docker exec pst-postgres psql -U postgres -d postgres -q -f /lab/reset_bench_db.sql > "$dir/reset.log" 2>&1
  docker restart pst-pgbouncer pst-proxysql >/dev/null
  wait_healthy pst-pgbouncer; wait_healthy pst-proxysql
  vacuum_db "$dir" "after reset"

  # 2. warm-up (not measured)
  log "  warm-up ${WARMUP}s"
  rc=0
  run_pgbench "$dir" "$(pgbench_cmd "$host" "$port" "$W" "$C" "$WARMUP" "")" > "$dir/warmup.log" 2>&1 || rc=$?
  if [ "$rc" -ne 0 ] && [ -f "$PAUSE_FLAG" ]; then abort_cell; return 1; fi
  # clean dead tuples / refresh stats produced by the warm-up before measuring
  vacuum_db "$dir" "after warm-up"

  # 3. measured run
  start_sampler "$dir/docker_stats.csv"
  start_ms="$(now_ms)"
  set +e
  run_pgbench "$dir" "$(pgbench_cmd "$host" "$port" "$W" "$C" "$DURATION" "/out/tx")" 2>&1 \
    | tee "$dir/pgbench.log" | progress_pusher > /dev/null
  rc=${PIPESTATUS[0]}
  set -e
  end_ms="$(now_ms)"
  stop_sampler
  delete_metrics "job/bench_live"

  if [ "$rc" -ne 0 ] && [ -f "$PAUSE_FLAG" ]; then abort_cell; return 1; fi

  # 4. results
  local tps lat std txns failed p50 p95 p99 cpu pcpu_avg pcpu_max pgcpu status
  tps="$(sed -n 's/^tps = \([0-9.]*\).*/\1/p' "$dir/pgbench.log" | tail -1)"
  lat="$(sed -n 's/^latency average = \([0-9.]*\) ms.*/\1/p' "$dir/pgbench.log" | tail -1)"
  std="$(sed -n 's/^latency stddev = \([0-9.]*\) ms.*/\1/p' "$dir/pgbench.log" | tail -1)"
  txns="$(sed -n 's/^number of transactions actually processed: \([0-9]*\).*/\1/p' "$dir/pgbench.log" | tail -1)"
  failed="$(sed -n 's/^number of failed transactions: \([0-9]*\).*/\1/p' "$dir/pgbench.log" | tail -1)"
  set -- $(cat "$dir"/tx* 2>/dev/null | awk '$3 ~ /^[0-9]+$/ {print $3}' | sort -n | awk '
      { a[NR]=$1 } END { if (!NR) { print "NA NA NA"; exit }
        i50=int(NR*0.50); i95=int(NR*0.95); i99=int(NR*0.99); if(i50<1)i50=1; if(i95<1)i95=1; if(i99<1)i99=1
        printf "%.3f %.3f %.3f", a[i50]/1000, a[i95]/1000, a[i99]/1000 }')
  p50="$1"; p95="$2"; p99="$3"
  [ "$KEEP_TXLOG" = "1" ] && gzip -f "$dir"/tx* 2>/dev/null || rm -f "$dir"/tx*
  set -- $(cpu_stats "$dir/docker_stats.csv" "$ctr"); pcpu_avg="$1"; pcpu_max="$2"
  set -- $(cpu_stats "$dir/docker_stats.csv" pst-postgres); pgcpu="$1"

  status=done; [ "$rc" -ne 0 ] || [ -z "$tps" ] && status=failed
  cat > "$dir/result.env" <<EOF
cell=${id}
workload=${W}
target=${T}
clients=${C}
protocol=${PROTOCOL}
repeat=${R}
duration=${DURATION}
tps=${tps:-NA}
lat_avg_ms=${lat:-NA}
lat_stddev_ms=${std:-NA}
p50_ms=${p50}
p95_ms=${p95}
p99_ms=${p99}
transactions=${txns:-NA}
failed=${failed:-0}
pooler_cpu_avg=${pcpu_avg}
pooler_cpu_max=${pcpu_max}
postgres_cpu_avg=${pgcpu}
started_ms=${start_ms}
finished_ms=${end_ms}
exit_code=${rc}
status=${status}
EOF

  # `run` and `cell` labels come from the Pushgateway grouping key
  local lbl="target=\"${T}\",workload=\"${W}\",clients=\"${C}\",protocol=\"${PROTOCOL}\",repeat=\"${R}\""
  { echo "bench_result_tps{${lbl}} ${tps:-NaN}"
    echo "bench_result_latency_avg_ms{${lbl}} ${lat:-NaN}"
    [ "$p95" != "NA" ] && echo "bench_result_latency_p95_ms{${lbl}} ${p95}"
    [ "$p99" != "NA" ] && echo "bench_result_latency_p99_ms{${lbl}} ${p99}"
    [ "$pcpu_avg" != "NA" ] && echo "bench_result_pooler_cpu_pct{${lbl}} ${pcpu_avg}"
    true; } | push_metrics "job/bench_result/run/${RUN}/cell/${id}"
  grafana_annotation "$start_ms" "$end_ms" "${id}: ${tps:-?} tps, avg ${lat:-?} ms, p95 ${p95} ms" \
    "[\"bench\",\"${T}\",\"${W}\",\"c${C}\"]"

  ledger_set "$id" "$status"
  CURRENT_CELL=""
  log "  ${status}: tps=${tps:-NA} avg=${lat:-NA}ms p95=${p95}ms p99=${p99}ms pooler_cpu=${pcpu_avg}% (max ${pcpu_max}%)"
}

abort_cell() {
  stop_sampler
  delete_metrics "job/bench_live"
  if [ -n "$CURRENT_CELL" ]; then
    ledger_set "$CURRENT_CELL" pending
    rm -rf "${RUN_DIR}/cells/${CURRENT_CELL}"
    log "  ⏸ ${CURRENT_CELL} aborted -> pending"
  fi
  CURRENT_CELL=""
}

on_interrupt() {
  echo; log "interrupted"
  docker kill "$BENCH_CTR" >/dev/null 2>&1 || true
  abort_cell
  rm -f "$LOCK"
  exit 130
}

# --------------------------------------------------------------------- commands
cmd_run() {
  mkdir -p "$RUN_DIR"
  if [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK")" 2>/dev/null; then
    echo "run '$RUN' already in progress (pid $(cat "$LOCK"))" >&2; exit 1
  fi
  echo $$ > "$LOCK"
  trap on_interrupt INT TERM
  trap 'rm -f "$LOCK"' EXIT

  check_stack
  ledger_init
  log "run=${RUN} targets=[${TARGETS}] workloads=[${WORKLOADS}] clients=[${CLIENTS}] repeats=${REPEATS} protocol=${PROTOCOL} duration=${DURATION}s warmup=${WARMUP}s"
  cmd_status_short

  local id st
  for id in $(cell_ids); do
    if [ -f "$PAUSE_FLAG" ]; then log "⏸ paused (make resume RUN=${RUN} to continue)"; return 0; fi
    st="$(ledger_get "$id")"
    case "$st" in done) continue ;; failed) [ "$FORCE" = "1" ] || [ "${RETRY_FAILED:-0}" = "1" ] || continue ;; esac
    run_cell "$id" || { log "⏸ paused (make resume RUN=${RUN} to continue)"; return 0; }
  done
  cmd_summary
  log "✔ run '${RUN}' complete -> ${RUN_DIR}/summary.csv  (make report RUN=${RUN})"
}

cmd_status_short() {
  awk -F'\t' '{n[$2]++; t++} END { printf "  cells: %d  done: %d  pending: %d  failed: %d  running: %d\n", t, n["done"], n["pending"], n["failed"], n["running"] }' "$STATE"
}

cmd_status() {
  [ -f "$STATE" ] || { echo "no run '$RUN' yet"; exit 0; }
  echo "run: ${RUN}   $( [ -f "$PAUSE_FLAG" ] && echo '[PAUSED]')   $( [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK")" 2>/dev/null && echo "[RUNNING pid $(cat "$LOCK")]")"
  cmd_status_short
  printf '%-34s %-8s %-4s %s\n' CELL STATUS TRY UPDATED
  awk -F'\t' '{ printf "%-34s %-8s %-4s %s\n", $1, $2, $3, $4 }' "$STATE"
}

cmd_pause() {
  mkdir -p "$RUN_DIR"; touch "$PAUSE_FLAG"
  if [ "$NOW" = "1" ]; then
    docker kill "$BENCH_CTR" >/dev/null 2>&1 && echo "current cell aborted; it will be re-run on resume" || true
  else
    echo "pause requested: the current cell finishes, then the runner stops"
  fi
}

cmd_resume() { rm -f "$PAUSE_FLAG"; cmd_run; }

cmd_summary() {
  local out="${RUN_DIR}/summary.csv" f
  local cols="cell workload target clients protocol repeat duration tps lat_avg_ms lat_stddev_ms p50_ms p95_ms p99_ms transactions failed pooler_cpu_avg pooler_cpu_max postgres_cpu_avg started_ms finished_ms exit_code status"
  echo "$cols" | tr ' ' ',' > "$out"
  for f in "${RUN_DIR}"/cells/*/result.env; do
    [ -f "$f" ] || continue
    awk -F'=' -v cols="$cols" 'BEGIN{n=split(cols,c," ")} {v[$1]=$2} END{ for(i=1;i<=n;i++) printf "%s%s", v[c[i]], (i<n?",":"\n") }' "$f"
  done | sort -t, -k2,2 -k4,4n -k3,3 -k6,6n >> "$out"
  echo "summary: $out"
}

case "${1:-run}" in
  run) cmd_run ;;
  status) cmd_status ;;
  pause) cmd_pause ;;
  resume) cmd_resume ;;
  summary) cmd_summary ;;
  *) echo "usage: $0 run|status|pause|resume|summary" >&2; exit 2 ;;
esac
