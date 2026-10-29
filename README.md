# spa-infra

## AWS

### Requirement
Local環境に以下をインストール

- [aws cli](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html)
- [terraform](https://developer.hashicorp.com/terraform/install)
- [tflint](https://github.com/terraform-linters/tflint/releases)
- [gitleaks](https://github.com/gitleaks/gitleaks/releases)

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

> python --version
Python 3.9.12

> pip --version
pip 21.2.4 from C:\Users\katsu\anaconda3\lib\site-packages\pip (python 3.9)

> pre-commit --version
pre-commit 4.3.0

> gitleaks --version
gitleaks version 8.30.1
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
tflint, gitleaks, terraform fmtはpre-commit時に確認しているはずなのでMR時にのみ実行。
terraform planはpush時にのみ実行。Mergeの際はHCP Terraformで勝手にPlanする。

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
| ECS Service / Task | `api_tasks_enabled = false`でECS Serviceを削除する | `api_stack_enabled`とは独立して存在を制御する。RDSを削除する場合はDB接続情報がなくなるためService / Task Definitionも削除される。 |
| API Gateway | リクエスト課金のため、通信がなければAPI request料金は基本的に発生しない | APIだけを削除せず、削除する場合はVPC LinkやAPI側ALBなど関連リソースとまとめて扱う。 |
| API Gateway VPC Link | 固定の時間料金は基本的にないため、通常は残してよい | 60日間通信がないと`INACTIVE`になり、次の通信時にENIの再作成で復旧に時間がかかることがある。 |
| ALB | 停止機能はない。長期間使わない場合は削除を検討する | 通信がなくても時間料金が発生する。東京リージョンのApplication Load Balancerは約$0.0243/時（約$17.74/月・台）に加え、利用量に応じたLCU料金がある。現在のAPI用・Frontend用の2台で約$35.48/月（ALB時間料金のみ）。 |
| RDS Aurora | `rds_enabled = false`で削除する | 現設定の`db.t3.medium` 1台は約$0.125/時（約$91.25/月）。停止は最長7日で自動起動するため長期停止に使わない。現状はデータ未投入のため単純削除とし、自動バックアップ・最終スナップショットは作成しない（`skip_final_snapshot = true`）。将来データを保持する場合は削除前バックアップと復元手順を実装する。 |
| Cognito User Pool | 基本的に削除しない | User Pool削除でユーザーや認証設定を失う。利用者数に応じた課金で、OIDC/SAMLフェデレーションは月50 MAUまで無料枠があり、超過分は約$0.015/MAU・月。SMS、メール、Advanced Security Featuresは別料金。無料枠の適用条件はAWS料金ページを確認する。 |
| S3 Bucket | `s3_enabled = false`で削除する | 空でもBucket自体の月額料金は通常発生しない。削除時に中身も失うため、削除前に空であることを確認する。オブジェクトが残ると削除に失敗する。 |
| S3 Interface VPC Endpoint | Frontend ALBと同じflagで削除する | 東京リージョンで約$0.014/時/AZ（約$10.22/月/AZ）。現在の2 AZ構成では約$20.44/月に加えてデータ処理料金がかかる。Frontend ALBのtarget attachmentはEndpoint ENIを参照するため、関連リソースをまとめて扱う。 |

#### Terraform flags

設定場所は`terraform/env/dev/02_variables.auto.tfvars`の`resource_flags`。すべて`true`が通常稼働状態。

- `api_tasks_enabled`: `true`でECS Serviceを作成して設定済みdesired countでTaskを稼働し、`false`でServiceを削除する。RDSをOFFにするとTask Definitionを作成できないため、Serviceも削除される。
- `api_stack_enabled`: API Gateway、VPC Link、API側ALBなどAPI入口一式を作成・削除する。OFFでもECS Serviceは維持するが、ALBへの紐付けを外すためAPI経由では到達できない。Taskを稼働したままにするとFargate料金がかかるので、不要なら`api_tasks_enabled`もOFFにする。
- `frontend_edge_enabled`: Frontend ALB、S3 Interface VPC Endpoint、関連するlistener / target attachmentをまとめて作成・削除する。S3 Bucketは別flagで管理する。
- `s3_enabled`: Frontend S3 Bucketと関連設定を作成・削除する。S3をOFFにする前に`frontend_edge_enabled`もOFFにする。両立しない組み合わせはvariable validationで拒否する。
- `rds_enabled`: Aurora cluster、instance、DB subnet groupを作成・削除する。OFFにするとDB接続情報に依存するECS Service / Task Definitionも削除される。ONに戻すと空のDBを新規作成する。
- Cognito User Poolはユーザーを失うためflagの対象外とする。

flagを`false`にするとTerraformがリソース削除を計画する。適用前にplanのdestroy対象を確認する。特にRDSとS3は、現状ではデータを保持せず削除する設定である。

## Pre-commit
```
pre-commit sample-config | out-file .pre-commit-config.yaml -encoding utf8
```
.pre-commit-config.yamlを作る。外部通信は発生しない。初回のみ実行。
```
git config --local --unset-all core.hooksPath
pre-commit install
```
Git hookを有効化する。.git/hooks/pre-commitを作成する。外部通信は発生しない。初回のみ実行。Git clone後に実行。
```
pre-commit install-hooks
```
hook用の設定やライブラリの取得。外部通信が発生する。初回のみ実行。
```
pre-commit run # Stageファイルのみを対象に実行
pre-commit run --all-files # 全ファイルを対象に実行
```
動作確認コマンド。全ファイルに対してチェックを実行。

VSCodeのCommitボタンからhookされない場合は以下のように修正。
- .git/config：core.hooksPath に C:/Users/katsu/OneDrive/デスクトップ/work/spa-infra/.git/hooks を設定する。Git がこのリポジトリで使う hook の場所を明示する。
- pre-commit install --overwrite を実行。.git/hooks/pre-commitが再生成される。
- VS Codeのsettings.jsonの`git.path`にgitのパスを指定。`C:\\Program Files\\Git\\cmd\\git.exe`とか。

core.hooksPath が .git/hooks に設定されていても、pre-commit は設定が明示されていると hook のインストールを拒否します。設定が標準の .git/hooks を指しているなら、リポジトリのルートで PowerShell から次を実行してください。
これで Git の標準 hook ディレクトリが使われ、コミット時に pre-commit が実行されるはずです。core.hooksPath を意図的に別の hook 管理ツール用に設定している場合は、先にその影響を確認してください。

接続先: `http://spa-okmu-1480180708.ap-northeast-1.elb.amazonaws.com`