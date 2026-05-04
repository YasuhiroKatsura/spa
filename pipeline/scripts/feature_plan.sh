#!/bin/sh

set -e # エラー発生時にスクリプトを終了

TARGET_LAYER="$1"

echo "Terraform plan for $TARGET_LAYER."
    
terraform init -backend=false # HCPに接続せずローカルで構文チェックのみ行う
terraform validate
# terraform plan -out=tfplan # バイナリに吐き出したほうがいいとは思うがどこに吐き出すか設計してない
terraform plan

echo "Task completed successfully!"