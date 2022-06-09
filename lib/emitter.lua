local Object = require 'lib.object'
local Emitter = Object:extend()

function Emitter:new()
  self.signals = {}
end

function Emitter:register_signals(...)
  for _, signal in pairs({ ... }) do
    if not self.signals[signal] then
      self.signals[signal] = {}
    end
  end
end

function Emitter:connect_signal(signal, callback)
  local signals = self.signals[signal]
  assert(signals, string.format('Invalid signal %s.', signal))
  table.insert(signals, callback)
end

function Emitter:emit_signal(signal, ...)
  assert(self.signals[signal], string.format('Invalid signal %s.', signal))
  for _, callback in ipairs(self.signals[signal]) do
    callback(...)
  end
end

return Emitter
