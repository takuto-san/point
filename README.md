# 解約金還元申請管理システム — point

他社解約金還元申請の精査結果を受信し、担当者による確認・確定と顧客への結果通知を支える管理システム。精査工数を月約30時間削減し、7日以内に審査結果を通知することを業務目標とする。

設計の基準は「管理システム」チャットの最新の全体像・画面仕様。L3内の証跡解析・本人確認・ポイント付与判定は [point-l3](https://github.com/takuto-san/point-l3)、管理側の受信・保存・配信基盤はこのリポジトリで管理する。

## 環境セットアップ

### 必要なツール

| ツール | 用途 |
|---|---|
| Git | ソースの取得 |
| Docker / Docker Compose v2 | Swagger UI、受信処理のテスト、draw.io構成図の再生成。Docker Desktop等を起動しておく |
| Terraform 1.6以上 | AWS構成の初期化・検証・構築を行う場合のみ |
| AWS CLI v2 | AWSへ接続・構築する場合のみ |

Swagger UIの閲覧・受信処理のテスト・draw.io構成図の再生成に、ホスト側のNode.jsやPython、AWSアカウント・認証情報は不要。初回はDockerイメージの取得にネット接続が必要。

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
docker run --rm -v "$(pwd):/work:ro" -w /work node:22-alpine \
  node --test tests/*.test.mjs
```

テストはNode.js標準機能で実行できるため、`npm install` は不要。Node.jsはコンテナ内で実行する。

### 4. AWS構成を設定・検証する場合

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

システム概要図は既存図を内容変更せず掲載している。AWSサービスの配置は、下の共通AWS構成図でL3内のTextract・Bedrock・本人確認Lambdaとして具体化した。実装済み／未実装の区分は下の表を参照。

本人確認とポイント付与判定は別々に実行し、それぞれの結果を順次管理側へ反映する。AIの判定出力は「結果・理由」のみ。担当者は詳細画面で内容を修正して「確定」する。管理側へ渡す比較情報は持出許可済みのマスク情報に限り、証跡原本はformrunで確認する。

| 業務イベント | マイページの表示 |
|---|---|
| formrunで申請受付 | 受付済み |
| 申請管理システムへの取込 | 審査中 |
| メール配信完了を連携 | 結果 |

メール送信可能になった時点ではなく、配信完了後に結果を公開する。画面名は「マイページ」で統一し、ポイント実付与はこの全体像に含めない。

## AWS構成図

point / point-l3 の両リポジトリに、以下の同一画像を掲載する。既存の **L3アカウント** と管理システム用アカウントを、AWS Accountの枠で分離した全体設計図。

![L3アカウントと管理アカウントを分離した共通AWS構成図](docs/architecture-aws.png)

[draw.io編集用ファイル](docs/architecture-aws.drawio) ／ [draw.io出力SVG](docs/architecture-aws.svg) ／ [Terravision設計定義](docs/architecture.tvg.json)

編集用の `.drawio` はAWS4サービスアイコンを使用し、AWS Cloud、AWS Account、機能グループ、番号付きの主処理フローで構成する。[draw.ioのAWS構成図ガイド](https://www.drawio.com/docs/diagram-types/aws-diagrams/) と [AWS Reference Architecture Diagrams](https://docs.aws.amazon.com/reference-architecture-diagrams/) の表現を参考にしている。READMEの画像もこのdraw.ioファイルから出力している。

- **L3アカウント（既存）**：Webhook受付 → 受付Lambda → S3へ顧客・申請・証跡データを保存。保存後にStep Functionsで精査を開始し、Textract、本人確認Lambda、付与判定Lambda、Bedrock、持出ゲート・送信LambdaをL3内で利用する。
- **本人確認Lambda**：抽出した氏名とL3内の回線契約者情報を照合し、結果・理由を返す。回線契約情報の取得元・接続方式は詳細設計で確定する。Webhookを保存するS3を、照合用の正しい回線契約情報の取得元と同一視しない。
- **管理アカウント**：持出許可済み結果をEventBridge → SQS → 受信Lambda → DynamoDBへ保存する。CloudFront・画面配信用S3・Cognito・管理側APIもこのアカウントに置く。

L3の顧客情報・証跡原本・OCR全文は管理アカウントへ送らず、ゲートで許可した識別子・マスク情報・判定・理由・金額だけを連携する。

この図は実装済みと追加予定の構成を含む**設計図**で、Terraform planや実環境のスキャン結果ではない。既存のL3アカウントを新規作成するものではなく、アカウント枠はデータ処理・権限の境界を表す。現在のL3用Terraformは送信用IAMのみで、Webhook受付・保存・解析・本人確認のコードやリソース定義は別途実装する。

Textractは図のとおりL3内で利用する想定。ただし、[AWS公式の対応言語](https://docs.aws.amazon.com/textract/latest/dg/limits-document.html) に日本語は含まれないため、日本語証跡のOCRは補完・代替方式を含めて検証が必要。Bedrockのモデル・判定ルールも詳細設計で確定する。

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
│   ├── diagram.sh                     # 共通AWS設計図の再生成（両リポジトリ共通）
│   ├── diagram-drawio.py              # 編集可能なdraw.io図を生成
│   ├── diagram-preview.sh             # TerravisionのPNG/SVGプレビューを生成
│   ├── diagram-terraform.sh           # このリポジトリのTerraformだけを図示
│   ├── diagram-providers.tf.txt        # Terraform図用の仮プロバイダ設定
│   ├── terravision.Dockerfile          # 日本語フォント対応の描画環境
│   └── terravision-services.pth        # Textract/Bedrockの公式サービスアイコン名
└── docs/
    ├── architecture.tvg.json           # 両アカウントの共通設計図
    ├── architecture-aws.drawio          # AWS4アイコンで編集可能な共通図
    ├── architecture-aws.png             # draw.ioから出力したREADME表示用画像
    ├── architecture-aws.svg             # draw.ioから出力したSVG
    ├── terravision.yml                 # 日本語ラベル・連携ラベル
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

Dockerのみ必要。コンテナ内のPythonで共通の `docs/architecture.tvg.json` を読み込み、AWS4アイコンを使った編集可能な `docs/architecture-aws.drawio` を生成する。READMEの構成図は、このdraw.ioファイルから出力したPNGである。ホストにPythonをインストールする必要はない。Textract/Bedrockはサービス利用を示す図用の型で、Terraformリソースの作成を意味しない。

両リポジトリの設計定義・生成スクリプト・draw.ioファイルを同一に保つ。`.drawio` は [diagrams.net](https://app.diagrams.net/) の「ファイルを開く」から編集できる。

READMEに表示するPNG/SVGプレビューを再生成する場合は、Dockerを起動して `bash tools/diagram-preview.sh` を実行する。Terravision 0.55.0を使うため、プレビューの配置はdraw.io編集画面と異なる。両リポジトリの画像を同一に保つときは一方で生成してコピーする。描画日時が画像に入るため、個別生成ではバイト単位で一致しない。

このリポジトリのTerraformだけを図示する場合は `bash tools/diagram-terraform.sh` を使う（Terraformも必要）。出力名は `terraform-architecture-aws.dot.png` / `.svg` で、READMEの共通図を上書きしない。いずれの図生成手順もAWSの作成・変更は行わない。
