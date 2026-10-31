#!/bin/sh

set -e # エラー発生時にスクリプトを終了

AWS_ENV="$1"

echo -e "\e[34mChanging directory to terraform root.\e[0m"
cd terraform/
echo "current directory: $(pwd)"

echo -e "\e[34mInitializing TFlint.\e[0m"
tflint --init

echo -e "\e[34mChanging directory to terraform/env/$AWS_ENV\e[0m"
cd "env/$AWS_ENV"
echo "current directory: $(pwd)"

echo -e "\e[34mRunning TFlint.\e[0m"
tflint -f compact --config=../../.tflint.hcl # 修正項目がある場合はexit code 2を吐いて停止

echo "Task completed successfully!"