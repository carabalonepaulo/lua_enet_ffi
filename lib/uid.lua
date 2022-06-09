local Object = require 'lib.object'
local UID = Object:extend()

function UID:new()
  self.available_indices = {}
  self.highest_indice = 0
end

function UID:next()
  if #self.available_indices > 0 then
    return table.remove(self.available_indices)
  end
  self.highest_indice = self.highest_indice + 1
  return self.highest_indice
end

function UID:free(id)
  table.insert(self.available_indices, id)
end

return UID
