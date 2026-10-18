# 解約金還元申請管理システム

## 概要

他社解約金還元申請の精査結果を受信し、担当者による確認・確定と顧客への結果通知を支える管理システム。L3環境で証跡解析・本人確認・ポイント付与判定を行い、許可された結果だけを管理システムへ連携する。

![解約金還元申請システムの全体像](docs/system-overview.png)

## 1. 依存関係

| 名前 | バージョン |
|---|---|
| Docker / Docker Compose | Compose v2 |
| Terraform | 1.6.0以上 |
| AWS CLI | v2 |
| Swagger UI | 5.25.3 |

## 2. セットアップ

```bash
git clone https://github.com/takuto-san/point.git
cd point
docker compose up --build -d --wait
docker compose ps
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
```

## 3. ディレクトリ構成

```text
point/
├── README.md
├── openapi.yaml
├── Dockerfile
├── docker-compose.yml
├── terraform/
│   ├── README.md
│   ├── *.tf
│   ├── terraform.tfvars.example
│   └── files/lambda/
└── docs/
    ├── aws-architecture.yaml
    ├── aws-architecture.png
    └── system-overview.png
```

## 4. AWS構成図

![AWS構成図](docs/aws-architecture.png)
