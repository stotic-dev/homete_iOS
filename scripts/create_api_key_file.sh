#!/bin/bash

# 引数チェック
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <base_directory> <api_key_id> <api_key_base64>"
  exit 1
fi

# 引数の割り当て
BASE_DIR="$1"
API_KEY_ID="$2"
API_KEY_BASE_64="$3"

# ASCのAPIキーファイル生成処理を行って、環境変数に設定する
mkdir -p private_keys
API_KEY_PATH="$BASE_DIR/AuthKey_$API_KEY_ID.p8"
echo "$API_KEY_BASE_64" | base64 --decode > "$API_KEY_PATH"
chmod 600 "$API_KEY_PATH"
export API_KEY_PATH