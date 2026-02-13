#!/usr/bin/env lua

-- ディレクトリ解決
local lua_v = _VERSION:match("Lua (%d%.%d)")
local home = os.getenv("HOME")

if home and lua_v then
  -- LuaRocks のパスを動的に生成
  local rocks_lua = home .. "/.luarocks/share/lua/" .. lua_v .. "/?.lua;" ..
                    home .. "/.luarocks/share/lua/" .. lua_v .. "/?/init.lua;"
  local rocks_lib = home .. "/.luarocks/lib/lua/" .. lua_v .. "/?.so;"

  package.path = rocks_lua .. package.path
  package.cpath = rocks_lib .. package.cpath
end

-- 自作スクリプト側のパス解決
local script_path = debug.getinfo(1).source:match("@?(.*)/") or "."
local root = script_path:gsub("/bin$", "")
package.path = root .. "/config/?.lua;" .. package.path
package.cpath = root .. "/bin/?.so;" .. package.cpath

local socket = require("socket")
local usbir = require("usbir")
local config = require("config")

-- ログ出力用関数
local function log(msg)
  print(string.format("[%s] %s", os.date("%Y-%m-%d %H:%M:%S"), msg))
end

-- バイナリデータを16進数文字列に変換
local function to_hex(data)
  return (data:gsub('.', function(c)
    return string.format('%02X ', string.byte(c))
  end))
end

-- デバイスのオープン
local dev, err = usbir.open()
if not dev then
  log("❌ デバイスエラー: " .. (err or "不明"))
  os.exit(1)
end

log("🚀 ir-remapper 起動成功")
log("📡 受信待機中...")

-- メインループ
while true do
  local recv_data = dev:receive()

  if recv_data and #recv_data > 0 then
    log("📥 受信: " .. to_hex(recv_data))

    -- 設定ファイルから対応するアクションを取得
    local action = config.remap[recv_data]
        
    -- 2. 共通設定になければ、現在のモード設定を確認
    if not action then
        action = config.current_mode[recv_data]
    end

    if action then
      log("🎯 マッチ！実行中...")

      if type(action) == "function" then
        -- 関数の場合は実行
        action(recv_data, dev)
      elseif type(action) == "table" then
        -- テーブル（配列）の場合は順次送信
        socket.select(nil, nil, 0.4) -- 送信前の安定化待ち
        for i = 1, #action do
          dev:send(action[i])
          log(string.format("📤 連続送信 (%d/%d)", i, #action))
          socket.select(nil, nil, 0.1) -- 信号間のインターバル
        end
      else
        -- 単一データの場合はそのまま送信
        socket.select(nil, nil, 0.4) -- 送信前の安定化待ち
        dev:send(action)
        log("📤 送信完了")
      end
    end
  end
end
