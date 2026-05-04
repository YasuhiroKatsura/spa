#!/bin/sh

set -e # エラー発生時にスクリプトを終了

TARGET_LAYER="$1"

echo "Validating Terraform configuration for $TARGET_LAYER."

terraform init -backend=false # HCPに接続せずローカルで構文チェックのみ行う
terraform validate

echo "Task completed successfully!"