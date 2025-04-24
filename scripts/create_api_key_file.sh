#!/bin/bash

# 引数チェック
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <path> <base_dir> <api_key_base64>"
  exit 1
fi

# 引数の割り当て
API_KEY_FILE_PATH="$1"
BASE_DIR="$2"
API_KEY_BASE_64="$3"

# ASCのAPIキーファイル生成処理を行う
mkdir -p $BASE_DIR
echo "$API_KEY_BASE_64" | base64 --decode > "$API_KEY_FILE_PATH"
chmod 600 "$API_KEY_FILE_PATH"