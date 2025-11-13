#!/bin/bash


while true; do
    echo
    echo "================================================"
    echo "Origin Replication status:"
    echo "================================================"
    docker compose exec -T postgres13 psql -nx -U postgres -d testdb <<EOF
        SELECT slot_name, active, active_pid, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(),
            confirmed_flush_lsn)) AS diff_size, pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn) AS diff_bytes,
            confirmed_flush_lsn as LSN_origin
        FROM pg_replication_slots WHERE slot_type = 'logical';
        
        select pid, application_name, backend_start, backend_xmin, state
            sent_lsn, write_lsn, flush_lsn, replay_lsn, write_lag, flush_lag, replay_lag,  sync_state, reply_time
        from pg_stat_replication;

        SELECT count(*) FROM demo_table;
EOF

    echo "================================================"
    echo "Destination Replication lag:"
    echo "================================================"
    docker compose exec -T postgres17 psql -nx -U postgres -d testdb <<EOF
     SELECT subname, 
                received_lsn as LSN_destination, 
                last_msg_receipt_time, 
                latest_end_lsn, 
                latest_end_time, 
                pg_wal_lsn_diff(received_lsn, latest_end_lsn) AS bytes_pending_apply,
                pg_size_pretty(pg_wal_lsn_diff(received_lsn, latest_end_lsn)) AS pending_apply,
                clock_timestamp() - latest_end_time AS lag, 
                clock_timestamp() as current_time
            FROM pg_stat_subscription;
    SELECT count(*) FROM demo_table;
EOF
    echo "================================================"
    echo "Disk usage:"
    echo "================================================"
    du -hs pg*data
    sleep 10
done