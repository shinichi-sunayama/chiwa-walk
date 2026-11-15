# アプリアイコン（Gemini で描く）

## 手順
1. Gemini（画像を作れるモデル）を開き、見本の絵を添付してから、下の「おねがいの文」を貼る。
   - 見本の絵：`assets/dogs/ohagi.png`（おはぎ）
2. 何枚か作ってもらい、気に入った1枚を **`docs/art/icon/app_icon_gemini.png`**（jpg でも可）という名前で保存する。
   - 正方形でなくても大丈夫（Claude が真ん中を正方形に切り取ります）。1024×1024 以上が理想。
3. Claude に「アイコンを差し替えて」と頼む。次の組み立てから自動でその絵が使われる（仮のアイコンより優先）。
4. 使った絵のことを `docs/asset-licenses.md` に書く（Claude が書きます）。

## 気をつけること
- 何のアプリかがひと目で分かること：主役は「おさんぽ中のおはぎ」と「記録（手帳）」。
- 文字・数字は入れない（小さいと読めない）。
- 角は丸めない（iPhone が自動で丸める）。ふちに大事なものを置かない（Watch では丸く切られる）。
- うんちの絵は入れない（ホーム画面に並べたときの印象のため）。足あとや手帳で表す。
- 他の作品のキャラ・ロゴ・画風の名前（「〇〇風」）を文に入れない。
- アプリの色に合わせる：空色〜クリーム色、オレンジ、やわらかい緑。

## おねがいの文（日本語）
```
スマホアプリのアイコンを1枚描いてください。犬の散歩中に、おしっこやうんちを記録するアプリです。
・正方形、文字や数字はなし、角は丸めない、背景まで塗りつぶす（透明なし）
・主役は添付の犬（白・黒・茶の3色で毛の長いチワワ）。赤いリードをつけて、うれしそうに前を向いておさんぽしている。体の大きさは画面の半分くらい
・犬のうしろに、小さな手帳（クリーム色の表紙、オレンジのしおり、ページに肉球のスタンプ）が少しななめに置いてある
・足もとに小さな肉球の足あとが点々と続いている
・背景はやわらかい空色からクリーム色へのグラデーション、下のほうに明るい緑の芝生を少しだけ
・やわらかい塗り、太めのふち線、明るくはっきりした色、やさしい雰囲気。小さく表示しても犬と手帳がわかる形
・ふちの近くには大事なものを置かない（丸く切り取られても犬の顔が残るように、犬は真ん中寄り）
```

## Prompt (English)
```
Please draw one app icon for a smartphone app that logs a dog's pee and poop during walks.
- Square, no text or numbers, no rounded corners, fully painted background (no transparency)
- Main subject: the attached dog (a long-haired white, black and tan chihuahua) on a red leash, happily walking and facing forward. The dog fills about half of the image
- Behind the dog, a small notebook (cream cover, orange bookmark ribbon, a paw-print stamp on the page) placed at a slight angle
- A trail of small paw prints near the dog's feet
- Background: a soft gradient from sky blue to cream, with a little bright green grass near the bottom
- Soft shading, thick outlines, bright clear colors, a gentle mood; the dog and the notebook should still be recognizable when tiny
- Keep important things away from the edges (the dog's face near the center, so it survives a circular crop)
```
