#!/usr/bin/env python3
"""Generates the provisioned Grafana dashboards (stdlib only).

    python3 docker/grafana/gen_dashboards.py

Edit the panel lists below and re-run; Grafana picks the JSON up within 10s.
"""
import json
import os

OUT = os.path.join(os.path.dirname(__file__), "provisioning", "dashboards")
DS = {"type": "prometheus", "uid": "prometheus"}
RI = "$__rate_interval"
POOLERS = 'name=~"pst-(pgbouncer|proxysql|postgres)"'

ANNOTATIONS = {"list": [
    {"builtIn": 1, "datasource": {"type": "grafana", "uid": "-- Grafana --"}, "enable": True, "hide": True,
     "iconColor": "rgba(0, 211, 255, 1)", "name": "Annotations & Alerts", "type": "dashboard"},
    {"datasource": {"type": "grafana", "uid": "-- Grafana --"}, "enable": True, "hide": False,
     "iconColor": "rgba(255, 96, 96, 0.25)", "name": "Benchmark cells", "type": "tags",
     "tags": ["bench"], "matchAny": True},
]}


class Board:
    def __init__(self, uid, title, tags=None, variables=None):
        self.uid, self.title, self.tags = uid, title, tags or []
        self.variables = variables or []
        self.panels, self.y, self.x, self.row_h, self.pid = [], 0, 0, 0, 1

    def _next(self, w, h):
        if self.x + w > 24:
            self.x, self.y = 0, self.y + self.row_h
            self.row_h = 0
        pos = {"x": self.x, "y": self.y, "w": w, "h": h}
        self.x += w
        self.row_h = max(self.row_h, h)
        self.pid += 1
        return pos

    def row(self, title):
        if self.x:
            self.x, self.y, self.row_h = 0, self.y + self.row_h, 0
        self.pid += 1
        self.panels.append({"type": "row", "title": title, "collapsed": False, "id": self.pid,
                            "gridPos": {"x": 0, "y": self.y, "w": 24, "h": 1}, "panels": []})
        self.y += 1

    def ts(self, title, targets, unit="short", w=12, h=8, desc="", stack=False):
        pos = self._next(w, h)
        self.panels.append({
            "type": "timeseries", "title": title, "id": self.pid, "gridPos": pos, "datasource": DS,
            "description": desc,
            "fieldConfig": {"defaults": {"unit": unit, "custom": {
                "lineWidth": 2, "fillOpacity": 10, "showPoints": "never",
                "stacking": {"mode": "normal" if stack else "none"}}}, "overrides": []},
            "options": {"legend": {"displayMode": "table", "placement": "bottom",
                                   "calcs": ["mean", "max", "lastNotNull"]},
                        "tooltip": {"mode": "multi", "sort": "desc"}},
            "targets": [{"datasource": DS, "expr": e, "legendFormat": l, "refId": chr(65 + i)}
                        for i, (e, l) in enumerate(targets)],
        })

    def stat(self, title, expr, unit="short", w=4, h=4, legend=""):
        pos = self._next(w, h)
        self.panels.append({
            "type": "stat", "title": title, "id": self.pid, "gridPos": pos, "datasource": DS,
            "fieldConfig": {"defaults": {"unit": unit}, "overrides": []},
            "options": {"reduceOptions": {"calcs": ["lastNotNull"]}, "colorMode": "value", "graphMode": "area"},
            "targets": [{"datasource": DS, "expr": expr, "legendFormat": legend, "refId": "A"}],
        })

    def table(self, title, targets, w=24, h=10):
        pos = self._next(w, h)
        self.panels.append({
            "type": "table", "title": title, "id": self.pid, "gridPos": pos, "datasource": DS,
            "targets": [{"datasource": DS, "expr": e, "format": "table", "instant": True, "refId": chr(65 + i)}
                        for i, e in enumerate(targets)],
            "transformations": [
                {"id": "merge", "options": {}},
                {"id": "organize", "options": {
                    "excludeByName": {"Time": True, "__name__": True, "instance": True, "job": True, "cell": True},
                    "indexByName": {"run": 0, "workload": 1, "clients": 2, "target": 3, "protocol": 4, "repeat": 5},
                    "renameByName": {"Value #A": "TPS", "Value #B": "avg ms", "Value #C": "p95 ms",
                                     "Value #D": "p99 ms", "Value #E": "pooler CPU %"}}},
                {"id": "sortBy", "options": {"sort": [{"field": "clients"}]}},
            ],
            "fieldConfig": {"defaults": {"decimals": 2}, "overrides": []},
            "options": {"showHeader": True},
        })

    def save(self):
        d = {"uid": self.uid, "title": self.title, "tags": ["pool-single-thread"] + self.tags,
             "timezone": "browser", "schemaVersion": 39, "version": 1, "editable": True,
             "refresh": "5s", "time": {"from": "now-30m", "to": "now"},
             "annotations": ANNOTATIONS, "templating": {"list": self.variables},
             "graphTooltip": 1, "panels": self.panels, "links": [
                 {"type": "dashboards", "tags": ["pool-single-thread"], "asDropdown": True, "title": "Lab dashboards"}]}
        with open(os.path.join(OUT, f"{self.uid}.json"), "w") as f:
            json.dump(d, f, indent=2)
        print("wrote", self.uid)


def var_query(name, query, multi=True):
    return {"name": name, "type": "query", "datasource": DS, "query": {"query": query, "refId": name},
            "definition": query, "refresh": 2, "includeAll": True, "multi": multi,
            "current": {"text": "All", "value": "$__all"}, "allValue": ".*"}


# ------------------------------------------------------------------ overview
b = Board("pst-overview", "Pooler Benchmark — Overview", ["overview"],
          [var_query("run", "label_values(bench_result_tps, run)")])
b.row("Live benchmark (pgbench progress, pushed every 5s)")
b.ts("TPS by target", [("bench_live_tps", "{{target}} {{workload}} c{{clients}}")], "short")
b.ts("Latency avg by target", [("bench_live_latency_ms", "{{target}} {{workload}} c{{clients}}"),
                               ("bench_live_latency_stddev_ms", "stddev {{target}}")], "ms")
b.row("Single-core saturation (100% = one full core)")
b.ts("CPU per component", [(f'rate(container_cpu_usage_seconds_total{{{POOLERS}}}[{RI}]) * 100', "{{name}}")],
     "percent", w=12, desc="From cAdvisor. Each pooler is pinned to one core: 100% means saturated.")
b.ts("Throughput seen by each component", [
    (f'sum(rate(pgbouncer_stats_sql_transactions_pooled_total{{database="bench"}}[{RI}]))', "pgbouncer xact/s"),
    (f'sum(rate(pgbouncer_stats_queries_pooled_total{{database="bench"}}[{RI}]))', "pgbouncer queries/s"),
    (f'sum(rate(proxysql_connpool_conns_queries_total[{RI}]))', "proxysql queries/s"),
    (f'sum(rate(pg_stat_database_xact_commit{{datname="bench"}}[{RI}]))', "postgres commits/s"),
], "short")
b.row("Pooling / queueing")
b.ts("Client connections", [
    ('sum(pgbouncer_pools_client_active_connections{database="bench"})', "pgbouncer active"),
    ('sum(pgbouncer_pools_client_waiting_connections{database="bench"})', "pgbouncer waiting"),
    ('sum(proxysql_client_connections_connected)', "proxysql connected"),
], "short", w=8)
b.ts("Backend (server) connections", [
    ('sum(pgbouncer_pools_server_active_connections{database="bench"})', "pgbouncer active"),
    ('sum(pgbouncer_pools_server_idle_connections{database="bench"})', "pgbouncer idle"),
    ('sum by (status) (proxysql_connpool_conns)', "proxysql {{status}}"),
], "short", w=8)
b.ts("Postgres sessions on bench", [('sum by (state) (pg_stat_activity_count{datname="bench"})', "{{state}}")],
     "short", w=8)
b.row("Results (one row per finished cell, from Pushgateway)")
lbl = '{run=~"$run"}'
b.table("Benchmark results", [f"bench_result_tps{lbl}", f"bench_result_latency_avg_ms{lbl}",
                              f"bench_result_latency_p95_ms{lbl}", f"bench_result_latency_p99_ms{lbl}",
                              f"bench_result_pooler_cpu_pct{lbl}"], h=12)
b.save()

# ------------------------------------------------------------------ pgbouncer
b = Board("pst-pgbouncer", "Pooler Benchmark — PgBouncer", ["pgbouncer"])
b.stat("Up", "pgbouncer_up")
b.stat("Version", "pgbouncer_version_info", legend="{{version}}")
b.stat("Max client conn", "pgbouncer_config_max_client_connections")
b.stat("Pool size", 'pgbouncer_databases_pool_size{name="bench"}')
b.stat("CPU %", f'rate(container_cpu_usage_seconds_total{{name="pst-pgbouncer"}}[{RI}]) * 100', "percent")
b.stat("Memory", 'container_memory_working_set_bytes{name="pst-pgbouncer"}', "bytes")
b.ts("Transactions / queries per second", [
    (f'rate(pgbouncer_stats_sql_transactions_pooled_total{{database="bench"}}[{RI}])', "xact/s"),
    (f'rate(pgbouncer_stats_queries_pooled_total{{database="bench"}}[{RI}])', "queries/s")])
b.ts("Avg query / xact time (server side)", [
    (f'rate(pgbouncer_stats_queries_duration_seconds_total{{database="bench"}}[{RI}]) / rate(pgbouncer_stats_queries_pooled_total{{database="bench"}}[{RI}])', "query"),
    (f'rate(pgbouncer_stats_server_in_transaction_seconds_total{{database="bench"}}[{RI}]) / rate(pgbouncer_stats_sql_transactions_pooled_total{{database="bench"}}[{RI}])', "transaction")], "s")
b.ts("Client wait time per second (queueing)", [
    (f'rate(pgbouncer_stats_client_wait_seconds_total{{database="bench"}}[{RI}])', "client wait s/s")], "s")
b.ts("Oldest waiting client", [('pgbouncer_pools_client_maxwait_seconds{database="bench"}', "maxwait")], "s")
b.ts("Clients", [('pgbouncer_pools_client_active_connections{database="bench"}', "active"),
                 ('pgbouncer_pools_client_waiting_connections{database="bench"}', "waiting")])
b.ts("Servers", [('pgbouncer_pools_server_active_connections{database="bench"}', "active"),
                 ('pgbouncer_pools_server_idle_connections{database="bench"}', "idle"),
                 ('pgbouncer_pools_server_used_connections{database="bench"}', "used"),
                 ('pgbouncer_pools_server_login_connections{database="bench"}', "login")])
b.ts("Network", [(f'rate(pgbouncer_stats_received_bytes_total{{database="bench"}}[{RI}])', "received"),
                 (f'rate(pgbouncer_stats_sent_bytes_total{{database="bench"}}[{RI}])', "sent")], "Bps")
b.ts("Prepared statements (extended/prepared protocol)", [
    (f'rate(pgbouncer_stats_client_parses_total{{database="bench"}}[{RI}])', "client parses/s"),
    (f'rate(pgbouncer_stats_server_parses_total{{database="bench"}}[{RI}])', "server parses/s"),
    (f'rate(pgbouncer_stats_binds_total{{database="bench"}}[{RI}])', "binds/s")])
b.save()

# ------------------------------------------------------------------ proxysql
b = Board("pst-proxysql", "Pooler Benchmark — ProxySQL", ["proxysql"])
b.stat("Up", 'up{job="proxysql"}')
b.stat("Client conns", "sum(proxysql_client_connections_connected)")
b.stat("Server conns", "sum(proxysql_server_connections_connected)")
b.stat("Backend pool used", 'sum(proxysql_connpool_conns{status="used"})')
b.stat("CPU %", f'rate(container_cpu_usage_seconds_total{{name="pst-proxysql"}}[{RI}]) * 100', "percent")
b.stat("Memory", 'container_memory_working_set_bytes{name="pst-proxysql"}', "bytes")
b.ts("Queries per second (connection pool)", [
    (f'sum by (endpoint) (rate(proxysql_connpool_conns_queries_total[{RI}]))', "{{endpoint}}")])
b.ts("Backend latency (ping)", [('proxysql_connpool_conns_latency_us', "{{endpoint}}")], "µs")
b.ts("Client connections", [('proxysql_client_connections_connected', "connected {{protocol}}"),
                            (f'rate(proxysql_client_connections_total[{RI}])', "new/s {{protocol}} {{status}}")])
b.ts("Server connections", [('proxysql_server_connections_connected', "connected {{protocol}}"),
                            (f'rate(proxysql_server_connections_total[{RI}])', "new/s {{protocol}} {{status}}")])
b.ts("Connection pool by status", [('proxysql_connpool_conns', "{{status}} {{endpoint}}")])
b.ts("Pool traffic", [(f'rate(proxysql_connpool_data_bytes_total[{RI}])', "{{traffic_flow}} {{endpoint}}")], "Bps")
b.ts("Errors", [(f'rate(proxysql_pgsql_error_total[{RI}])', "pgsql errors {{code}}"),
                (f'rate(proxysql_access_denied_wrong_password_total[{RI}])', "access denied")])
b.ts("Memory", [('container_memory_working_set_bytes{name="pst-proxysql"}', "working set")], "bytes")
b.save()

# ------------------------------------------------------------------ postgres
b = Board("pst-postgres", "Pooler Benchmark — PostgreSQL", ["postgres"])
b.stat("Up", "pg_up")
b.stat("Max connections", "pg_settings_max_connections")
b.stat("Shared buffers", "pg_settings_shared_buffers_bytes", "bytes")
b.stat("DB size", 'pg_database_size_bytes{datname="bench"}', "bytes")
b.stat("CPU % (3 cores = 300%)", f'rate(container_cpu_usage_seconds_total{{name="pst-postgres"}}[{RI}]) * 100', "percent")
b.stat("Sessions on bench", 'sum(pg_stat_activity_count{datname="bench"})')
b.ts("Transactions per second", [
    (f'rate(pg_stat_database_xact_commit{{datname="bench"}}[{RI}])', "commit"),
    (f'rate(pg_stat_database_xact_rollback{{datname="bench"}}[{RI}])', "rollback")])
b.ts("Sessions by state", [('pg_stat_activity_count{datname="bench"}', "{{state}}")])
b.ts("Tuples", [(f'rate(pg_stat_database_tup_fetched{{datname="bench"}}[{RI}])', "fetched"),
                (f'rate(pg_stat_database_tup_inserted{{datname="bench"}}[{RI}])', "inserted"),
                (f'rate(pg_stat_database_tup_updated{{datname="bench"}}[{RI}])', "updated"),
                (f'rate(pg_stat_database_tup_deleted{{datname="bench"}}[{RI}])', "deleted")])
b.ts("Cache hit ratio", [(f'rate(pg_stat_database_blks_hit{{datname="bench"}}[{RI}]) / (rate(pg_stat_database_blks_hit{{datname="bench"}}[{RI}]) + rate(pg_stat_database_blks_read{{datname="bench"}}[{RI}]))', "hit ratio")], "percentunit")
b.ts("Locks", [('sum by (mode) (pg_locks_count{datname="bench"})', "{{mode}}")])
b.ts("Deadlocks / conflicts / temp", [
    (f'rate(pg_stat_database_deadlocks{{datname="bench"}}[{RI}])', "deadlocks"),
    (f'rate(pg_stat_database_conflicts{{datname="bench"}}[{RI}])', "conflicts"),
    (f'rate(pg_stat_database_temp_bytes{{datname="bench"}}[{RI}])', "temp bytes")])
b.ts("Top statements by calls/s (pg_stat_statements)", [
    (f'topk(10, rate(pg_stat_statements_calls_total{{datname="bench"}}[{RI}]))', "{{queryid}}")], w=12)
b.ts("Top statements by time/s", [
    (f'topk(10, rate(pg_stat_statements_seconds_total{{datname="bench"}}[{RI}]))', "{{queryid}}")], "s", w=12)
b.save()

# ------------------------------------------------------------------ containers
b = Board("pst-containers", "Pooler Benchmark — Containers", ["containers"])
b.ts("CPU (100% = 1 core)", [(f'rate(container_cpu_usage_seconds_total{{name=~"pst-.*"}}[{RI}]) * 100', "{{name}}")],
     "percent", w=24)
b.ts("Memory working set", [('container_memory_working_set_bytes{name=~"pst-.*"}', "{{name}}")], "bytes")
b.ts("Network rx", [(f'rate(container_network_receive_bytes_total{{name=~"pst-.*"}}[{RI}])', "{{name}}")], "Bps")
b.ts("Network tx", [(f'rate(container_network_transmit_bytes_total{{name=~"pst-.*"}}[{RI}])', "{{name}}")], "Bps")
b.ts("CPU throttling", [(f'rate(container_cpu_cfs_throttled_seconds_total{{name=~"pst-.*"}}[{RI}])', "{{name}}")], "s")
b.save()

# ------------------------------------------------------------------ reused sql_exporter dashboard
p = os.path.join(OUT, "sql_exporter.json")
if os.path.exists(p):
    d = json.load(open(p))
    s = json.dumps(d).replace("PBFA97CFB590B2093", "prometheus")
    d = json.loads(s)
    d.update({"uid": "pst-sql-exporter", "title": "Pooler Benchmark — Tables (sql_exporter)",
              "tags": ["pool-single-thread", "postgres"], "annotations": ANNOTATIONS, "id": None})
    json.dump(d, open(p, "w"), indent=2)
    print("patched sql_exporter.json")
