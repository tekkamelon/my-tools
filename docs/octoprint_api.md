# OctoPrint APIを利用したステータス取得

OctoPrintのREST APIを利用して、プリンターの状態やジョブの進捗状況を`curl`で取得する方法について記します。

## 基本的なエンドポイント

### 1. プリンター情報の取得
プリンターの接続状態、温度、現在の軸の状態などを取得します。

- **Endpoint**: `/api/printer`
- **Method**: `GET`
- **Command**:
	```bash
	curl -H "X-Api-Key: YOUR_API_KEY" http://<OctoPrintのIPアドレス>/api/printer
	```

### 2. ジョブ情報の取得
現在のプリントジョブの状態（ファイル名、進捗率、残り時間など）を取得します。

- **Endpoint**: `/api/job`
- **Method**: `GET`
- **Command**:
	```bash
	curl -H "X-Api-Key: YOUR_API_KEY" http://<OctoPrintのIPアドレス>/api/job
	```

## 実行例

### 進捗率の取得 (jqを使用)
現在のプリント進捗率（パーセント）のみを抽出する場合：

```bash
curl -s -H "X-Api-Key: YOUR_API_KEY" http://octopi.local/api/job | jq '.progress.completion'
```

### ステータス文字列の取得
現在のプリンターの状態（Printing, Operational, Offlineなど）を取得する場合：

```bash
curl -s -H "X-Api-Key: YOUR_API_KEY" http://octopi.local/api/job | jq -r '.state'
```

## 必要な情報
- **X-Api-Key**: OctoPrintの「Settings > API」から生成・確認できるAPIキー。
- **Host**: OctoPrintが動作しているホスト名（例: `octopi.local`）またはIPアドレス。

## レスポンス形式 (例: /api/job)
```json
{
	"job": {
		"file": {
			"name": "example.gcode",
			"origin": "local",
			"size": 123456,
			"date": 1615814400
		},
		"estimatedPrintTime": 3600.0,
		"lastPrintTime": 3550.0,
		"filament": {
			"tool0": {
				"length": 1500.0,
				"volume": 3.6
			}
		}
	},
	"progress": {
		"completion": 50.0,
		"filepos": 61728,
		"printTime": 1800,
		"printTimeLeft": 1800,
		"printTimeLeftOrigin": "analysis"
	},
	"state": "Printing"
}
```
