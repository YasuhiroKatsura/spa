# spa

## Requirement
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

## ディレクトリ構成
```
- aws
  - modules
    - network         # 通信の土台（VPC, Subnet, IGW, NATGW, Route Table）
    - security        # 権限と守り（IAM, Security Group, WAF, KMS）
    - compute         # 計算リソース（EC2, Auto Scaling, Lambda, EKS）
    - load_balancer   # トラフィック配分（ALB, NLB）
    - storage         # データの保存（S3, EFS）
    - database        # 構造化データ（RDS, Aurora, DynamoDB, ElastiCache）
    - monitoring      # 監視（CloudWatch, SNS）
```

## 構成図
xxx

## 方針
- [modules構造の考え方](https://docs.aws.amazon.com/ja_jp/prescriptive-guidance/latest/terraform-aws-provider-best-practices/structure.html#modularity)
- [基本思想](https://qiita.com/shogomuranushi/items/266f5ef342fb81a7a5cd)

## 参考
- [Terraform Document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## TODO
- [ ] tflint
- [ ] datadog
- [ ] cost alert
- [ ] gemini assistant (agent mode) or copilot
- [ ] draw.ioで構成図を書かせる (AWSアイコン利用)
- [ ] セキュアな秘匿情報運用
- [ ] ブランチ戦略
- [ ] CI/CD
- [ ] 単体テスト, 結合テストの自動化
- [ ] Antigravity
- [ ] snippet
- [ ] stateをS3で管理（まあローカルでもいいけど）
- [ ] kafka