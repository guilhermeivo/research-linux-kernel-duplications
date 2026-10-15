#!/usr/bin/env bash

if [ -z "${BASE_DIR:-}" ]; then
    echo "BASE_DIR is empty"
    exit 1
fi

mkdir -p "$BASE_DIR"

# loop in profiles
# $HOME/.cache/arkanjo/[profiles]/*
for dir in "$BASE_DIR"/*; do
    [ -d "$dir" ] || continue

    name=$(basename "$dir")

    echo "Processing $name..."
    arkanjo explorer --name "$name" --json -S 90.0 > "$dir/$name.json"
done
