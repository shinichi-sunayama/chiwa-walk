# iPhone＋Apple Watch 版を TestFlight で試す（Mac なし）

Mac がなくても、GitHub のクラウドの Mac で組み立て・署名し、TestFlight に上げられます。
このリポジトリは公開なので、クラウドの Mac は無料で使えます（チワちくの月 200 分の枠は減りません）。

## 段階
| 段階 | 内容 | だれが | 状態 |
|---|---|---|---|
| 1 | Swift のアプリを書く（`apple/`） | Claude | 試作1 |
| 2 | バンドル ID を 2 つ登録し、App Store Connect にアプリを作る | ユーザー | |
| 3 | このリポジトリの GitHub の Secrets に鍵を 4 つ入れる | ユーザー | |
| 4 | クラウドで組み立て・署名して App Store Connect に上げる | Claude | |
| 5 | TestFlight で iPhone と Watch に入れ、散歩で試す | ユーザー | |

iCloud（自分の iCloud での同期・家族共有）は試作2から。そのときに iCloud の設定の手順を足します（今は不要）。

## 2. バンドル ID を登録して、アプリを作る（ユーザー）

### 2-1. バンドル ID（アプリの名札）を 2 つ登録
1. https://developer.apple.com/account/resources/identifiers/list を開く
2. 「＋」→「App IDs」→「Continue」→「App」→「Continue」
3. 説明（Description）`Osanpo`、Bundle ID は「Explicit」で **`com.ohagikinakokobo.osanpo`** →「Continue」→「Register」
4. もう一度 2. から。説明 `Osanpo Watch`、Bundle ID **`com.ohagikinakokobo.osanpo.watchkitapp`**
   - 機能（Capabilities）のチェックは、今はどちらも何も付けなくてよい（iCloud は試作2で付けます）

### 2-2. App Store Connect にアプリを作る
1. https://appstoreconnect.apple.com/ →「アプリ」→ 左上の「＋」→「新規 App」
2. 次のように入れて「作成」
   - プラットフォーム：iOS
   - 名前：`おはぎのおさんぽ帳 - 犬のトイレ記録`
   - 主言語：日本語
   - バンドル ID：`com.ohagikinakokobo.osanpo`
   - SKU：`osanpo`
   - ユーザーアクセス：アクセス制限なし
3. ストアの文章や画像はまだ入れなくてよい（TestFlight で試すだけなら不要）
   - Watch アプリは iPhone アプリの中に入って一緒に届くので、Watch 用に別のアプリを作る必要はない
   - 名前が「使用済み」と出たら Claude に知らせる（別の案を出します）

## 3. GitHub に鍵を 4 つ入れる（ユーザー）
ピックルボールのアプリ（pickle-score）と**同じ値**です（チームの API キーなので、同じチームのどのアプリにも使える）。
1. https://github.com/shinichi-sunayama/chiwa-walk/settings/secrets/actions を開く
2. 「New repository secret」を押し、Name と Secret を入れて「Add secret」。これを 4 回
   | Name | Secret に入れるもの |
   |---|---|
   | `ASC_KEY_ID` | App Store Connect の API キーの「キー ID」 |
   | `ASC_ISSUER_ID` | 同じ画面の上にある「Issuer ID」 |
   | `ASC_KEY_P8` | キーのファイル `AuthKey_<キーID>.p8` をメモ帳で開いた中身ぜんぶ（`-----BEGIN PRIVATE KEY-----` から `-----END PRIVATE KEY-----` まで） |
   | `APPLE_TEAM_ID` | Apple Developer のチーム ID（10 文字） |
   - キー ID と Issuer ID は https://appstoreconnect.apple.com/access/integrations/api で見られる
   - 鍵は Claude に送らない。GitHub の画面にだけ入れる
   - 公開リポジトリでも Secrets の中身はほかの人には見えない（ほかの人からの変更依頼（プルリクエスト）の実行でも渡らない）

## 4. クラウドで作って上げる（Claude）
Actions の「Apple build」（`.github/workflows/apple.yml`）を手で起動します。
```
gh workflow run apple.yml -R shinichi-sunayama/chiwa-walk -f upload=true
```
- 鍵がないときは、署名なしで組み立てられるかだけを確かめる
- ビルド番号は Actions の実行番号を使うので、上げるたびに自動で増える
- 結果：https://github.com/shinichi-sunayama/chiwa-walk/actions/workflows/apple.yml

## 5. TestFlight で試す（ユーザー）
1. 上がってから数分〜数十分で、App Store Connect の「おはぎのおさんぽ帳」→「TestFlight」にビルドが出る（「処理中」が消えるまで待つ）
2. 左の「内部テスト」の「＋」でグループを作り（名前は何でもよい）、自分をテスターに入れて、ビルドを追加
3. iPhone の「TestFlight」アプリ →「おはぎのおさんぽ帳」→「インストール」
4. Apple Watch には、iPhone の「Watch」アプリ →「マイウォッチ」→ 下のほうの「おさんぽ帳」→「インストール」（自動で入ることもある）

### 試してほしいこと（試作1）
- iPhone で犬を登録（2匹以上だと「まとめて記録」も試せる）→ Watch を開くと犬が出るか
- Watch でボタンを押す → 手首の振動で分かるか。「とりけす」が押しやすいか
- iPhone を家に置いて散歩し、Watch だけで記録 → 帰ってから iPhone に届いているか
- Watch の2ページ目（下にスクロール）の「うんち ○時間前」
- iPhone の「きろく」で時刻の直し・消し・あとから追加、「せってい」の一覧を送る
