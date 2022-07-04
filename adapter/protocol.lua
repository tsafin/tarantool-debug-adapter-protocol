local messages = require 'messages'
local json = require 'json'

local Emitter = {
    event = {},
    listener = nil, -- callback
}

function Emitter:event()
    -- FIXME
    return {}
end

function Emitter:fire(event)
    -- FIXME

end

function Emitter:hasListener()
    return false
end

function Emitter:dispose()
    self.listener = nil
    -- self = nil
end

local TWO_CRLF = '\r\n\r\n'

local ProtocolServer = function()
    local self = {}
    self.sendMessage = Emitter
    self.handleMessage = function (msg)
        if msg.type == 'request' then
            self.dispatchRequest(msg)
        else if msg.type == 'response' then
            local clb = self.pendingRequests.get(response.request_seq)
            if clb ~= nil then
                self.pendingRequests.delete(response.request_seq)
                clb(response)
            end
        end
    end

    self.start = function(inStream, outStream)
        -- TODO
    end

    self.stop = function()
        if self.writableStream ~= nil then
            self.writableStream._end()
        end
    end

    self.sendEvent = function(event)
        self:_send('event', event)
    end

    self.sendResponse = function (response)
        if response.seq > 0 then
            error(('attempt to send more than one response for command %s'):
                  format(response.command))
        else
            self:_send('response', response)
        end
    end

    self.sendRequest = function (command, args, timeout, cb)
        local request = {
            command  = command,
            arguments = args
        }
        self:_send('request', request)
        if cb ~= nil then
            self:pendingRequests.set(request.seq, cb)
            -- local timer = bobobo
            -- FIXME - delayed delete
        end
    end

    self.dispatchRequest = function(request) end

    -- WTF?
    self.emitEvent = function(event)
        self:emit(event.event, event)
    end

    self._send = function(type, message)
        message.type = type
        self._sequence = self._sequence + 1
        message.seq = self._sequence

        if self.writableStream ~= nil then
            local jsonS = json.encode(message)
            writableStream.write(('Content-Length: %d\r\n\r\n%s'):
                                  format(#jsonS, jsonS))
            self.sendMessage.fire(message)
        end
    end

    self._handleDate = function(data)
        self.rawData = self.rawData .. data
        while true do
            if self.contentLength >= 0 then
                if #(self.rawData) >= self.contentLength then
                    local message = string.sub(self.rawData, 1, self.contentLength)
                    self.contentLength = -1
                    if #message > 0 then
                        local ok, msg = pcall(json.parse, message)
                        if ok then
                            self:handleMessage(msg)
                        end
                        goto continue
                    end
                end
            else
                local idx = string.find(self.rawData, TWO_CRLF)
                if idx then
                    local header = string.substr(self.rawData, 1, idx)
                    for _, line in pairs(string.split(header)) do
                        local left, right = string.split(line, ': ')
                        if left == 'Content-Length' then
                            self.contentLength = tonumber(right)
                        end
                    end
                    self.rawData = string.sub(self.rawData, idx + #TWO_CRLF + 1)
                    goto continue
                end
            end
            break
            ::continue::
        end
    end
end
