# spa

## Application
xxx


## AWS

### Requirement
Local環境に以下をインストール

- [aws cli](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html)
- [terraform](https://developer.hashicorp.com/terraform/install)
- [tflint](https://github.com/terraform-linters/tflint/releases)

```
> aws --version
aws-cli/2.33.12 Python/3.13.11 Windows/11 exe/AMD64

> terraform -v
Terraform v1.14.3
on windows_amd64

Your version of Terraform is out of date! The latest version
is 1.14.5. You can update by downloading from https://developer.hashicorp.com/terraform/install

> tflint -v
TFLint version 0.61.0
+ ruleset.terraform (0.14.1-bundled)
```

### 設計方針
- core instance (storage, loadbalancer, compute, resource-base roleなど), observability (cloud watch, dataaogなど), landing zone (network, scp, control towerなど)の3層に分ける。
- simple is bestで作る。基本的にmodulesは使わない。ただしlanding zoneは組織全体で共通する設定項目のため例外とし、機能別で実装する。

### 構成図
xxx


## CI/CD
- ブランチ戦略: Github Flow


## その他
### 参考情報
- [Terraform設計方針の参考](https://qiita.com/shogomuranushi/items/266f5ef342fb81a7a5cd)
- [Terraform Document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Gitlab CICD構文リファレンス](https://docs.gitlab.com/ja-jp/ci/yaml/)

### TODO
- [ ] tflint
- [ ] datadog
- [ ] cost alert
- [ ] gemini assistant (agent mode) or copilot
- [ ] draw.ioで構成図を書かせる (AWSアイコン利用)
- [ ] セキュアな秘匿情報運用
- [ ] ブランチ戦略
- [ ] CI/CD
- [ ] git hooks
- [ ] trivy
- [ ] 単体テスト, 結合テストの自動化
- [x] Antigravity
- [ ] snippet
- [ ] stateをS3で管理（まあローカルでもいいけど）
- [ ] kafka