# sample-spa: CI/CD

## 全体方針

### 実行環境
| Phase | 実行環境 | 用途 | トリガ |
|---|---|---|---|
| pre-commit | Local端末 | Localでのlint、検証、テスト | git commit |
| CI | Gitlab | lint、検証、テスト | git push / MR |


### 基本的な考え方
- pushやMRのタイミングでこけまくると開発スピードが落ちるので、pre-commitを導入し、コードの不備を極力Local環境で検知できるように設計する（Shift Left）。
- CIはGitlab-CIを採用する。
  CDはfrontend/backend/infraそれぞれに適した実行環境を採用する。
- pre-commit段階でlint、検証、テストを行っているが、マージ直前にも改めて確認する。
  このため、MRのタイミングでも同様の処理をCIパイプラインにて実行する。

### CI/CDディレクトリ構成
```text
.
├── ci/
│   └── scripts/ # jobの中で呼び出される処理スクリプト
│   └── backend-ci.yaml # backend関連のCI実装
│   └── frontend-ci.yaml # frontend関連のCI実装
│   └── infra-ci.yaml # terraform/ansible関連のCI実装
├── .gitlab-ci.yaml # gitlab ciのメインファイル
└── .pre-commit-config.yaml # pre-commitのメインファイル
```

## Terraform CI/CD設計方針

### 実行環境

| Phase | 実行環境 | 用途 | トリガ |
|---|---|---|---|
| CD | HCP Terraform | AWS環境へのdeploy | git merge |

### 基本的な考え方
- 実行環境と実行トリガの概要は下表のとおり。
- AWS環境へのdeployはmainブランチへのマージの際に行われるが、その都度失敗すると開発スピードが落ちる。
  対策として、featureブランチへのpushの都度terraform planを実行する。
  - Gitlabの実行環境はAWSへの接続ができないため、Gitlab実行環境からHCP Terraformを呼び出してterraform planを実行する。
  - このため、HCP TerraformへのAccess TokenをGitlabに持たせる必要があるので注意。
- HCP Terraformのworkspaceは環境毎に1つとする（dev環境しかないけども）。

### Stage設計
| Phase | Stage | 実行処理 | トリガ |
|---|---|---|---|
| pre-commit | - | gitleaks, tflint, terraform fmt, terraform validate | git commit |
| CI | lint | gitleaks, tflint, terraform fmt  | MR |
|  | plan | terraform plan | git push |
| CD | - | terraform apply | git merge |


## Frontend CI/CD設計方針

### 実行環境

| Phase | 実行環境 | 用途 | トリガ |
|---|---|---|---|
| CD |  | AWS環境へのdeploy | git merge |

### 基本的な考え方
-

### Stage設計
| Phase | Stage | 実行処理 | トリガ |
|---|---|---|---|
|  |  |  |  |

## Backend CI/CD設計方針

### 実行環境

| Phase | 実行環境 | 用途 | トリガ |
|---|---|---|---|
| CD |  | AWS環境へのdeploy | git merge |

### 基本的な考え方
-

### Stage設計
| Phase | Stage | 実行処理 | トリガ |
|---|---|---|---|
|  |  |  |  |
