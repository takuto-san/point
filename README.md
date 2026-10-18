# 解約金還元申請システム

「管理システム」「OpenAPI」「AWS構成」を統合した最小サーバーレス構成。

- `openapi/l3-management.openapi.yaml` — L3連携のデータ契約と受信・受信票API
- `terraform/` — 管理アカウントのAWSインフラ
- `Dockerfile` / `docker-compose.yml` — Swagger UI
- `tools/diagram.sh` — Terraform planからTerravisionで構成図を生成

```bash
docker compose up --build -d
# http://localhost:8080

node --test tests/*.test.mjs
terraform -chdir=terraform init
terraform -chdir=terraform validate
bash tools/diagram.sh
```

生成した構成図は `docs/architecture-aws.dot.png` / `.svg`。図生成にはTerraformとDockerを使用する。図用の一時コピーで仮のアカウントIDと認証情報を使い、AWSへ接続せずにplanを作成する。出力は未デプロイの設計図。

構成は `L3 → EventBridge → SQS → 受信Lambda → DynamoDB`。HTTPSのPUT/GETも同じLambdaと保存処理を使う。管理画面用にはCloudFront、非公開S3、Cognitoを用意する。詳細と実装範囲は [terraform/README.md](terraform/README.md) を参照。

L3アカウントの送信用IAMロールは別リポジトリ `takuto-san/point-l3` へ移設した。このリポジトリのTerraformは管理アカウントだけを操作する。`management_event_bus_arn` をL3側へ渡し、双方の `l3_account_id` を揃える。OpenAPIは管理側受信APIの正本として保持し、point-l3には送信先契約として同じ内容をコピーしている。

最小化に伴い、追加設計だったVPC・サブネット・NAT・Endpointを削除し、Lambdaを2つから1つへ統合。キューポリシーも共通化した。サーバーレス構成のため図にVPC/AZの枠は表示しない。Dockerの公開ポートはlocalhostに限定した。
