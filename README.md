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

検証とplanは `terraform/env/dev` で実行する。HCP Terraform workspaceのWorking Directoryも `terraform/env/dev` に設定する。変数の型定義は `01_variables.tf`、開発環境の設定値は自動読込される `terraform.tfvars` で管理する。Entra IDの値はHCP Terraform workspace variables（または対応する `TF_VAR_...` 環境変数）から渡し、client secretはSensitiveにする。

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
- `TF_TOKEN_app_terraform_io`: GitlabのVariablesに設定


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

### Module化
当プロジェクトにおけるTerraformモジュールは、「複数箇所で参照される共通インフラパーツ（VPC、IAM、共通SG等）のガードレール化」 を目的として作成します。

- モジュール化の条件:
  - 複数のリソースや環境から一貫した設定で参照されること
  - variables.tf のパラメータ数が少なく、大半を default 値で隠蔽（カプセル化）できること

- モジュール化しない条件:
  - アプリケーション固有のリソース（ECS, EC2, RDS等）
  - 変数の種類が多く、ルート側にそのままパラメータを露出させることになる場合

[managed login page](https://spa-auth.auth.ap-northeast-1.amazoncognito.com/login?client_id=1u3j9e23em0405faeqhr5mb8tm&response_type=code&scope=email+openid+profile&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2F)

## その他
### 参考情報
- [Terraform設計方針の参考](https://qiita.com/shogomuranushi/items/266f5ef342fb81a7a5cd)
- [Terraform Document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Gitlab CICD構文リファレンス](https://docs.gitlab.com/ja-jp/ci/yaml/)

### dev環境の停止・削除方針（メモ）

普段AWSを利用しない期間のrunning costを抑える。料金は東京リージョン（`ap-northeast-1`）での概算であり、データ量・利用状況・税などにより変動する。適用前にTerraform planで削除対象を確認する。

#### リソースごとの扱い

| リソース | 方針 | 注意点 |
| --- | --- | --- |
| ECS Service / Task | `desired_count = 0`で停止するflagを設ける | Service、Cluster、Task Definitionは残し、実行Taskだけ停止する。再開しやすい。 |
| API Gateway | リクエスト課金のため、通信がなければAPI request料金は基本的に発生しない | APIだけを削除せず、削除する場合はVPC LinkやAPI側ALBなど関連リソースとまとめて扱う。 |
| API Gateway VPC Link | 固定の時間料金は基本的にないため、通常は残してよい | 60日間通信がないと`INACTIVE`になり、次の通信時にENIの再作成で復旧に時間がかかることがある。 |
| ALB | 停止機能はない。長期間使わない場合は削除を検討する | 通信がなくても時間料金が発生する。東京リージョンのApplication Load Balancerは約$0.0243/時（約$17.74/月・台）に加え、利用量に応じたLCU料金がある。現在のAPI用・Frontend用の2台で約$35.48/月（ALB時間料金のみ）。 |
| RDS Aurora | 長く使わない場合は、バックアップを取ってから削除する | 現設定の`db.t3.medium` 1台は約$0.125/時（約$91.25/月）。停止は最長7日で自動起動するため長期停止に使わない。削除前に手動スナップショットを取得し、最終スナップショットも有効化する。自動バックアップ保持期間は1日、`skip_final_snapshot = true`のため、現状のままでは削除時の最終スナップショットが作られない。復元後はDB endpointが変わる可能性がある。 |
| Cognito User Pool | 基本的に削除しない | User Pool削除でユーザーや認証設定を失う。利用者数に応じた課金で、OIDC/SAMLフェデレーションは月50 MAUまで無料枠があり、超過分は約$0.015/MAU・月。SMS、メール、Advanced Security Featuresは別料金。無料枠の適用条件はAWS料金ページを確認する。 |
| S3 Bucket | 空でもBucket自体の月額料金は通常発生しない。Bucketは残す | データ、リクエスト、追加機能に応じて課金。削除時に中身も失うため、停止flagの対象にしない。 |
| S3 Interface VPC Endpoint | Frontend ALBと同じflagで削除する | 東京リージョンで約$0.014/時/AZ（約$10.22/月/AZ）。現在の2 AZ構成では約$20.44/月に加えてデータ処理料金がかかる。Frontend ALBのtarget attachmentはEndpoint ENIを参照するため、関連リソースをまとめて扱う。 |

#### flag設計の案

- `api_tasks_enabled`: `true`で通常のdesired count、`false`で`0`にしてECS Taskを停止する。
- `api_stack_enabled`: API Gateway、VPC Link、API側ALBなどAPI入口のリソース一式をまとめて作成・削除する。
- `frontend_edge_enabled`: Frontend ALB、S3 Interface VPC Endpoint、関連するlistener / target attachmentをまとめて作成・削除する。S3 Bucket自体は対象外とする。
- RDSは通常のON/OFF flagから分ける。削除前に手動スナップショットを取得し、snapshotからの復元を別手順として管理する。
- Cognito User PoolとS3 Bucketは、データ・ユーザーを失うリスクがあるため、通常の停止・削除flagの対象にしない。

flagを`false`にするとTerraformがリソース削除を計画する場合がある。特にRDS、Cognito、S3は、planのdestroy対象を確認してからapplyする。
