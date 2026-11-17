# App Store 審査に出す手順（おはぎのおさんぽ帳 1.0.0）

pickle-score（おはぎのピックルボールコール）で通った手順に合わせています。

## 先に読む注意（ほかの作品で起きたこと）
- **ページごとに右上の「保存」を押す**。押さずに別のページへ行くと、入れた内容が消える。
- 説明文に「■」「★」「……」を使うと「無効な文字」ではじかれる。下の文はそれらを使っていない（【】と・だけ）。
- 初回は **Guideline 2.1「Information Needed（情報の追加依頼）」** が来ることが多い。不合格ではなく質問。下の「6」で返す。返したあと **「App Review に再提出」を押さないと止まったまま**。
- リリースは **手動**（審査が通っても自動で公開しない）。

## 1. アプリ情報（左の「一般」→「App 情報」）
日本語だけでよい（英語のページは作らない。アプリの画面が日本語だけのため）。
| 項目 | 入れるもの |
|---|---|
| 名前 | おはぎのおさんぽ帳 - 犬のトイレ記録 |
| サブタイトル（30文字まで） | 散歩のトイレをWatchでワンタップ |
| カテゴリ | プライマリ：ライフスタイル／セカンダリ：ユーティリティ |
| コンテンツ配信権 | 「はい、サードパーティのコンテンツを含み、使用する権利があります」（フォント M PLUS Rounded 1c） |
| 年齢制限指定 | 「編集」→ 質問はすべて「いいえ／なし」。「子ども向け（Made for Kids）」は「該当なし」→ 4+ |

## 2. 価格と配信状況
- 価格：**無料**（広告なし。応援の購入は今後のバージョンで追加）
- 配信地域：ほかの作品と同じく、**中国本土・EU 27か国・アイスランド・ノルウェー・ロシア・ベラルーシを外す**。Mac・Vision Pro で使えるようにするチェックは外す。
  - ヨーロッパ以外は見出しのチェックで地域ごとまとめて入れる → アジア太平洋の **「中国本土」だけ外す**
  - **ヨーロッパは次の 11 だけ**（見出しが「ヨーロッパ (11)」になれば正しい）：アルバニア、イギリス、ウクライナ、コソボ、スイス、セルビア、トルコ、ボスニア・ヘルツェゴビナ、モルドバ、モンテネグロ、北マケドニア

## 3. App のプライバシー（左の「App のプライバシー」）
- プライバシーポリシー URL：https://shinichi-sunayama.github.io/chiwa-walk/privacy.html
- 「データを収集していますか？」→ **いいえ** →「保存」→ 右上の **「公開」**
  - 記録は端末の中だけで、工房には届かないので「収集」にあたらない。

## 4. バージョン 1.0.0 のページ（左の「iOS App」）
バージョンの数字は **1.0.0**（ほかの作品とそろえる）。最初は「1.0」と出ていることがあるので、ページ上の「バージョン」欄を **1.0.0** に直して保存。アプリ側（ビルド）もすでに 1.0.0。

### プロモーション用テキスト（170文字まで）
```
散歩中のおしっこ・うんちを、Apple Watch からワンタップで記録。前回から何時間たったかが文字盤でわかります。多頭飼いでもまとめて記録できます。
```

### 説明（4000文字まで）
```
おはぎきなこ工房のチワワ「おはぎ」といっしょに、毎日の散歩のトイレを記録するアプリです。
リードを持ったまま、Apple Watch のボタンを1回押すだけ。iPhone を出さなくても記録できます。

【ワンタップで記録】
・おしっこ・うんちのボタンを押すだけ。手首の振動で記録できたことがわかります
・押しまちがえても、すぐに「とりけす」で消せます
・おみず・ごはんのボタンも、せっていで足せます
・散歩のはじまりとおわりも記録できます

【Apple Watch だけで完結】
・iPhone を家に置いて散歩しても、記録は Watch に保存され、あとで iPhone に届きます
・文字盤に「前回のうんちから何時間」を表示できます

【多頭飼いに】
・いっしょに散歩する犬を選べば、1回のタップでまとめて記録
・犬ごとに、前回からの時間と、きょうの回数を表示

【あとから見返す】
・日にちごとの記録を一覧で表示。時刻の直し・消し・追加ができます
・動物病院で見せやすい、日ごとの一覧や表（CSV）を送れます

【安心して使える】
・ログインなし、広告なし、機能はすべて無料
・記録はお使いの iPhone と Apple Watch の中だけに保存します。位置情報は使いません
・犬のアイコンは、工房の犬たちの絵か、ご自身で選んだ写真1枚

このアプリは記録のためのもので、健康の判断や助言はしません。気になることがあるときは、動物病院にご相談ください。

フォント：M PLUS Rounded 1c（SIL Open Font License 1.1）

おはぎきなこ工房
```

### キーワード（100文字まで、カンマのあとに空白を入れない）
```
いぬ,ドッグ,さんぽ,排泄,排せつ,おしっこ,うんち,ログ,日記,多頭飼い,チワワ,ペット,アップルウォッチ,ウォッチ,文字盤,子犬,老犬,シニア犬,おでかけ,トイレトレーニング
```
名前・サブタイトルにある言葉は検索の対象になるので、なるべく重ねない。ほかのアプリ名・商標は入れない。

### サポート URL・マーケティング URL
- サポート URL：https://shinichi-sunayama.github.io/chiwa-walk/support.html
- マーケティング URL：https://shinichi-sunayama.github.io/chiwa-walk/

### 著作権
```
2026 おはぎきなこ工房
```

### スクリーンショット
`C:\Users\sunay\Claude\chiwa-walk\docs\store\screenshots\` の画像を使う（クラウドのシミュレーターで、見本の犬と記録を入れて撮影。撮り直しは `gh workflow run screenshots.yml`）。
- **iPhone**：「6.3 インチ」の欄（pickle で受け付けられた大きさ）に `iphone\1_today.png` → `2_history.png` → `3_settings.png` の順。ほかの大きさの欄は空でよい。
- **Apple Watch**：Watch の欄に `watch\1_record.png` → `2_status.png`。
- PNG のアップロードが止まったら、軽い JPEG にしたものを使う。

### ビルド
「ビルド」の「＋」で、いちばん新しい **1.0.0** のビルドを選ぶ（手順を書いた時点では 15）。Watch アプリと文字盤は同じビルドの中に入っている。

### App Review に関する情報
- サインインが必要：**いいえ**
- 連絡先：名前（ローマ字）・電話番号（+81 から）・メールは、ご自身で入れる
- メモ（英語。保存後にもう一度、空になっていないか確認）：
```
Ohagi's Walk Log lets dog owners record their dog's pee and poop (and optionally water and food) during walks with one tap, mainly from Apple Watch.

No account or sign-in is needed. How to test:
1. On iPhone, tap "わんちゃんを とうろく" (add a dog), enter a name and choose a picture, then save.
2. On the "きょう" (Today) tab, tap the yellow button (pee) or the brown button (poop). The record appears in today's list; "とりけす" (Undo) removes it. Tap a dog to switch; long-press a dog or tap "みんな" (all) to record for several dogs at once.
3. The "きろく" (History) tab lists records by day; tap one to edit the time or delete it. "せってい" (Settings) can add water/food buttons and share a daily summary or CSV.
4. The Apple Watch app shows the same buttons (pictures only). Records made on the Watch are stored on the Watch and sent to the iPhone with WatchConnectivity. The watch face complication shows the time since the last poop.

Privacy: all data stays on the user's iPhone and Apple Watch. No server, account, ads, analytics, tracking or location. The optional dog photo is picked by the user with the system photo picker (one photo only).
The app records facts (times and counts) only and gives no health advice; it suggests consulting a veterinarian.
The dog pictures and icon are our own (drawn for our workshop). Font: M PLUS Rounded 1c (SIL Open Font License).

Answers we were asked for on earlier first submissions (Guideline 2.1), given in advance:
1. Purpose and audience: helps dog owners keep a simple log of their dog's toilet during walks. Anyone with a dog can use it.
2. External services: none (no server, ads, analytics, tracking or account).
3. Regional differences: none (Japanese interface, works the same everywhere).
4. Third-party material: M PLUS Rounded 1c font (SIL Open Font License). The dog pictures and icon are our own.
A screen recording from a physical iPhone, starting on the Home Screen, is attached.
```

### 添付ファイル（審査用の画面収録、最初から付ける）
ほかの作品は初回に毎回 2.1 で動画を求められたので、最初から付けて往復を減らす（必須ではない）。
1. 実機の iPhone で「画面収録」を始め、**ホーム画面から**「おさんぽ帳」を開く。犬の登録、おしっこ・うんちのボタン、「とりけす」、「きろく」で時刻を直す、「せってい」まで、30秒〜1分。
2. 動画を Claude に渡す → ホーム画面のぼかし・無音・30fps・高さ 1920 に加工する（chiwa-survivor の `tools/review-video.ps1` と同じ方法）。**加工前の動画はそのまま付けない**（壁紙・通知が映る）。
3. 「App Review に関する情報」の「添付ファイル」に加工した動画を付けて「保存」。

### バージョンのリリース
**「このバージョンを手動でリリースする」** を選ぶ。

## 5. 審査に出す
右上の「審査用に追加」→「審査へ提出」。入れ忘れがあると赤い文字で出るので、その項目を直して「保存」。

## 6. 2.1（Information Needed）が来たとき
返信（英語）と、App Review のメモに同じ文を入れる。動画がまだなら上の「添付ファイル」の方法で付ける。
```
Thank you for reviewing our app.

1. Purpose and audience: Ohagi's Walk Log helps dog owners keep a simple log of their dog's pee and poop during walks, with one tap from Apple Watch or iPhone. Anyone with a dog can use it.
2. How to use: add a dog on iPhone, then tap the yellow (pee) or brown (poop) button. Undo removes the last record. The History tab lists records by day and allows editing. The Apple Watch app has the same buttons and works without the iPhone nearby; records are sent to the iPhone later.
3. External services: none. The app does not use a server, ads, analytics, tracking or location, and has no account. All data stays on the user's devices.
4. Regional differences: none. The app works the same in every region (Japanese interface).
5. Third-party material: the font M PLUS Rounded 1c (SIL Open Font License). The dog pictures and the icon are our own.

A screen recording from a physical iPhone is attached.
```
返信したら **「App Review に再提出」** を押す。

## 7. 通ったら
「このバージョンをリリース」を押す。公開まで最大 24 時間ほど。
