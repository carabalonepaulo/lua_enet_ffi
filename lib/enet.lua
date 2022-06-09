local ffi = require 'ffi'

local function read_all(path)
  local file = assert(io.open(path, 'r'), string.format("File '%s' doesn't exist!", path))
  local contents = file:read('*all')
  file:close()
  return contents
end

ffi.cdef(read_all('lib/enet.h'))
return ffi.load('bin/ENetX64.dll')
