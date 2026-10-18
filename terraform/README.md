# AWS構成

このTerraformは管理アカウントのみを操作する。L3アカウントの送信用IAMロールは別リポジトリ `takuto-san/point-l3` のTerraformへ移設した。OCR、formrun、メール基盤、マイページは既存・別実装。

管理側の通常経路は `EventBridge → SQS（DLQ付き）→ 受信Lambda → DynamoDB`。API GatewayのIAM認可PUT/GETも同じLambdaを利用し、受信票を照会できる。HTTPS経路は管理アカウント内のIAM呼び出しを対象とする。L3からの直接クロスアカウントHTTPS呼び出し権限は付与しない。

管理画面の配信基盤はCloudFront＋非公開S3、認証基盤はCognito。画面コード、社内IdP連携、担当者の修正・確定API、通知・公開処理は未実装。配信基盤だけで管理画面が完成するわけではない。

## 適用

`terraform.tfvars.example` を `terraform.tfvars` としてコピーし、アカウントID・AWSプロファイルを実環境の値に変更する。

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -var-file=terraform.tfvars
```

プロバイダは `allowed_account_ids` で管理アカウントへの適用を検証する。L3の認証情報は不要。`l3_account_id` は受信を許可する送信元IDなので、point-l3の適用先と一致させる。生成した `.terraform.lock.hcl` はバージョン管理する。

管理側を先に適用し、`terraform output -raw management_event_bus_arn` をpoint-l3の同名変数へ設定する。各リポジトリのstateは独立し、互いのstateやファイルを直接参照しない。

既存環境で旧構成を適用済みの場合は、`aws_iam_role.l3_export` と `aws_iam_role_policy.l3_export` のstateをL3用stateへ移管してから両方のplanを確認する。ソースの削除だけで旧stateに対してapplyするとL3側リソースの削除になるため、そのまま適用しない。

## 受信処理

OpenAPIをzip作成時に同梱し、許可項目・型・必須項目を共通検証する。JSONのキー順を正規化して同一revisionの再送を判定し、DynamoDBトランザクションで受信票と最新状態を同時保存する。

- 同一版・同一内容：初回の受信票を返す。
- 同一版・異なる内容：409。SQSでは再試行後DLQへ退避する。
- 古い版：履歴を保存し、適用済みの状態は保持する。
- 確定後の新版：`HELD_AFTER_CONFIRMATION` で保留する。

将来の確定APIはLATEST項目のJSON `data` 内に `confirmed: true` を保存し、条件付き更新でトップレベル `version` を増やすこと。`snapshot` は最新受信値、`appliedSnapshot` は適用値、`receipt` は受付時点の不変記録。

スキーマの検証は自由文の個人情報混入やマスクの安全性までは判定しない。持出審査はL3のゲートで実装する。本受信処理には422を返す意味検査はまだなく、OpenAPIには将来の契約として残している。

## 構成図

READMEのAWS構成図はL3・管理アカウントを合わせた共通設計図。`bash tools/diagram.sh` でTerravisionの設計定義（`docs/architecture.tvg.json`）から生成し、追加予定のL3リソースも表示する。この管理側Terraformにそれらのリソースが追加されたわけではない。

このTerraformのplanから管理アカウントの定義だけを確認する場合は、プロジェクトルートで `bash tools/diagram-terraform.sh` を実行する。仮プロファイルの一時コピーを使い、`docs/terraform-architecture-aws.dot.png` / `.svg` を出力する。実インフラ・state・README用の共通図は変更しない。
