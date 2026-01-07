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

# Ensure empty variables are set to empty strings (for valid JavaScript)
times_str=${times_str:-}
ori_tps13=${ori_tps13:-}
onlyff_tps13=${onlyff_tps13:-}
ori_tps18=${ori_tps18:-}
onlyff_tps18=${onlyff_tps18:-}
ori_tps17=${ori_tps17:-}
onlyff_tps17=${onlyff_tps17:-}

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
                    label: 'v13 Original',
                    data: [$ori_tps13],
                    borderColor: 'rgb(255, 165, 0)',
                    tension: 0.1
                }, {
                    label: 'v13 Fillfactor=50',
                    data: [$onlyff_tps13],
                    borderColor: 'rgb(0, 255, 0)',
                    tension: 0.1
                }, {
                    label: 'v18 Original',
                    data: [$ori_tps18],
                    borderColor: 'rgb(200, 40, 120)',
                    tension: 0.1
                }, {
                    label: 'v18 Fillfactor=50',
                    data: [$onlyff_tps18],
                    borderColor: 'rgb(29, 122, 235)',
                    tension: 0.1
                },
                {
                    label: 'v17 Original',
                    data: [$ori_tps17],
                    borderColor: 'rgb(255, 255, 0)',
                    tension: 0.1
                }, {
                    label: 'v17 Fillfactor=50',
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
