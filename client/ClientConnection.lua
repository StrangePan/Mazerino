require "Connection"
require "ConnectionStatus"
require "Queue"

-- message handler and coordinator for clients

ClientConnection = buildClass(Connection)
local Class = ClientConnection

--
-- Initializes a new connection object optimized for clients. Registers
-- as a listener for messageReceiver's messages and automaticaly handles
-- communication with server.
--
function Class:_init()
  Class.superclass._init(self, 25566)
  
  self.serverAddress = '127.0.0.1'
  self.serverPort = 25565
  self.server = {
    address = self.serverAddress,
    port = self.serverPort
  }
  
  -- Initialize status variables
  self.connectionStatus = ConnectionStatus.DISCONNECTED
  self.connectionId = nil
  self.connectionSendTime = nil
  self.lastReceivedTime = nil
  self.lastSentTime = nil
  self.outQueue = Queue()
  
  -- Register for message callbacks
  self.receiver:registerListener(MessageType.SERVER_CONNECT_ACK,
    self, self.onReceiveServerConnectAck)
  
  self.receiver:registerListener(MessageType.PING,
    self, self.onReceivePing)
end

--
-- Gets the current status of the connection with the server.
-- Returns a ConnectionStatus enum value.
--
function Class:getConnectionStatus()
  return self.connectionStatus
end

--
-- Changes the connection status and notifies registered listeners if
-- necessary.
--
function Class:setConnectionStatus(status)
  self.connectionStatus = status
end

function Class:connectToServer()
  
  -- ignore command if already connected/connecting
  if self:getConnectionStatus() ~= ConnectionStatus.DISCONNECTED then
    return
  end
  
  -- initialize connection protocol
  self:requestConnectToServer()
  self:setConnectionStatus(ConnectionStatus.CONNECTING)
end

function Class:requestConnectToServer()
  print("attempting to connect to server @ "..self.serverAddress..":"..self.serverPort)
  self:sendMessage(messages.clientConnectInit())
  self.connectionSendTime = love.timer.getTime()
end

function Class:disconnectFromServer()
  if self:getConnectionStatus() == ConnectionStatus.DISCONNECTED then
    return
  end
  print("disconnected from server")
  self:sendMessage(messages.clientDisconnect())
  self.connectionSendTime = nil
  self.lastReceivedTime = nil
  self.connectionId = nil
  self:setConnectionStatus(ConnectionStatus.DISCONNECTED)
end

--
-- Reads and processes incoming messages
--
function Class:update()
  self.receiver:processIncomingMessages()
  
  local time = love.timer.getTime()
  
  -- ping server periodically
  if (self.connectionStatus == ConnectionStatus.CONNECTED or
      self.connectionStatus == ConnectionStatus.STALLED) and
      time >= self.lastSentTime + 2 then
    self:sendMessage(messages.ping())
  end
  
  -- handle timeouts
  if self:getConnectionStatus() == ConnectionStatus.CONNECTING and
      time >= self.connectionSendTime + 3 then
    self:requestConnectToServer()
  elseif self:getConnectionStatus() == ConnectionStatus.CONNECTED and
      time >= self.lastReceivedTime + 5 then
    self:setConnectionStatus(ConnectionStatus.STALLED)
    print("connection stalled")
  elseif self:getConnectionStatus() == ConnectionStatus.STALLED and
      time >= self.lastReceivedTime + 30 then
    self:disconnectFromServer()
    print("connection timed out")
  end
end

--
-- Handles an incoming message of type MessageType.SERVER_CONNECT_ACK
--
function Class:onReceiveServerConnectAck(message, address, port)
  if self:shouldIgnore(message, address, port) then return end
  self:updateLastReceivedTime()
  
  -- ignore message if not looking to connect
  if self:getConnectionStatus() ~= ConnectionStatus.CONNECTING then return end
  
  print("connected to server with client id "..message.id)
  self.connectionId = message.id
  self:setConnectionStatus(ConnectionStatus.CONNECTED)
end

function Class:onReceivePing(message, address, port)
  if self:shouldIgnore(message, address, port) then return end
  self:updateLastReceivedTime()
  print("received ping")
end


--
-- returns true if the given message should not be processed
--
function Class:shouldIgnore(message, address, port)
  return address ~= self.serverAddress or port ~= self.serverPort
end

--
-- Updates the last received message time to prevent connection going stale
--
function Class:updateLastReceivedTime()
  self.lastReceivedTime = love.timer.getTime()
  if self:getConnectionStatus() == ConnectionStatus.STALLED then
    self:setConnectionStatus(ConnectionStatus.CONNECTED)
  end
end

function Class:sendMessage(message)
  self.sender:sendMessage(message, self.server)
  self.lastSentTime = love.timer.getTime()
end
