#!/bin/bash

PROJECT_NAME="ir-remapper"
PROJECT_ROOT=$(cd $(dirname $0); pwd)
SERVICE_NAME="ir-daemon.service"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "🔧 $PROJECT_NAME のセットアップを開始します..."

# フォルダ作成
mkdir -p "$SYSTEMD_USER_DIR"

# シンボリックリンクの作成（既存があれば上書き）
ln -sf "$PROJECT_ROOT/systemd/$SERVICE_NAME" "$SYSTEMD_USER_DIR/$SERVICE_NAME"

# systemdリロード & 有効化
systemctl --user daemon-reload
systemctl --user enable "$SERVICE_NAME"

echo "✨ セットアップが完了しました！"
echo "🚀 起動コマンド: systemctl --user start $SERVICE_NAME"
echo "📊 ログ確認: journalctl --user -u $SERVICE_NAME -f"

