#!/usr/bin/perl -e$_=$ARGV[0];exec(s|[^/]+$|tarantool|r,@ARGV)
local fh = io.open('/home/tsafin/debug/tarantool-debug-adapter-protocol/bins/echo.log', 'w+')
local jsonl = io.open('package.jsonl', 'r')
local json = require 'json'
json.cfg{
    encode_invalid_numbers = true,
    encode_load_metatables = true,
    encode_use_tostring    = true,
    encode_invalid_as_nil  = true,
}

for line in jsonl:lines() do
    local M = json.decode(line)
    local S = json.encode(M)
    fh:write(S .. "\n")
    print(S)
end
jsonl:close()
fh:close()
