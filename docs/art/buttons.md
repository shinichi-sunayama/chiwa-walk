# 記録ボタンの絵（Gemini で描く）

> **2026-11-17 改訂（試用の感想から）**：うんち・おしっこそのものの絵はリアルすぎ、手首で人目に触れるのも気になる、とのこと。
> そこで **おはぎが主役の「場面」の絵** に変えます（うんちそのもの・しずくそのものは描かない）。
> Watch のボタンは絵だけ（文字なし）、iPhone は絵の下に小さく文字。文字盤と一覧の印は 💩 をやめて ●（茶）・しずく に。

> **絵柄の基準（2026-11-17 決定）**：うんちの絵 `C:\Users\sunay\Claude\chiwa-walk\docs\art\buttons\poop_gemini.jpg`（太く均一なこげ茶の線・平たい塗り・目を細めた笑顔）。
> ほかの3枚は、この絵を添付して「この絵と同じ描き方で」と頼む。立体的な塗りや細かい毛の線の絵（1回目のおしっこ）は不採用。

## 手順
1. Gemini（画像を作れるモデル）に、見本の絵 **`C:\Users\sunay\Claude\chiwa-walk\docs\art\icon\reference_ohagi.png`** を添付して、下の「おねがいの文」を貼る。「場面」を4つ順に入れかえて、1枚ずつ。
   - 2枚目からは、気に入った1枚目も添付して「この絵と同じ描き方で」と添える。
   - 保存は Gemini のダウンロードボタンで（スクリーンショットは不可）。
2. 気に入ったものを、次の名前で `C:\Users\sunay\Claude\chiwa-walk\assets\kinds\` に保存する（png でも jpg でも可。いまある同じ名前のファイルは上書きでOK。pee.svg は Claude が消します）。
   | ボタン | ファイル名 |
   |---|---|
   | おしっこ | `pee.png` |
   | うんち | `poop.png` |
   | おみず | `water.png` |
   | ごはん | `food.png` |
3. Claude に「ボタンの絵を入れて」と頼む（背景の透明化・大きさの調整・ライセンスの記録をします）。

## 気をつけること
- ボタンは小さい（Watch では 1.3cm ほどの白い丸の中）。**おはぎの顔と小物を大きく**、全身や背景は描かない。
- うんち・おしっこそのものは描かない。**何の場面かは、小物（電柱・マナー袋）とボタンの色（黄・茶）で伝える**。
- 犬を大切に：つらそう・恥ずかしそうな表情にしない。いつもうれしそうに。
- ごはんは**ドッグフード**だけ。人の食べ物や、犬に有害な食べ物（ぶどう・チョコ・ねぎ類など）は描かない。
- 他の作品のキャラ・ロゴ・画風の名前（「〇〇風」）を文に入れない。

## おねがいの文（日本語）
```
スマホアプリのボタンに使う、小さなアイコンの絵を1つ描いてください。
・主役は添付の犬（白・黒・茶の3色で毛の長いチワワ）。顔が大きめの、かわいくデフォルメした姿で、うれしそうな表情
・場面：［ここを入れかえる］
・真っ白な背景、正方形、文字なし、影なし、背景の景色は描かない
・なめらかで均一な太さのこげ茶のふち線、やわらかい塗り、明るくやさしい色、まるっこい形
・とても小さく表示しても犬の顔と小物がわかる、シンプルな絵。細かい毛の線は入れない
・犬と小物をまとめて真ん中に、まわりに少し余白
```
「場面」の4つ：
1. おしっこ：小さな黄色い電柱（または小さな木）のにおいを、くんくん嗅いでいる横顔。電柱の根元に小さな草が少し。しずくや水たまりは描かない
2. うんち：すっきりした満足顔でおすわり。まわりに小さなキラキラ。横の地面に、小さなスコップと、口をむすんだ茶色のマナー袋（中身は見えない、肉球マーク）が置いてある。犬は袋にさわらない
3. おみず：水色の水が入った犬用の丸いお皿から、ぺろぺろ水を飲んでいる
4. ごはん：オレンジ色の犬用のお皿（カリカリのドッグフード入り）の前で、目をきらきらさせておすわり

## Prompt (English)
```
Please draw one small icon for a button in a smartphone app.
- The main character is the attached dog (a long-haired white, black and tan chihuahua), drawn cute and chibi with a large head, looking happy
- Scene: [replace this]
- Plain white background, square, no text, no shadow, no scenery behind
- Smooth, even-width dark-brown outlines, soft shading, bright gentle colors, rounded shapes
- Very simple, the dog's face and the prop must read even when tiny; no fine fur strokes
- Dog and prop grouped in the center with a little margin
```
Scenes:
1. Pee: sniffing a small yellow utility pole (or a small tree), side view. A little grass at its base. No droplets or puddles
2. Poop: sitting with a relieved, satisfied smile, a few small sparkles around. On the ground beside it, a small scoop and a tied brown waste bag (contents not visible, tiny paw mark). The dog does not touch the bag
3. Water: lapping water from a round dog bowl of light-blue water
4. Food: sitting with sparkling eyes in front of an orange dog bowl of dry kibble
