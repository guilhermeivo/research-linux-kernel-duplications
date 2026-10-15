#!/bin/bash
set -e

echo "Ativando virtualenv em /opt/venv..."
source /opt/venv/bin/activate

export PATH="/usr/local/bin:$PATH"

echo -e "/kernel/drivers/gpu/drm/amd/display/dc/gpio\n0.9\n1" | arkanjo-preprocessor
arkanjo explorer --limiter 5 --sort --no-color
arkanjo function offset_to_id --no-color
arkanjo duplication --no-color

ls /kernel