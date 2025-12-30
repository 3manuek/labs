# Project Editors

Consistent slowness shown by upserts over `projects` table.

More information in [Slow Upserts on projects](https://workato.atlassian.net/wiki/spaces/INF/pages/2065235970/Slow+Upserts+on+projects).

## Setup and run

```bash
make up-back
```

After databases are ready, run the benchmarks:
```bash
make start-bench
```


## Query

```sql
INSERT INTO "projects" ("folder_id","user_id","team_id","activity_log_id","edited_at") 
    VALUES (17874974,3663172,3748097,645464895,'2025-12-10 22:55:03.178149') 
    ON CONFLICT (folder_id, user_id) 
    DO UPDATE SET "activity_log_id"=EXCLUDED."activity_log_id","edited_at"=EXCLUDED."edited_at"  
    RETURNING "folder_id", "user_id";
```

```sql
error_postgresql.log.2025-12-10-2200:2025-12-10 22:55:17 UTC:10.237.36.81(33752):udamkofc046iic@d2m99i8fn7gv3e:[39111]:LOG:  duration: 14097.022 ms  execute <unnamed>: INSERT INTO "projects" ("folder_id","user_id","team_id","activity_log_id","edited_at") VALUES (17874974,3663172,3748097,645464895,'2025-12-10 22:55:03.178149') ON CONFLICT (folder_id, user_id) DO UPDATE SET "activity_log_id"=EXCLUDED."activity_log_id","edited_at"=EXCLUDED."edited_at"  RETURNING "folder_id", "user_id"
error_postgresql.log.2025-12-10-2200:2025-12-10 22:55:20 UTC:10.235.210.111(43318):udamkofc046iic@d2m99i8fn7gv3e:[34050]:LOG:  duration: 17321.083 ms  execute <unnamed>: INSERT INTO "projects" ("folder_id","user_id","team_id","activity_log_id","edited_at") VALUES (17874974,3663172,3748097,645464888,'2025-12-10 22:55:02.959926') ON CONFLICT (folder_id, user_id) DO UPDATE SET "activity_log_id"=EXCLUDED."activity_log_id","edited_at"=EXCLUDED."edited_at"  RETURNING "folder_id", "user_id"
```

ori bench
```
pgbench     | progress: 10.0 s, 57.5 tps, lat 34.711 ms stddev 4.606, 0 failed
pgbench     | progress: 20.0 s, 59.0 tps, lat 33.930 ms stddev 6.138, 0 failed
pgbench     | progress: 30.0 s, 61.7 tps, lat 32.405 ms stddev 2.520, 0 failed
pgbench     | progress: 40.0 s, 63.5 tps, lat 31.498 ms stddev 2.167, 0 failed
pgbench     | progress: 50.0 s, 58.5 tps, lat 34.159 ms stddev 12.615, 0 failed
```