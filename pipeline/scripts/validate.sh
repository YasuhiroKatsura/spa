#!/bin/sh

set -e # エラー発生時にスクリプトを終了

AWS_ENV="$1"
TARGET_LAYER="$2"

echo "Changing directory to:" $TARGET_LAYER
cd terraform/$TARGET_LAYER/env/$AWS_ENV
pwd; ls -a

echo "Initializing Terraform."
terraform init -backend=false # HCPに接続せずローカルで構文チェックのみ行う

echo "Validating Terraform configuration."
terraform validate

echo "Task completed successfully!"