# sample-spa: Frontend

## 初期設定・各種コマンド
git clone後以下を実行。
```bash
$ pwd
<work directory>\sample-spa\frontend

$ npm ci # package-lock.jsonを更新せずにライブラリをインストール
```

開発中は以下のコマンドでLocal Serverを立ち上げる。ソースコードの変更が即時反映される。
```bash
npx nuxt dev --port 3000
```

成果物をLocal Serverで確認する際には以下のコマンドを実行する。
```bash
$ npm run build

$ npm run preview
```

本番用の静的ファイルを出力する際には以下のコマンドを実行する。
```bash
$ npm run generate
```

## Frontend設計方針
### 基本的な考え方
- フレームワークにはNuxt.jsを採用。
- 静的型付けが可能なTypeScriptを採用。

### Frontendディレクトリ構成
```text
.
└── frontend/
    ├── .nuxt/
    ├── .output/
    │   └── server/ # npm run buildの出力先
    │   └── public/ # npm run generateの出力先
    ├── app/
    │   └── app.vue # アプリ実装
    ├── dist/
    ├── node_modules/
    ├── patches/ # ライブラリの脆弱性対応
    ├── public/ # アイコンとか
    ├── .nvmrc
    ├── nuxt.config.ts
    ├── package-lock.json # 依存ライブラリのバージョン指定
    ├── package.json # 依存ライブラリの指定
    └── tsconfig.json # typescriptの型定義
```
