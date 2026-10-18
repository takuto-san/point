# Terraform

## 構成図

[L3アカウントと管理アカウントを分離したAWS構成図（draw.io）](../docs/architecture-aws.drawio)

## 生成後のディレクトリ構成

```text
terraform/
├── README.md
├── versions.tf
├── providers.tf
├── variables.tf
├── locals.tf
├── management.tf
├── api.tf
├── lambda.tf
├── outputs.tf
├── terraform.tfvars.example
├── .terraform.lock.hcl
└── lambda/
    ├── index.mjs
    ├── schema.mjs
    └── store.mjs
```
