# my-tools
自分用の小さなツール集

## bbhd

- "busybox httpd"を用いて指定したディレクトリをホスティングするwebサーバー

## bbud

- パイプで受け取った標準出力をurlデコード,改行付きで出力

	- "-a"オプションで改行無しで出力

## bbhe

- パイプで受け取った標準出力をhtmlエンコード,改行付きで出力

	- "-a"オプションで改行無しで出力

## bd2p

- "GNU barcode"と"imagemagic"を使いjanコードを生成

## c2h

- カンマ区切りのテキストファイルをhtmlのtableに変換

## c2x

- カンマ区切りのテキストファイルをxmlに変換

## cpugv

- cpuガバナーの調整

## csrch

- 対話形式でcsvファイル内を検索

## fpr

- ファイル内の文字列を非対話的に置換

## sands,sandv

- 自分のデスクトップPCの設定用コマンド

## tbug

- "/tmp/"ディレクトリにパイプの途中経過を保存

	- "-q"オプションで出力を抑制

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

	- "-t"オプションで疎通時にPOSTを送信

	- "-f"オプションで疎通失敗時にPOSTを送信

## mdwc

- markdownの文章の文字数のみをカウント
