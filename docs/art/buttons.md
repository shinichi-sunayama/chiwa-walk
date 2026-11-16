# 記録ボタンの絵（Gemini で描く）

ボタンの絵文字（💦💩💧🍽️）を、工房のやさしいイラストに差し替えます。絵がない種類は、これまでどおり絵文字が出ます。

## 手順
1. Gemini（画像を作れるモデル）で、下の「おねがいの文」を使って **4枚** 描いてもらう（1枚ずつ。下の4つの「描くもの」を順に入れかえる）。
   - 絵柄をそろえるため、最初に気に入った1枚を、2枚目からは「この絵と同じ描き方で」と添付するとよい。
2. 気に入ったものを、次の名前で `assets/kinds/` に保存する（png でも jpg でも可。Claude が png にそろえます）。
   | ボタン | ファイル名 |
   |---|---|
   | おしっこ | `pee.png` |
   | うんち | `poop.png` |
   | おみず | `water.png` |
   | ごはん | `food.png` |
3. Claude に「ボタンの絵を入れて」と頼む（背景の透明化・大きさの調整・ライセンスの記録をします）。

## 気をつけること
- ボタンは小さい（Watch では 1cm ほど）。**形がひと目でわかる、太いふち線のシンプルな絵**にする。文字は入れない。
- ボタンの色（おしっこ＝黄、うんち＝茶、おみず＝青、ごはん＝オレンジ）の上に乗るので、**背景は白一色**で描いてもらい、Claude が白を抜く。
- うんちは、ソフトクリーム型の「かわいい記号」にとどめ、リアルにしない。顔を描かない（食べ物に見えないように）。
- ごはんは**ドッグフードのお皿**（カリカリが入った犬用の器）。人の食べ物や、犬に有害な食べ物（ぶどう・チョコ・ねぎ類など）は描かない。
- 他の作品のキャラ・ロゴ・画風の名前（「〇〇風」）を文に入れない。

## おねがいの文（日本語）
```
スマホアプリのボタンに使う、小さなアイコンの絵を1つ描いてください。
・描くもの：［ここを入れかえる］
・真っ白な背景、正方形、文字なし、影なし
・太めのこげ茶のふち線、やわらかい塗り、明るくやさしい色、まるっこい形
・とても小さく表示しても形がわかる、シンプルな絵。細かい模様は入れない
・絵は真ん中に、まわりに少し余白
```
「描くもの」の4つ：
1. おしっこ：黄色い、丸いしずくが3つ（大・中・小）
2. うんち：茶色の、ソフトクリームのような3段のうずまきの形（かわいい記号として。顔はなし）
3. おみず：水色の水が入った、犬用の丸い水入れのお皿（側面に小さな肉球マーク）
4. ごはん：カリカリのドッグフードが山盛りの、オレンジ色の犬用のお皿（側面に小さな骨のマーク）

## Prompt (English)
```
Please draw one small icon for a button in a smartphone app.
- Subject: [replace this]
- Plain white background, square, no text, no shadow
- Thick dark-brown outlines, soft shading, bright gentle colors, rounded shapes
- Very simple, readable even when tiny; no fine details
- Centered with a little margin
```
Subjects:
1. Pee: three round yellow droplets (large, medium, small)
2. Poop: a brown three-tier swirl shaped like soft-serve ice cream (a cute symbol, no face)
3. Water: a round dog water bowl filled with light-blue water (small paw mark on the side)
4. Food: an orange dog bowl heaped with dry kibble (small bone mark on the side)
