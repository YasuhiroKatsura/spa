#!/bin/sh

set -e # エラー発生時にスクリプトを終了

AWS_ENV="$1"

echo -e "\e[34mChanging directory to terraform/env/$AWS_ENV\e[0m"
cd "terraform/env/$AWS_ENV"
echo "current directory: $(pwd)"

echo -e "\e[34mInitializing Terraform.\e[0m"
terraform init

echo -e "\e[34mRunning Terraform plan.\e[0m"
terraform plan

echo "Task completed successfully!"