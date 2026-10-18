# 解約金還元申請管理システム — point

他社解約金還元申請の精査結果を受信し、担当者による確認・確定と顧客への結果通知を支える管理システム。精査工数を月約30時間削減し、7日以内に審査結果を通知することを業務目標とする。

設計の基準は「管理システム」チャットの最新の全体像・画面仕様。L3内の証跡解析・本人確認・ポイント付与判定は [point-l3](https://github.com/takuto-san/point-l3)、管理側の受信・保存・配信基盤はこのリポジトリで管理する。

## 環境セットアップ

### 必要なツール

| ツール | 用途 |
|---|---|
| Git | ソースの取得 |
| Docker / Docker Compose v2 | Swagger UIの起動。Docker Desktop等を起動しておく |
| Node.js 22 | 受信処理のテスト |
| Terraform 1.6以上 | AWS構成の初期化・検証・構築 |
| AWS CLI v2 | AWSへ構築する場合の認証・アカウント確認 |

Swagger UIの閲覧と受信処理のテストには、AWSアカウント・認証情報は不要。

### 1. リポジトリを取得する

```bash
git clone https://github.com/takuto-san/point.git
cd point
```

以下のコマンドは、特記がない限りリポジトリのルートで実行する。

### 2. Swagger UIを起動する

```bash
docker compose up --build -d --wait
docker compose ps
```

[http://localhost:8080](http://localhost:8080) を開く。これはAPI仕様の閲覧用で、管理画面や受信API本体のローカル起動ではない。停止する場合は `docker compose down` を実行する。ポートが重複する場合は `SWAGGER_PORT=18080 docker compose up --build -d --wait` で変更できる。

### 3. 受信処理をテストする

```bash
node --version
node --test tests/*.test.mjs
```

テストはNode.js標準機能で実行できるため、`npm install` は不要。

### 4. Terraformを設定・検証する

初回のみ設定例をコピーし、`terraform/terraform.tfvars` を編集する。既存の設定ファイルがある場合はコピーを省略する。

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
```

| 設定項目 | 設定する値 |
|---|---|
| `management_aws_profile` | 管理アカウント用AWSプロファイル名。例：`management-dev` |
| `management_account_id` | 管理アカウントの12桁ID |
| `l3_account_id` | 結果送信を許可するL3アカウントの12桁ID |
| `aws_region` | 使用するリージョン。初期値：`ap-northeast-1` |

設定例のアカウントIDは仮の値なので、AWSへ接続する前に実環境の値へ置き換える。`init` はプロバイダ取得のためネット接続が必要だが、`validate` までの手順にAWS認証情報は不要。`terraform.tfvars` とstateはGit管理対象外。

### 5. AWSへ接続・構築する場合

組織の認証手順に従って管理アカウント用プロファイルを用意し、`management_aws_profile` と同じ名前で認証する。例の `management-dev` は実際の名前に置き換える。

```bash
aws sts get-caller-identity --profile management-dev
terraform -chdir=terraform plan -var-file=terraform.tfvars
```

表示されたアカウントIDと `management_account_id` が一致することを確認する。AWSリソースを構築する場合は、planの内容を確認してから実行する。

```bash
terraform -chdir=terraform apply -var-file=terraform.tfvars
terraform -chdir=terraform output -raw management_event_bus_arn
```

出力したARNをpoint-l3の `management_event_bus_arn` へ設定する。構築順序は **point（管理側）→ point-l3（L3側）**。受信処理・適用の詳細は [terraform/README.md](terraform/README.md) を参照。

## システム概要

「管理システム」チャットでCodexのdiagram-designを使って作成した、全体構成と画面仕様の図。完成時の業務・画面仕様を示しており、現在の実装範囲は下の「実装状況」を参照。

![解約金還元申請システムの全体構成と画面仕様](docs/point-award-system-overview-with-screens.png)

[SVG版](docs/point-award-system-overview-with-screens.svg) ／ [編集用HTML](docs/point-award-system-overview-with-screens.html)

既存図を内容変更せず掲載している。図中のTextractは当初の検討案で、現在のOCR/AIサービスは未選定。図の矢印・破線は元の凡例に従い、実装済み／未実装の区分は下の表を参照。

本人確認とポイント付与判定は別々に実行し、それぞれの結果を順次管理側へ反映する。AIの判定出力は「結果・理由」のみ。担当者は詳細画面で内容を修正して「確定」する。管理側へ渡す比較情報は持出許可済みのマスク情報に限り、証跡原本はformrunで確認する。

| 業務イベント | マイページの表示 |
|---|---|
| formrunで申請受付 | 受付済み |
| 申請管理システムへの取込 | 審査中 |
| メール配信完了を連携 | 結果 |

メール送信可能になった時点ではなく、配信完了後に結果を公開する。画面名は「マイページ」で統一し、ポイント実付与はこの全体像に含めない。

## AWS構成図

管理側TerraformのplanからTerravisionで生成した構成図。仮のアカウントIDを使った設計図で、AWSへ適用済みの環境を示すものではない。

![Terravisionで生成した管理アカウントのAWS構成図](docs/architecture-aws.dot.png)

[SVG版](docs/architecture-aws.dot.svg)

Terraformに定義されたリソースと依存関係を表示する。業務処理の全体像は上のシステム概要を参照。再生成はリポジトリルートで `bash tools/diagram.sh` を実行する。

CloudFront/S3とCognitoは画面配信・認証の基盤のみで、管理画面コードや社内IdP連携は未実装。現在の受信APIはIAM認可を使用する。LambdaはVPCに接続しない最小サーバーレス構成で、VPC・サブネット・NATは作成しない。

## ディレクトリ構成

```text
point/
├── README.md
├── Dockerfile                         # Swagger UI
├── docker-compose.yml                 # localhost:8080
├── .dockerignore
├── .gitignore
├── openapi/
│   └── l3-management.openapi.yaml      # 管理側受信API・共通データ契約の正本
├── terraform/
│   ├── versions.tf                    # Terraform・プロバイダのバージョン
│   ├── providers.tf                   # 管理アカウントへの接続
│   ├── variables.tf                   # 入力変数
│   ├── locals.tf                      # 共通名・タグ
│   ├── management.tf                  # EventBridge・SQS・DB・画面配信・認証基盤
│   ├── api.tf                         # IAM認可の受信・受信票API
│   ├── lambda.tf                      # 受信Lambda・IAM・イベントソース
│   ├── outputs.tf                     # API URL・EventBridge ARN等
│   ├── terraform.tfvars.example        # 設定例
│   ├── .terraform.lock.hcl             # プロバイダの固定
│   ├── .gitignore                      # ローカル設定・生成物を除外
│   ├── README.md                       # 適用・受信処理の詳細
│   └── lambda/
│       ├── index.mjs                  # HTTP / SQSのエントリポイント
│       ├── schema.mjs                 # OpenAPIスキーマ検証・正規化
│       └── store.mjs                  # 版管理・受信票・トランザクション
├── tests/
│   └── receiver.test.mjs              # 再送・競合・確定後保留のテスト
├── tools/
│   ├── diagram.sh                     # Terravision構成図の再生成
│   └── diagram-providers.tf.txt        # 図生成専用の仮プロバイダ設定
└── docs/
    ├── architecture-aws.dot.png
    ├── architecture-aws.dot.svg
    ├── point-award-system-overview-with-screens.png
    ├── point-award-system-overview-with-screens.svg
    └── point-award-system-overview-with-screens.html
```

生成物・ローカル設定の `.terraform/`、state、zip、`terraform.tfvars` はGit管理対象外。

## 実装状況

| 項目 | 現在の状態 |
|---|---|
| EventBridge → SQS → Lambda → DynamoDB | 定義・受信コードあり |
| 受信APIのPUT / 受信票照会GET | 定義・受信コードあり。IAM認可 |
| 同一revisionの再送・競合、旧版、確定後の保留 | 共通保存処理とテストあり |
| CloudFront・非公開S3・Cognito | Terraform定義あり。画面・認証連携は未実装 |
| 一覧・詳細画面、結果・理由の編集、「確定」API | 未実装 |
| メールリスト、配信完了受付、マイページ連携 | 未実装 |
| formrun Webhook、OCR、AI判定、持出審査・送信 | point-l3側の担当範囲。未実装 |

計画している管理画面は「申請一覧」「申請詳細」の2画面。一覧は `申請ID → NIFTY ID → 受付日 → 本人確認 → 審査 → 通知 → 不備理由 → 解約金 → 詳細` の順に表示する。詳細はマスク済みの回線契約情報と証跡抽出情報を並べ、その下に「formrunで開く」、編集可能な「判定結果（結果・理由）」と「確定」を置く。独立した最終判定欄やメモ欄は追加しない。

## L3との接続

1. 管理側の `terraform/terraform.tfvars.example` を元に実環境設定を用意し、管理インフラを適用する。
2. 出力 `management_event_bus_arn` を取得し、point-l3の同名変数へ設定する。
3. 両リポジトリの `l3_account_id` を同じL3アカウントIDに揃える。

```bash
terraform -chdir=terraform output -raw management_event_bus_arn
```

通常の結果連携はEventBridge。イベントの `source` は `jp.co.nifty.point-award.l3`、`detail-type` は `AnalysisSnapshot.v1`、`detail` はOpenAPIの `AnalysisSnapshot` とする。HTTPSのPUT/GETは管理アカウント内の照会・検証用で、L3からの直接クロスアカウントHTTPS呼び出し権限は付与していない。

OpenAPIの正本は [openapi/l3-management.openapi.yaml](openapi/l3-management.openapi.yaml)。point-l3のコピーは契約更新時に同じ内容へ更新する。両側のTerraform stateは独立して管理する。

## AWS構成図の再生成

```bash
bash tools/diagram.sh
```

TerraformとDockerが必要。図生成専用の一時コピーと仮のアカウントIDでplanを作成し、TerravisionでPNG/SVGを生成する。AWS API・実stateを参照せず、AWSへの適用も行わない。
