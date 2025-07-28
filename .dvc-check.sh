#!/bin/bash
set -e

# Check DVC status with remote
output=$(dvc status)

if [[ "$output" != "Data and pipelines are up to date." ]]; then
    echo "❌ DVC status shows changes not in sync with remote:"
    echo "$output"
    echo "🔒 Please run './dvc-push.sh' before committing if you wish to sync your files."
    exit 1
fi