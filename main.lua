local Listener = require 'src.listener'
local listener = Listener('*', 5000)
listener:connect_signal('connected', function(id, ip)
  print(string.format('connected <%d:%s>', id, ip))
end)
listener:connect_signal('data_received', function(channel, id, buff)
  -- print('data received from ' .. tostring(id) .. ': ' .. buff)
end)
listener:connect_signal('disconnected', function(id)
  print('disconnected ' .. tostring(id))
end)
listener:start()

while true do listener:poll() end
