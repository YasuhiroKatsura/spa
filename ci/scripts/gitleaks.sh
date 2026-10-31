#!/bin/sh

set -e # エラー発生時にスクリプトを終了

echo -e "\e[34mRunning Gitleaks.\e[0m"
gitleaks detect --source "$CI_PROJECT_DIR" --verbose --redact

echo "Task completed successfully!"