local ffi = require 'ffi'
local bit = require 'bit'
local enet = require 'lib.enet'
local UID = require 'lib.uid'

local EVENT_TYPE = ffi.typeof('ENetEvent')

local Listener = require('lib.emitter'):extend()

local function get_ip_from(address)
  return string.format('%d.%d.%d.%d',
    bit.band(address.host, 0xFF),
    bit.band(bit.rshift(address.host, 8), 0xFF),
    bit.band(bit.rshift(address.host, 16), 0xFF),
    bit.band(bit.rshift(address.host, 24), 0xFF))
end

local function create_packet(buff, type)
  local packet_type = type or enet.ENET_PACKET_FLAG_RELIABLE
  return enet.enet_packet_create(buff, buff:len() + 1, packet_type)
end

local function get_peer_id(peer)
  return tonumber(ffi.cast('int', peer.data))
end

function Listener:new(ip, port, max_connections, max_channels, incoming_bandwidth, outgoing_bandwidth)
  Listener.super.new(self)
  self:register_signals('connected', 'data_received', 'disconnected')
  self.ip = ip
  self.port = port
  self.max_connections = max_connections or 4096
  self.max_channels = max_channels or 1
  self.incoming_bandwidth = incoming_bandwidth or 0
  self.outgoing_bandwidth = outgoing_bandwidth or 0
  self.peers = {}
  self.uid = UID()
end

function Listener:start()
  if enet.enet_initialize() ~= 0 then
    error('An error occurred while initializing ENet.')
  end

  local addr = ffi.new('ENetAddress')
  addr.host = self.ip == '*' and enet.ENET_HOST_ANY or self.ip
  addr.port = self.port

  self.host = enet.enet_host_create(addr, self.max_connections, self.max_channels,
    self.incoming_bandwidth, self.outgoing_bandwidth)

  if ffi.cast('int', self.host) == 0 then
    error('An error occurred while trying to create the host.')
  end
end

function Listener:stop()
  enet.enet_host_flush(self.host)
  enet.host_destroy(self.host)
  enet.enet_deinitialize()
end

function Listener:poll()
  local event = ffi.new(EVENT_TYPE)
  while enet.enet_host_service(self.host, event, 0) > 0 do
    if event.type == enet.ENET_EVENT_TYPE_CONNECT then
      local id = self.uid:next()
      event.peer.data = ffi.cast('void*', id)
      self.peers[id] = event.peer
      self:emit_signal('connected', id, get_ip_from(event.peer.address))
    elseif event.type == enet.ENET_EVENT_TYPE_RECEIVE then
      self:emit_signal('data_received', event.channelID, get_peer_id(event.peer), ffi.string(event.packet.data, event.packet.dataLength))
    elseif event.type == enet.ENET_EVENT_TYPE_DISCONNECT then
      local id = get_peer_id(event.peer)
      self:emit_signal('disconnected', id)
      self.peers[id] = nil
      self.uid:free(id)
    end
  end
end

function Listener:send_to(id, channel, buff, type)
  enet.enet_peer_send(self.peers[id], channel, create_packet(buff, type))
end

function Listener:send_to_all(channel, buff, type)
  local packet = create_packet(buff, type)
  for _, peer in pairs(self.peers) do
    enet.enet_peer_send(peer, channel, packet)
  end
end

function Listener:disconnect(id, data)
  enet.enet_peer_disconnect(self.peers[id], data or 0)
end

function Listener:disconnect_later(id, data)
  enet.enet_peer_disconnect_later(self.peers[id], data or 0)
end

function Listener:disconnect_now(id, data)
  enet.enet_peer_disconnect_now(self.peers[id], data or 0)
end

return Listener
