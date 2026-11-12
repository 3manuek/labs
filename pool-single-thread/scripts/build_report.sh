#!/usr/bin/env bash
# Builds results/<RUN>/report.html from results/<RUN>/summary.csv (same Chart.js approach as ../fillfactor/build_graph.sh).
# Repeats are averaged. One section per workload: TPS / avg latency / p95 / p99 / pooler CPU vs clients.
set -euo pipefail
cd "$(dirname "$0")/.."

RUN="${RUN:-default}"
CSV="results/${RUN}/summary.csv"
OUT="results/${RUN}/report.html"
[ -f "$CSV" ] || { echo "missing $CSV (run: make summary RUN=${RUN})" >&2; exit 1; }

# CSV -> JS string literal lines
ROWS="$(awk 'NR>1 { gsub(/"/, ""); printf "  \"%s\",\n", $0 }' "$CSV")"
HEADER="$(head -1 "$CSV")"
GENERATED="$(date '+%Y-%m-%d %H:%M:%S')"

cat > "$OUT" <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Pooler benchmark — ${RUN}</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<style>
  body { font-family: -apple-system, Helvetica, Arial, sans-serif; margin: 24px; color: #222; }
  h1 { margin-bottom: 4px; } .sub { color: #666; margin-top: 0; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(420px, 1fr)); gap: 18px; }
  .card { border: 1px solid #ddd; border-radius: 8px; padding: 12px; }
  table { border-collapse: collapse; font-size: 13px; margin-top: 10px; }
  th, td { border: 1px solid #ddd; padding: 4px 8px; text-align: right; } th { background: #f4f4f4; }
  td:first-child, th:first-child { text-align: left; }
</style>
</head>
<body>
<h1>PgBouncer vs ProxySQL — single thread</h1>
<p class="sub">run <b>${RUN}</b> · generated ${GENERATED} · values averaged over repeats · pooler CPU: 100% = one core</p>
<div id="root"></div>
<script>
const HEADER = "${HEADER}".split(",");
const RAW = [
${ROWS}
];
const rows = RAW.map(l => Object.fromEntries(l.split(",").map((v, i) => [HEADER[i], v])))
                .filter(r => r.status === "done");
const COLORS = { direct: "rgb(120,120,120)", pgbouncer: "rgb(29,122,235)", proxysql: "rgb(235,110,30)" };
const num = v => (v === undefined || v === "NA" || v === "") ? null : Number(v);
const avg = a => { const b = a.filter(x => x !== null); return b.length ? b.reduce((s, x) => s + x, 0) / b.length : null; };

const metrics = [
  ["tps", "Throughput (TPS)"], ["lat_avg_ms", "Latency avg (ms)"],
  ["p95_ms", "Latency p95 (ms)"], ["p99_ms", "Latency p99 (ms)"],
  ["pooler_cpu_avg", "Target CPU avg (%) — postgres for direct"]
];
const root = document.getElementById("root");
const workloads = [...new Set(rows.map(r => r.workload))].sort();
for (const w of workloads) {
  const wr = rows.filter(r => r.workload === w);
  const clients = [...new Set(wr.map(r => +r.clients))].sort((a, b) => a - b);
  const targets = [...new Set(wr.map(r => r.target))];
  const sec = document.createElement("section");
  sec.innerHTML = "<h2>" + w + " <small style='color:#888'>(" + (wr[0]?.protocol || "") + " protocol, " + (wr[0]?.duration || "") + "s per cell)</small></h2>";
  const grid = document.createElement("div"); grid.className = "grid"; sec.appendChild(grid);
  const agg = {};
  for (const t of targets) for (const c of clients) {
    const sel = wr.filter(r => r.target === t && +r.clients === c);
    agg[t + c] = Object.fromEntries(metrics.map(([k]) => [k, avg(sel.map(r => num(r[k])))]));
  }
  for (const [k, title] of metrics) {
    const card = document.createElement("div"); card.className = "card";
    const cv = document.createElement("canvas"); card.appendChild(cv); grid.appendChild(card);
    new Chart(cv, {
      type: k === "tps" ? "bar" : "line",
      data: { labels: clients.map(c => c + " clients"),
              datasets: targets.map(t => ({ label: t, data: clients.map(c => agg[t + c][k]),
                         backgroundColor: COLORS[t], borderColor: COLORS[t], tension: 0.1 })) },
      options: { plugins: { title: { display: true, text: w + " — " + title } },
                 scales: { y: { beginAtZero: true } } }
    });
  }
  // table
  let html = "<table><tr><th>target</th><th>clients</th><th>TPS</th><th>vs direct</th><th>avg ms</th><th>p95 ms</th><th>p99 ms</th><th>CPU %</th></tr>";
  for (const c of clients) for (const t of targets) {
    const a = agg[t + c], d = agg["direct" + c];
    const rel = (d && d.tps && a.tps) ? ((a.tps / d.tps - 1) * 100).toFixed(1) + "%" : "";
    const f = (v, n = 2) => v === null ? "NA" : v.toFixed(n);
    html += "<tr><td>" + t + "</td><td>" + c + "</td><td>" + f(a.tps, 0) + "</td><td>" + (t === "direct" ? "" : rel) +
            "</td><td>" + f(a.lat_avg_ms, 3) + "</td><td>" + f(a.p95_ms, 3) + "</td><td>" + f(a.p99_ms, 3) + "</td><td>" + f(a.pooler_cpu_avg, 1) + "</td></tr>";
  }
  sec.insertAdjacentHTML("beforeend", html + "</table>");
  root.appendChild(sec);
}
if (!rows.length) root.innerHTML = "<p>No completed cells yet.</p>";
</script>
</body>
</html>
EOF
echo "report: $OUT"
