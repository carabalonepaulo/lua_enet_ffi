---@diagnostic disable: need-check-nil
local fs = require 'fs'
local ffi = require 'ffi'

local CHUNK_SIZE = 256

return {
  exists = function(path)
    return fs.attr(path, 'mtime') ~= nil
  end,

  write_all = function(path, contents)
    local file = io.open(path, 'w+')
    file:write(contents)
    file:close()
  end,

  read_all = function(path)
    local file = assert(io.open(path, 'r'), string.format("File '%s' doesn't exist!", path))
    local contents = file:read('*all')
    file:close()
    return contents
  end,

  copy = function(src_path, dest_path)
    assert(fs.attr(src_path, 'mtime'), string.format("File '%s' doesn't exist!", src_path))

    local buff = ffi.new('char[?]', CHUNK_SIZE)
    local src_file = fs.open(src_path, 'r')
    local dest_file = fs.open(dest_path, 'w')

    local read_len
    repeat
      read_len = src_file:read(buff, CHUNK_SIZE)
      dest_file:write(buff, read_len)
    until read_len == 0

    src_file:close()
    dest_file:close()
  end
}
