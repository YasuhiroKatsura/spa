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
- Terraform構成は `terraform/env/<環境>` をroot moduleとし、共通化するVPC、IAM、Security Groupのみを `terraform/modules` に分離する。アプリケーションのリソースは環境rootで管理する。

### Terraform構成

- `terraform/env/dev`: 開発環境のroot module（HCP Terraform workspace: `spa-infra-dev`）
- `terraform/env/dev/0_provide.tf`: provider、共通設定、環境設定、外部入力の宣言
- `terraform/env/dev/1_main.tf`: VPC、IAM、Security Group moduleの呼び出しとstateアドレス移行
- `terraform/env/dev/2_*.tf`: database、container、API Gateway、frontend、authのリソース
- `terraform/modules/vpc`: VPC、subnet、route
- `terraform/modules/iam`: ECS task IAM roles and policies
- `terraform/modules/sg`: 各ワークロードのSecurity Groupとルール

検証とplanは `terraform/env/dev` で実行する。HCP Terraform workspaceのWorking Directoryも `terraform/env/dev` に設定する。環境設定とCognito設定は `0_provide.tf` のlocalsで管理し、Entra IDの値は同ファイルで宣言した入力変数としてHCP Terraform workspace variables（または対応する `TF_VAR_...` 環境変数）から渡す。client secretはSensitiveにする。

既存のstateはHCP Terraform workspace `01_core_infra` と `03_landing_zone` に分かれている。統合後のworkspace `spa-infra-dev` に両方のstateを移行し、planで既存リソースの意図しない作成・削除がないことを確認してからapplyする。`moved`ブロックは同一state内のアドレス変更に対応するもので、workspace間のstate移行そのものは行わない。

### 構成図
xxx

### CognitoとEntra IDのフェデレーション

`terraform/env/dev/2_auth.tf` は、Cognito Hosted UI と Microsoft Entra ID の OIDC フェデレーションを定義する。

Entra ID の App registration には、Terraform output の `cognito_entra_idp_response_url` を Web redirect URI として登録する。SPA の redirect URI は `cognito_callback_urls` と `cognito_logout_urls` に設定する。SPA クライアントは Authorization Code flow と PKCE を使用する。

以下の値は HCP Terraform の workspace variables に設定する。`entra_client_secret` は必ず Sensitive にする。

- `TF_VAR_entra_tenant_id`
- `TF_VAR_entra_oidc_issuer_url`
- `TF_VAR_entra_oidc_authorize_url`
- `TF_VAR_entra_oidc_token_url`
- `TF_VAR_entra_oidc_jwks_url`
- `TF_VAR_entra_oidc_userinfo_url`
- `TF_VAR_entra_client_id`
- `TF_VAR_entra_client_secret`

`cognito_entra_idp_response_url` は Cognito Hosted UI の IdP 応答先であり、SPA の callback URL とは異なる。Cognito domain prefix は AWS アカウント内で一意にし、dev と prd で分ける。


## CI/CD
- terraform planはgitlab-ciの中で実装する。
CIはGitlab, CDはHCP Terraformという単位でプラットフォームを分離する。


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


[managed login page](https://spa-auth.auth.ap-northeast-1.amazoncognito.com/login?client_id=1u3j9e23em0405faeqhr5mb8tm&response_type=code&scope=email+openid+profile&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2F)

## その他
### 参考情報
- [Terraform設計方針の参考](https://qiita.com/shogomuranushi/items/266f5ef342fb81a7a5cd)
- [Terraform Document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Gitlab CICD構文リファレンス](https://docs.gitlab.com/ja-jp/ci/yaml/)
