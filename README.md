# my-tools
自分用の小さなツール集

## bbhd

- "busybox httpd"を用いて指定したディレクトリをホスティングするwebサーバー

## bbud

- パイプで受け取った標準出力をurlデコード,改行付きで出力

- オプション

	- -a

        - 改行無しで出力

## bbhe

- パイプで受け取った標準出力をhtmlエンコード,改行付きで出力

- オプション

	- -a

        - 改行無しで出力

## bd2p

- "GNU barcode"と"imagemagic"を使いjanコードを生成

## c2h

- 特定の文字列で区切られたテキストファイルをhtmlのtableに変換

- デフォルトの区切り文字はカンマ

- オプション

    - -v fs="field separator"

        - "field separator"で指定された文字を区切り文字として処理

## c2x

- 特定の文字列(デフォルトではカンマ)で区切られたテキストファイルをxmlに変換

- デフォルトの区切り文字はカンマ

- オプション

    - -v fs="field separator"

        - "field separator"で指定された文字を区切り文字として処理

## c2mdt

- 特定の文字列(デフォルトではカンマ)で区切られたテキストファイルをmarkdownのtableに変換

- デフォルトの区切り文字はカンマ

- オプション

    - -v fs="field separator"

        - "field separator"で指定された文字を区切り文字として処理

    - -v p="right|center|left"

        - 指定された方向に表内の文字列を寄せる 

        - 指定がない場合は左寄せ

## srf

- 特定の文字で区切られたテキストの行列を入れ替える

- オプション

    - -v fs="field separator"

        - "field separator"で指定された文字を区切り文字として処理

## cpugv

- cpuガバナーの調整

## fpr

- ファイル内の文字列を非対話的に置換

## sands,sandv

- 自分のデスクトップPCの設定用コマンド

## tbug

- "/tmp/"ディレクトリにパイプの途中経過を保存

- オプション

	- -q

        - 出力を抑制

## hapi

- パイプで渡されたURLにwget,curl,w3mのいずれかでアクセス

## tmuxset

- tmuxのセッションの有無を確認し新規セッションのセットアップなどを行う

## dmenu_desktop

- デスクトップエントリをdmenuで表示

## dmenu_wmctrl

- dmenuを用いたウィンドウスイッチャー

## z2h

- 全角英数,スペースを半角に置換

## pws

- パイプで受け取った内容でwebサーバーを立てる

## dwh

- サーバーの死活確認,webhookでPOSTを送信

- オプション

	- -t

        - 疎通時にPOSTを送信

	- -f

        - 疎通失敗時にPOSTを送信

## mdwc

- markdownの文章の文字数のみをカウント

## fgcc

- C言語の即席コンパイル用

## songinfo

- mpdで再生中の曲及びカバーアートを通知

## clipper

- abcdeによりcli上でCDリッピング

## csvhs

- ヘッダから引数にマッチする列を抽出

## musiconv

- 複数の音声ファイルを一括変換

## xc2c

- Excel専用のcsvを通常のcsvに変換

## comlaunch

- fzfを使用したコマンドランチャー

## chitubox

- chituboxを起動するラッパー

## chromium-browser

- ungoogled-chromiumを起動するラッパー

## cura

- curaを起動するラッパー

## genymotion

- genymotionを起動するラッパー

## nvim

- neovimを起動するラッパー

## gpf

- fzfとgemini-cliを連携させ、定型的なgit操作やREADMEの編集作業を支援

