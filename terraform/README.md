# Terraform

## 構成図

[L3アカウントと管理アカウントを分離したAWS構成図（draw.io）](../docs/architecture-aws.drawio)

## ディレクトリ構成

```text
terraform/
├── README.md
├── main.tf
├── api.tf
├── lambda.tf
├── variables.tf
├── outputs.tf
├── locals.tf
├── providers.tf
├── versions.tf
├── terraform.tfvars.example
├── .terraform.lock.hcl
└── files/
    └── lambda/
        ├── index.mjs
        ├── schema.mjs
        └── store.mjs
```
