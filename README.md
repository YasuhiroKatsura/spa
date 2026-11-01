# sample-spa

## 概要
- 何のアプリにするかは決めてない。たぶん家計簿とか。勉強用。
- Endpointは[こちら](http://spa-okmr-515882119.ap-northeast-1.elb.amazonaws.com/)

## ディレクトリ構成
- prjectを複数分けることによる負荷を避けるためモノレポとする。

```text
.
├── .gitlab/
│   └── merge_request_templates/
├── ansible/
├── backend/
│   └── src/
├── chat/
├── ci/
│   └── scripts/
├── frontend/
│   ├── app/
│   ├── patches/
│   └── public/
├── terraform/
│   ├── env/
│   │   └── dev/
│   │       └── templates/
│   └── modules/
│       ├── iam/
│       ├── sg/
│       └── vpc/
├── .gitlab-ci.yaml
├── .pre-commit-config.yaml
└── README.md
```

## 構成図
TBD

## 技術スタック
| 領域 | 製品名 | バージョン | 用途 |
|---|---|---|---|
| Frontend | [Node.js](https://nodejs.org/ja/download) | 26.13.0 | Javascript実行環境 |
|  | [npm](https://nodejs.org/ja/download) | 12.2.1 | Node.jsライブラリ管理 |
| Infra | [amazoncorretto](https://hub.docker.com/hardened-images/catalog/dhi/amazoncorretto?tagDefinitionId=amazoncorretto%2Fdebian-13%2F21-fips-dev) | 21-alpine | API用ベースコンテナイメージ |
|| [Terraform](https://developer.hashicorp.com/terraform/install) | 1.15.1| AWS/Azure/Datadog構成管理 |
|| [TFLint](https://github.com/terraform-linters/tflint/releases) | 0.61.0| terraform lint |
|| [pre-commit](https://pre-commit.com/#installation) | 4.3.0 | pre-commit実行 |
|| [Python](https://www.python.org/downloads/) | 3.9.12| pre-commit依存ツール |
|| [pip](https://pypi.org/project/pip/) | 21.2.4| pythonライブラリ管理 |
|| [Gitleaks](https://github.com/gitleaks/gitleaks/releases) | 8.30.1 | コード内の秘匿情報検知 |


## 初期設定・各種コマンド
詳細は各ディレクトリ内のREADMEを参照。

## 設計方針
詳細は各ディレクトリ内のREADMEを参照。

## ブランチ運用
- ブランチ戦略はGithub Flowとする。
  - `main`: 直接commit禁止。MR完了後、AWS環境にデプロイされる。
  - `feature/xxx`: 各種機能追加。
- commitコメントには以下のプレフィックスをつける。（例: fix: XXXの修正）

| prefix | 用途 |
|---|---|
| fix | バグ修正 |
| feat | 機能追加 |
| docs | ドキュメント修正 |
| refactor | リファクタリング |
| test | テスト実行/テストコード追加 |
| chore | その他 |
