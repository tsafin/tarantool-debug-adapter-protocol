local Messages = {}

-- DebugProtocol.ProtocolMessage
function Messages.ProtocolMessage(type)
    return {
        seq = 0,
        -- type: 'request' | 'response' | 'event' | string;
        type = type
    }
end

-- we do not supposed to create DebugProtocol.Requests
-- It's client (vscode) responsibility

-- DebugProtocol.Response
function Messages.Response(request, message)
    return {
        -- ProtocolMessage
        seq = 0,
        type = 'response',

        -- Response
        request_seq = request.seq,
        command = request.command,
        message = message,
        success = message ~= nil
    }
end

-- DebugProtocol.Event
function Messages.Event(event, body)
    return {
        -- ProtocolMessage
        seq = 0,
        type = 'event',
        -- Event
        event = event,
        body = body,
    }
end

return Messages
