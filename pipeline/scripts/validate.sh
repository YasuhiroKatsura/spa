#!/bin/sh

TARGET_LAYER="$1"

echo "Processing directory: $TARGET_LAYER"

terraform init -backend=false # HCPに接続せずローカルで構文チェックのみ行う
terraform validate