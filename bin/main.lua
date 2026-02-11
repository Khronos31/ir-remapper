#!/usr/bin/env lua

-- ディレクトリ解決
local script_path = debug.getinfo(1).source:match("@?(.*)/") or "."
package.path = script_path .. "/../config/?.lua;" .. package.path

package.path = "/home/yunomin61/.luarocks/share/lua/5.4/?.lua;/home/yunomin61/.luarocks/share/lua/5.4/?/init.lua;" .. package.path
package.cpath = "/home/yunomin61/.luarocks/lib/lua/5.4/?.so;" .. package.cpath

local socket = require("socket")
local usbir = require("usbir")
local config = require("config")

local function log(msg)
    print(string.format("[%s] %s", os.date("%Y-%m-%d %H:%M:%S"), msg))
end

local function to_hex(data)
    return (data:gsub('.', function(c)
        return string.format('%02X ', string.byte(c))
    end))
end

local dev, err = usbir.open()
if not dev then
    log("❌ デバイスエラー: " .. (err or "不明"))
    os.exit(1)
end

log("🚀 ir-remapper 起動成功")
log("📡 受信待機中...")

while true do
    local recv_data = dev:receive()
    
    if recv_data and #recv_data > 0 then
        log("📥 受信: " .. to_hex(recv_data))
        
        local send_data = config.remap[recv_data]
        if send_data then
            log("🎯 マッチ！送信中...")
            socket.select(nil, nil, 0.4)
            dev:send(send_data)
        end
    end
    -- 必要に応じてウェイトを入れてください
    -- os.execute("sleep 0.1")
end

