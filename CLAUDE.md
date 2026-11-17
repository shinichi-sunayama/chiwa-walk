# chiwa-walk（おはぎのおさんぽ帳）— Claude 向けメモ

犬の散歩中に、おしっこ・うんち・おみず・ごはん・散歩のはじまり／おわりを Apple Watch や iPhone からワンタップで記録するアプリ。
おはぎきなこ工房の**公式アプリ**（売上よりブランドとファンづくり。チワちくシリーズの「付録」）。

- App Store の名前「おはぎのおさんぽ帳 - 犬のトイレ記録」、ホーム画面「おさんぽ帳」。
- 仕様書・タスク：Notion「ゲーム自動化用」の [おはぎのおさんぽ帳 プロジェクト](https://app.notion.com/p/419ab0ad1d308161801cda3c1ba15cb1)。決めたことは `docs/decisions.md`。

## ユーザーについて
- 個人開発者（屋号：おはぎきなこ工房）。返答はすべて日本語、専門用語は短い説明つき。コード・コミットは英語でよい。
- 予算 $0。このリポジトリは**公開**（GitHub の macOS ランナーが無料）。公開してよい素材だけ入れる。秘密の値は GitHub の Secrets だけ。
- ユーザーに頼むのは実機での試用と判断（課金・ストア申請・公開・アカウント操作）だけ。手順と入力内容は Claude が用意する。

## 構成
- `apple/WalkCore/` … 画面のない計算（記録の作成、前回からの時間、きょうの回数、散歩中か、Watch とのやりとりの形式、CSV・一覧の文章）。Linux で `swift test`（`.github/workflows/ci.yml`）。**ロジックはまずここに書き、テストを足す。**
- `apple/iOS/` … iPhone。`Persistence.swift`（Core Data、モデルはコードで定義、iCloud 用の作法に従う）、`AppModel.swift`（状態）、`PhoneSync.swift`（Watch との連携）、画面（Today / History / Settings）。
- `apple/Watch/` … Watch。`WatchStore.swift`（Watch に先に保存 → transferUserInfo で iPhone へ。iPhone からは applicationContext で犬と最近の記録）、`WatchViews.swift`。
- `apple/Shared/` … 色・フォント・振動・犬の顔（写真対応）・ボタンの絵（KindIcon、白い丸の上）・プライバシー申告。
- `apple/Complication/` … Watch の文字盤（WidgetKit 拡張）。Watch アプリが App Group `group.com.ohagikinakokobo.osanpo` に書いた `ComplicationData` を読むだけ。
- `apple/project.yml` … XcodeGen（Xcode プロジェクトは生成物、git に入れない）。バンドル ID `com.ohagikinakokobo.osanpo`／`.watchkitapp`／`.watchkitapp.widget`。iCloud Container は `iCloud.com.ohagikinakokobo.osanpo`（試作2で使う）。
- `site/` … プライバシーポリシー・サポート（GitHub Pages、ci.yml が公開）。https://shinichi-sunayama.github.io/chiwa-walk/
- `assets/dogs/` … 犬5匹の顔（chiwa-photo の描き出しから `tools/make_dog_faces.py`。条件は `docs/asset-licenses.md`）。`assets/kinds/` … ボタンの絵（Gemini。白背景は `tools/prepare_kind_art.py` で抜く。SVG はそのまま）。`assets/fonts/` … M PLUS Rounded 1c Bold（全文字。犬の名前に何でも使えるように減らしていない）。
- `tools/make_apple_assets.sh` … アイコンと犬の絵からアセットを作る（macOS）。アイコンは `docs/art/icon/app_icon_gemini.(png|jpg)`、なければ仮の `app_icon_placeholder.png`（`tools/make_placeholder_icon.py`）。
- `.github/workflows/apple.yml` … クラウドの Mac で組み立て。`gh workflow run apple.yml -f upload=true` で署名して TestFlight へ。手順は `docs/ios-testflight.md`。

## 守ること
- 健康について医療的な判断や助言をしない。「多い・少ない・異常」も出さない。事実（時刻・回数・経過時間）だけ。気になるときは動物病院へ、と案内する。
- 位置情報・地図・広告・解析・外部サーバーは使わない（写真は、犬のアイコンにユーザーが選んだ1枚だけ）。記録は端末とユーザー自身の iCloud の中だけ。
- 犬を大切に描く。犬に有害な食品を肯定的に描かない。
- Core Data のモデル（`Persistence.swift`）は、iCloud の本番に出したら**名前の変更・削除をしない**（足すだけ。足す項目は省略可にする）。
- 機能はすべて無料。100円の買い切りは「応援」（お礼は着せ替えだけ）。機能を後から有料にしない。
- このPC（Windows）には Swift がない。確かめはクラウド（Linux のテスト、macOS の組み立て）で行う。
- ユーザーにファイルの場所を伝えるときは、フルパス（`C:\Users\sunay\Claude\chiwa-walk\...`）で書く。
