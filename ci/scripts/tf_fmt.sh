#!/bin/sh

set -e # エラー発生時にスクリプトを終了

echo -e "\e[34mRunning terraform fmt.\e[0m"

terraform fmt -check -diff -recursive terraform/

echo "Task completed successfully!"