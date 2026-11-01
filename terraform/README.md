# sample-spa: Terraform

## 初期設定・各種コマンド
git clone後以下を実行。
```
> pwd
<work directory>\sample-spa\terraform\env\dev
> terraform init
```

## Terraform設計方針

### Terraform Module設計
- `terraform/env/<環境>` をroot moduleとする。dev環境しかないけどええねん。
- 複数のリソースや環境から一貫した設定で参照されるリソースのみmoduleとして実装し、カプセル化する。
  これらは`terraform/modules`に分離する。
  それ以外はモジュール化せず、rootで管理する。
  - 例: VPC、Subnet、IAM、Security Group
  - module化するとterraformに明るくない人間が変数をいじるだけで運用・保守できるというメリットはあるが、一方で詳細設定が複数ファイルに分散するため追いかけるのが辛くなる。
  個人開発なので極力moduleは使わない。
- AI が勝手にAWS触れてしまうのでローカル環境にはaws credentialsを配置しない。
  - AWSへのdeployはCICDパイプラインで実行する。

### Terraformディレクトリ構成
```text
.
└── terraform/
    ├── env/
    │   └── dev/
    │       └── templates/ # json形式のポリシーを格納
    │       └── .terraform.lock.hcl
    │       └── 00_backend.tf
    │       └── 01_call_modules.tf # モジュール呼び出し
    │       └── 01_variables.auto.tfvars # モジュール呼び出し時のパラメータ設定
    │       └── 01_variables.tf # モジュール呼び出し時の変数定義
    │       └── 02_api.tf # ECS関連の実装
    │       └── 02_auth.tf # Cognito関連の実装
    │       └── 02_database.tf # RDS関連の実装
    │       └── 02_frontend.tf # Frontend用S3関連の実装
    │       └── 02_variables.auto.tfvars # root moduleのパラメータ設定
    │       └── 02_variables.tf # root moduleの変数定義
    └── modules/
        ├── iam/ # IAM関連の共通化
        ├── sg/ # Security Group関連の共通化
        └── vpc/ # VPC, Subnet関連の共通化
```

### Terraformセキュリティ方針
- 秘匿情報はHCP TerraformにSecretとして持たせる。ハードコーディングはNG。

## AWSリソース設計方針

### Frontend配信
- ALB→VPC Endpoint→S3の構成をとる。CloudFrontはリッチすぎるので利用しないがちょっと興味あり。
- S3のフロントエンドはhost headerで宛先バケットを判断しているので、listener ruleでhost headerがバケット名を含むように書き換える。
- ヘルスチェックはlisterner ruleを介さないのでhost headerの書き換えが適用されない。
  よってS3は300, 400台の応答を返すので、2xx～4xxを正常応答として扱う。

### API提供
- API Gateway→ECSの構成をとる。
- コンテナイメージには`amazoncorretto:21-alpine`を採用する。
  - SpringBoot開発におけるデファクトスタンダード。軽量。
  - AWSによる無償LTSサポートあり。
  - より軽量なdistrolessも興味はあるが運用性が落ちるため優先度を下げた。

### Database
- RDS Aurora PostgreSQLを採用。

### CognitoとEntra IDのフェデレーション
- Cognito EntraID連携 (OIDC/SAML), Lambda Authorizorあたりを利用。
  まだなんにも考えてない。
- テスト用のManaged Loginエンドポイントは[こちら](https://spa-auth.auth.ap-northeast-1.amazoncognito.com/login?client_id=51hh08k8vd56o89b8odirjej2v&response_type=code&scope=email+openid+profile&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2F)


## AWSリソース停止・削除方針
- 利用しない期間はこまめにリソース削除してrunning costを抑える。
- `resource_flags`で以下のリソース単位で制御する。
  もっといい方法ありそうだがいったんこれでいく。
  - リソース間の依存関係が強いのでもう少しまとまった単位で削除できるようにしたい。
  - ステートフルなリソースは削除前にバックアップを取りたい。

| リソース | 削除方針 | 注意点 |
| --- | --- | --- |
| ECS Service / Task | `api_tasks_enabled = false`でECS Serviceを削除する | `api_stack_enabled`とは独立して存在を制御する。RDSを削除する場合はDB接続情報がなくなるためService / Task Definitionも削除される。 |
| API Gateway | リクエスト課金のため、通信がなければAPI request料金は基本的に発生しない | APIだけを削除せず、削除する場合はVPC LinkやAPI側ALBなど関連リソースとまとめて扱う。 |
| API Gateway VPC Link | 固定の時間料金は基本的にないため、通常は残してよい | 60日間通信がないと`INACTIVE`になり、次の通信時にENIの再作成で復旧に時間がかかることがある。 |
| ALB | 停止機能はない。長期間使わない場合は削除を検討する | 通信がなくても時間料金が発生する。東京リージョンのApplication Load Balancerは約$0.0243/時（約$17.74/月・台）に加え、利用量に応じたLCU料金がある。現在のAPI用・Frontend用の2台で約$35.48/月（ALB時間料金のみ）。 |
| RDS Aurora | `rds_enabled = false`で削除する | 現設定の`db.t3.medium` 1台は約$0.125/時（約$91.25/月）。停止は最長7日で自動起動するため長期停止に使わない。現状はデータ未投入のため単純削除とし、自動バックアップ・最終スナップショットは作成しない（`skip_final_snapshot = true`）。将来データを保持する場合は削除前バックアップと復元手順を実装する。 |
| Cognito User Pool | 基本的に削除しない | User Pool削除でユーザーや認証設定を失う。利用者数に応じた課金で、OIDC/SAMLフェデレーションは月50 MAUまで無料枠があり、超過分は約$0.015/MAU・月。SMS、メール、Advanced Security Featuresは別料金。無料枠の適用条件はAWS料金ページを確認する。 |
| S3 Bucket | `s3_enabled = false`で削除する | 空でもBucket自体の月額料金は通常発生しない。削除時に中身も失うため、削除前に空であることを確認する。オブジェクトが残ると削除に失敗する。 |
| S3 Interface VPC Endpoint | Frontend ALBと同じflagで削除する | 東京リージョンで約$0.014/時/AZ（約$10.22/月/AZ）。現在の2 AZ構成では約$20.44/月に加えてデータ処理料金がかかる。Frontend ALBのtarget attachmentはEndpoint ENIを参照するため、関連リソースをまとめて扱う。 |
