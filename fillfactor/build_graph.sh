#!/bin/bash

# Ensure reports directory exists
mkdir -p reports

# Extract data
# hash_data=$(docker compose logs pgbench_hash | grep progress | \
#     awk '{print $4, $6}' | sed 's/,//g' | \
#     awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}')

ori_data13=$(docker compose logs pgbench_ori13 2>/dev/null | grep progress 2>/dev/null | \
    awk '{print $4, $6}' | sed 's/,//g' | \
    awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}' || echo "")

onlyff_data13=$(docker compose logs pgbench_onlyff13 2>/dev/null | grep progress 2>/dev/null | \
    awk '{print $4, $6}' | sed 's/,//g' | \
    awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}' || echo "")

ori_data18=$(docker compose logs pgbench_ori18 2>/dev/null | grep progress 2>/dev/null | \
    awk '{print $4, $6}' | sed 's/,//g' | \
    awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}' || echo "")

onlyff_data18=$(docker compose logs pgbench_onlyff18 2>/dev/null | grep progress 2>/dev/null | \
    awk '{print $4, $6}' | sed 's/,//g' | \
    awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}' || echo "")

ori_data17=$(docker compose logs pgbench_ori17 2>/dev/null | grep progress 2>/dev/null | \
    awk '{print $4, $6}' | sed 's/,//g' | \
    awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}' || echo "")

onlyff_data17=$(docker compose logs pgbench_onlyff17 2>/dev/null | grep progress 2>/dev/null | \
    awk '{print $4, $6}' | sed 's/,//g' | \
    awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}' || echo "")

# Parse into arrays
# IFS=';' read -r times_str hash_tps <<< "$hash_data"
IFS=';' read -r times_str ori_tps13 <<< "$ori_data13" || true
IFS=';' read -r _ onlyff_tps13 <<< "$onlyff_data13" || true
IFS=';' read -r _ ori_tps18 <<< "$ori_data18" || true
IFS=';' read -r _ onlyff_tps18 <<< "$onlyff_data18" || true
IFS=';' read -r _ ori_tps17 <<< "$ori_data17" || true
IFS=';' read -r _ onlyff_tps17 <<< "$onlyff_data17" || true


# Remove trailing commas
times_str=${times_str%,}
# hash_tps=${hash_tps%,}
ori_tps13=${ori_tps13%,}
onlyff_tps13=${onlyff_tps13%,}
ori_tps18=${ori_tps18%,}
onlyff_tps18=${onlyff_tps18%,}
ori_tps17=${ori_tps17%,}
onlyff_tps17=${onlyff_tps17%,}

# Extract final statistics (TPS, latency, stddev) from pgbench logs
extract_stats() {
    local container=$1
    # Extract TPS - look for "tps = " followed by number
    local tps=$(docker compose logs "$container" 2>/dev/null | grep "tps = " | tail -1 | sed -n 's/.*tps = \([0-9.]*\).*/\1/p' || echo "")
    # Extract latency average - look for "latency average = " followed by number and "ms"
    local latency=$(docker compose logs "$container" 2>/dev/null | grep "latency average = " | tail -1 | sed -n 's/.*latency average = \([0-9.]*\) ms.*/\1/p' || echo "")
    # Extract latency stddev - look for "latency stddev = " followed by number and "ms"
    local stddev=$(docker compose logs "$container" 2>/dev/null | grep "latency stddev = " | tail -1 | sed -n 's/.*latency stddev = \([0-9.]*\) ms.*/\1/p' || echo "")
    echo "${tps};${latency};${stddev}"
}

stats_ori13=$(extract_stats pgbench_ori13)
stats_onlyff13=$(extract_stats pgbench_onlyff13)
stats_ori18=$(extract_stats pgbench_ori18)
stats_onlyff18=$(extract_stats pgbench_onlyff18)
stats_ori17=$(extract_stats pgbench_ori17)
stats_onlyff17=$(extract_stats pgbench_onlyff17)

# Debug: Print extracted stats (comment out in production)
# echo "Debug - stats_ori13: $stats_ori13" >&2
# echo "Debug - stats_onlyff13: $stats_onlyff13" >&2

# Parse statistics and ensure empty values are truly empty (not "0" or whitespace)
IFS=';' read -r tps_ori13 latency_ori13 stddev_ori13 <<< "$stats_ori13" || true
IFS=';' read -r tps_onlyff13 latency_onlyff13 stddev_onlyff13 <<< "$stats_onlyff13" || true
IFS=';' read -r tps_ori18 latency_ori18 stddev_ori18 <<< "$stats_ori18" || true
IFS=';' read -r tps_onlyff18 latency_onlyff18 stddev_onlyff18 <<< "$stats_onlyff18" || true
IFS=';' read -r tps_ori17 latency_ori17 stddev_ori17 <<< "$stats_ori17" || true
IFS=';' read -r tps_onlyff17 latency_onlyff17 stddev_onlyff17 <<< "$stats_onlyff17" || true

# Clean up any variables that are just whitespace or empty - set them to empty string
for var in tps_ori13 latency_ori13 stddev_ori13 tps_onlyff13 latency_onlyff13 stddev_onlyff13 \
          tps_ori18 latency_ori18 stddev_ori18 tps_onlyff18 latency_onlyff18 stddev_onlyff18 \
          tps_ori17 latency_ori17 stddev_ori17 tps_onlyff17 latency_onlyff17 stddev_onlyff17; do
    eval "val=\$$var"
    if [ -z "$val" ] || [ "$val" = "" ] || [ -z "${val// /}" ]; then
        eval "$var=''"
    fi
done

# Ensure empty variables are set to empty strings (for valid JavaScript)
times_str=${times_str:-}
ori_tps13=${ori_tps13:-}
onlyff_tps13=${onlyff_tps13:-}
ori_tps18=${ori_tps18:-}
onlyff_tps18=${onlyff_tps18:-}
ori_tps17=${ori_tps17:-}
onlyff_tps17=${onlyff_tps17:-}

# Format labels with statistics
format_label() {
    local base=$1
    local tps=$2
    local latency=$3
    local stddev=$4
    # Remove any leading/trailing whitespace
    tps=$(echo "$tps" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    latency=$(echo "$latency" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    stddev=$(echo "$stddev" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Check if all values are non-empty and are valid numbers
    if [ -n "$tps" ] && [ -n "$latency" ] && [ -n "$stddev" ] && \
       [ "$tps" != "" ] && [ "$latency" != "" ] && [ "$stddev" != "" ]; then
        # Verify they're numeric - must contain at least one digit
        if echo "$tps" | grep -qE '^[0-9]+\.?[0-9]*$' && \
           echo "$latency" | grep -qE '^[0-9]+\.?[0-9]*$' && \
           echo "$stddev" | grep -qE '^[0-9]+\.?[0-9]*$'; then
            # Use awk for floating point formatting
            tps_fmt=$(echo "$tps" | awk '{printf "%.2f", $1}')
            lat_fmt=$(echo "$latency" | awk '{printf "%.3f", $1}')
            stddev_fmt=$(echo "$stddev" | awk '{printf "%.3f", $1}')
            # Return formatted label with stats
            echo "${base} (TPS: ${tps_fmt}, Lat: ${lat_fmt}ms, StdDev: ${stddev_fmt}ms)"
        else
            echo "$base"
        fi
    else
        echo "$base"
    fi
}

# Escape labels for JavaScript (escape quotes and backslashes)
escape_js() {
    echo "$1" | sed "s/\\\\/\\\\\\\\/g" | sed "s/\"/\\\\\"/g"
}

label_ori13=$(escape_js "$(format_label "v13 Original" "$tps_ori13" "$latency_ori13" "$stddev_ori13")")
label_onlyff13=$(escape_js "$(format_label "v13 Fillfactor=50" "$tps_onlyff13" "$latency_onlyff13" "$stddev_onlyff13")")
label_ori18=$(escape_js "$(format_label "v18 Original" "$tps_ori18" "$latency_ori18" "$stddev_ori18")")
label_onlyff18=$(escape_js "$(format_label "v18 Fillfactor=50" "$tps_onlyff18" "$latency_onlyff18" "$stddev_onlyff18")")
label_ori17=$(escape_js "$(format_label "v17 Original" "$tps_ori17" "$latency_ori17" "$stddev_ori17")")
label_onlyff17=$(escape_js "$(format_label "v17 Fillfactor=50" "$tps_onlyff17" "$latency_onlyff17" "$stddev_onlyff17")")

# Validate that we have at least some data
if [ -z "$times_str" ]; then
    echo "Warning: No time data found. Chart may not render properly." >&2
fi

# # Convert epoch times to readable dates (macOS compatible)
# times_array=(${times_str//,/ })
# date_labels=""
# for time in "${times_array[@]}"; do
#     # Use macOS date command to convert epoch to readable format
#     readable_date=$(date -r "${time%.*}" "+%H:%M:%S")
#     date_labels="${date_labels}\"${readable_date}\","
# done
# # Remove trailing comma
# date_labels=${date_labels%,}



# Generate HTML
cat > reports/pgbench_chart.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
</head>
<body>
    <canvas id="chart"></canvas>
    <script>
        try {
            const data = {
                labels: [$times_str],
                datasets: [{
                    label: "${label_ori13}",
                    data: [$ori_tps13],
                    borderColor: 'rgb(255, 165, 0)',
                    tension: 0.1
                }, {
                    label: "${label_onlyff13}",
                    data: [$onlyff_tps13],
                    borderColor: 'rgb(0, 255, 0)',
                    tension: 0.1
                }, {
                    label: "${label_ori18}",
                    data: [$ori_tps18],
                    borderColor: 'rgb(200, 40, 120)',
                    tension: 0.1
                }, {
                    label: "${label_onlyff18}",
                    data: [$onlyff_tps18],
                    borderColor: 'rgb(29, 122, 235)',
                    tension: 0.1
                },
                {
                    label: "${label_ori17}",
                    data: [$ori_tps17],
                    borderColor: 'rgb(255, 255, 0)',
                    tension: 0.1
                }, {
                    label: "${label_onlyff17}",
                    data: [$onlyff_tps17],
                    borderColor: 'rgb(0, 0, 0)',
                    tension: 0.1
                }].filter(dataset => dataset.data && dataset.data.length > 0)
            };

            // Check if we have any data
            if (data.datasets.length === 0) {
                throw new Error('No data available to display');
            }

            // Ensure labels array matches the data length
            if (data.labels.length === 0 && data.datasets[0].data.length > 0) {
                // Generate default labels if missing
                data.labels = data.datasets[0].data.map((_, i) => i);
            }

            const ctx = document.getElementById('chart');
            if (!ctx) {
                throw new Error('Canvas element not found');
            }

            new Chart(ctx, {
            type: 'line',
            data: data,
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'pgbench: Hot-Updates TPS Comparison'
                    },
                    legend: {
                        display: true,
                        position: 'bottom',
                        labels: {
                            boxWidth: 20,
                            padding: 15,
                            font: {
                                size: 11
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        title: {
                            display: true,
                            text: 'Time (seconds)'
                        }
                    },
                    y: {
                        title: {
                            display: true,
                            text: 'TPS'
                        }
                    }
                }
            }
            });
        } catch (error) {
            console.error('Error rendering chart:', error);
            document.body.innerHTML = '<h1>Error rendering chart</h1><p>' + error.message + '</p>';
        }
    </script>
</body>
</html>
EOF

echo "Chart generated successfully at reports/pgbench_chart.html"
exit 0
