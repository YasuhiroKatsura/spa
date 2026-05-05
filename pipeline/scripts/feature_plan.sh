#!/bin/sh

set -e # エラー発生時にスクリプトを終了

AWS_ENV="$1"
TARGET_LAYER="$2"

echo -e "\e[34mChanging directory to:" $TARGET_LAYER "\e[0m"
cd terraform/$TARGET_LAYER/env/$AWS_ENV
pwd; ls -a

echo -e "\e[34mInitializing Terraform.\e[0m"
terraform init

echo -e "\e[34mValidating Terraform configuration.\e[0m"
terraform validate

echo -e "\e[34mPlanning Terraform changes.\e[0m"
# terraform plan -out=tfplan # バイナリに吐き出したほうがいいとは思うがどこに吐き出すか設計してない
terraform plan

echo -e "\e[32mTask completed successfully!\e[0m"