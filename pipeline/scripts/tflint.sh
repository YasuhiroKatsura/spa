#!/bin/sh

set -e # エラー発生時にスクリプトを終了

AWS_ENV="$1"
TARGET_LAYER="$2"

echo -e "\e[34mChanging directory to terraform root.\e[0m"
cd terraform/
pwd; ls -a

echo -e "\e[34mInitializing TFlint.\e[0m"
tflint --init

echo -e "\e[34mChanging directory to:" $TARGET_LAYER "\e[0m"
cd $TARGET_LAYER/env/$AWS_ENV
pwd; ls -a

echo -e "\e[34mRunning TFlint.\e[0m"
tflint -f compact --config=../../../.tflint.hcl

echo "Task completed successfully!"