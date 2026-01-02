#!/bin/bash

# Extract data
# hash_data=$(docker compose logs pgbench_hash | grep progress | \
#     awk '{print $4, $6}' | sed 's/,//g' | \
#     awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}')

ori_data13=$(docker compose logs pgbench_ori13 | grep progress | \
    awk '{print $4, $6}' | sed 's/,//g' | \
    awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}')

onlyff_data13=$(docker compose logs pgbench_onlyff13 | grep progress | \
    awk '{print $4, $6}' | sed 's/,//g' | \
    awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}')

ori_data18=$(docker compose logs pgbench_ori18 | grep progress | \
    awk '{print $4, $6}' | sed 's/,//g' | \
    awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}')

onlyff_data18=$(docker compose logs pgbench_onlyff18 | grep progress | \
    awk '{print $4, $6}' | sed 's/,//g' | \
    awk '{times=times $1 ","; tps=tps $2 ","} END {print times ";" tps}')

# Parse into arrays
# IFS=';' read -r times_str hash_tps <<< "$hash_data"
IFS=';' read -r times_str ori_tps13 <<< "$ori_data13"
IFS=';' read -r _ onlyff_tps13 <<< "$onlyff_data13"
IFS=';' read -r _ ori_tps18 <<< "$ori_data18"
IFS=';' read -r _ onlyff_tps18 <<< "$onlyff_data18"

# Remove trailing commas
times_str=${times_str%,}
# hash_tps=${hash_tps%,}
ori_tps13=${ori_tps13%,}
onlyff_tps13=${onlyff_tps13%,}
ori_tps18=${ori_tps18%,}
onlyff_tps18=${onlyff_tps18%,}

# Convert epoch times to readable dates (macOS compatible)
times_array=(${times_str//,/ })
date_labels=""
for time in "${times_array[@]}"; do
    # Use macOS date command to convert epoch to readable format
    readable_date=$(date -r "${time%.*}" "+%H:%M:%S")
    date_labels="${date_labels}\"${readable_date}\","
done
# Remove trailing comma
date_labels=${date_labels%,}



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
        const data = {
            labels: [$date_labels],
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
            }]
        };

        new Chart(document.getElementById('chart'), {
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
    </script>
</body>
</html>
EOF

