#!/usr/bin/env bash

LINUX_GIT_TREE="${1:-experiments/linux/}"

export BASE_DIR="$HOME/.cache/arkanjo"

# NOTE: comment out this section so it doesn't have to be executed

subsystems=("iio" "gpu")

for subsystem in ${subsystems[@]}; do
    arkanjo preprocessor build --name "${subsystem}" --path "${LINUX_GIT_TREE}/drivers/${subsystem}/" --method "3" -S 80.0
done

source "scripts/graphs/gen_json.sh"

cd scripts/graphs
R -e "source('graph_gpu.R')"

exit 0
