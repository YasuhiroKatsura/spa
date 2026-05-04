#!/bin/sh

set -e # エラー発生時にスクリプトを終了

AWS_ENV="$1"
TARGET_LAYER="$2"

echo "Changing directory to:" $TARGET_LAYER
cd terraform/$TARGET_LAYER/env/$AWS_ENV
pwd; ls -a

echo "Initializing Terraform."
terraform init

echo "Validating Terraform configuration."
terraform validate

echo "Planning Terraform changes."
# terraform plan -out=tfplan # バイナリに吐き出したほうがいいとは思うがどこに吐き出すか設計してない
terraform plan

echo "Task completed successfully!"