# Terraform

`terraform/` はデプロイ時のルートモジュールです。既存の state を継続して利用できるよう、Terraform の実行ディレクトリは変更しません。

## 構成

```text
terraform/
├── README.md
├── versions.tf                 # Terraform / Provider のバージョン制約
├── providers.tf                # Provider 設定
├── variables.tf                # ルートモジュールの入力
├── locals.tf                   # 共通タグ
├── main.tf                     # 子モジュールの呼び出し
├── outputs.tf                  # 公開する出力
├── moved.tf                    # 旧stateアドレスからの移行定義
├── environments/
│   └── dev.tfvars.example      # 環境別の入力値サンプル
└── modules/
    └── management-platform/
        ├── versions.tf
        ├── variables.tf
        ├── locals.tf
        ├── api.tf
        ├── lambda.tf
        ├── platform.tf
        ├── outputs.tf
        └── files/lambda/
```

- ルートモジュールは環境・Provider・共通タグの設定に限定します。
- AWS リソースの実装は `modules/management-platform` にまとめます。
- 環境固有値は `environments/*.tfvars` に置き、Git にはサンプルだけを保存します。
- `moved.tf` により、従来のルートリソースから子モジュールへの移動時も既存リソースを維持します。

## 利用方法

```bash
cp terraform/environments/dev.tfvars.example terraform/environments/dev.tfvars
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform validate
terraform -chdir=terraform plan -var-file=environments/dev.tfvars
```

既存環境へ初めてこの構成を適用する際は、`plan` に各リソースの `has moved to` が表示され、意図しない destroy/create がないことを確認してください。

チーム運用や本番環境では、S3 の versioning・暗号化・locking を有効にしたリモート state を使用してください。backend のバケット名などは組織・環境ごとに異なるため、このリポジトリには固定値を置いていません。

## 構成図

![L3アカウントと管理アカウントを分離したAWS構成図](../diagrams/aws-architecture.png)

L3側の単一AZ・単一プライベートサブネット構成、およびVPC・AZ・サブネットとLambdaのVPC接続は目標構成であり、現時点のTerraformには未実装です。
