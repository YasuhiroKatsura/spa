# spa-infra

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
Terraform v1.15.1
on windows_amd64

Your version of Terraform is out of date! The latest version
is 1.15.1. You can update by downloading from https://developer.hashicorp.com/terraform/install

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

### 方針
- ブランチ戦略: Github Flow
- mainへのマージリクエストをトリガに、以下の2段構成でパイプライン実行する。
  - CI: 脆弱性スキャン、terraform validate、READMEなどのドキュメント更新
    - 環境: Gitlab CI
    - mainブランチへのMerge Requestをトリガにする。
  - CD: terraform plan, apply
    - 環境: HCP Terraform
    - terraform plan結果は保存し、手動承認後にapplyする。
- 開発の流れ (環境がdevしかない前提)
  1. feature/xxxブランチを作成
  2. 開発する。ローカル端末でterraform validate, planを実行し問題がないことを確認する。  
     ※ ローカル端末からapplyは行わない (VCS連動なのでできない)。
  3. mainへのマージリクエストを作成する。このタイミングでCIが実行される。
  4. CI結果に問題がなければマージする。このタイミングでCDが実行される。
  5. terraform planの結果に問題がなければ承認する。このタイミングでterraform applyが実行され、stateファイルが更新される。
  6. 問題が生じた場合は過去のstateファイルから戻しを行う。


## その他
### 参考情報
- [Terraform設計方針の参考](https://qiita.com/shogomuranushi/items/266f5ef342fb81a7a5cd)
- [Terraform Document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Gitlab CICD構文リファレンス](https://docs.gitlab.com/ja-jp/ci/yaml/)

### TODO
- システム
  - [x] VPCのプロトタイプ実装
  - [x] ALB-S3のプロトタイプ実装
  - [x] API GWのプロトタイプ実装
  - [ ] ECS/Fargateのプロトタイプ実装
  - [ ] Auroraのプロトタイプ実装
  - [ ] S3手前のAPNのFQDNを任意に変える (Route53)
- CI/CD (インフラ)
  - [x] ブランチ戦略
  - [x] Pipelineのプロトタイプ実装 (Gitlab CI/HCP Terraform)
  - [x] stateをHCP Terraformで管理
  - [x] エラーハンドリング (scriptがこけたら止める)
  - [x] mainブランチ以外、git commitをトリガに実行されないようにする
  - [x] featureへのpushをトリガにterraform planする
  - [ ] featureの自動planをやめ、planまではLocalで行うように実装する
  - [ ] HCP Terraform設定をtfファイルで管理
  - [x] 01/02/03の各レイヤでのCI/CD実装
  - [ ] CDは並列実行されず、03→02→01の順序でapplyされるように実装する
  - [ ] terraform plan結果の保存
  - [ ] tflint, terraform fmt -checkを実装
  - [ ] 単体テスト, システム内結合テストを実装
  - [ ] git hooksの実装, CI/CDとどのように組み合わせるか検討
  - [ ] マージリクエストが拒否された場合に後続処理を止める
  - [ ] TFCのrunがこけた場合やdiscardされた場合にterraformを戻す。
  - [ ] TFCのrunがこけた場合やdiscardされた場合にgitlab mainブランチを戻す。
  - [ ] 脆弱性スキャンを実装 (trivyが使えるか検討)
  - [ ] READMEの自動更新を実装
- CI/CD (UI)
  - [ ] Pipelineのプロトタイプ実装 (Gitlab CI/Code Pipeline)
- CI/CD (API)
  - [ ] Pipelineのプロトタイプ実装 (Gitlab CI/Code Pipeline)
- ログ/監視運用
  - [ ] Datadogの導入
  - [ ] ログ保管の実装
  - [ ] cost alertの導入
- セキュリティ
  - [ ] CI/CD関連のIAM設定をterraformで実装(03/module/tfc_role)
  - [ ] Cognitoの導入
  - [ ] AD, ADFS (on EC2) の導入
  - [ ] API GatewayへのJWT Authorizor導入
  - [ ] Local端末でのセキュアな秘匿情報運用
  - [ ] Control Towerのプロトタイプ実装
  - [ ] IAM User, IAM GroupのTerraform管理
  - [ ] ALB, API GatewayへのSSL証明書導入 (ACM)
- テスト
  - [ ] Datadogでシステム外結合テストを実装
- ドキュメント運用
  - [ ] AIにdraw.ioで構成図を書かせる
- 開発
  - [x] terraformのディレクトリ構成, 方針の検討
  - [x] Antigravity
  - [ ] o1_core_infra, 02_observability, 数字が逆のほうがdeployの順序性がわかりやすい？
  - [ ] terraform provider Vup運用の検討
  - [x] mainに直接pushできないようにする
- ガバナンス
  - [ ] ライセンス保護