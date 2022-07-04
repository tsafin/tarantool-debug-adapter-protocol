local Messages = {}

-- DebugProtocol.ProtocolMessage
function Messages.ProtocolMessage(type)
    return {
        seq = 0,
        -- type: 'request' | 'response' | 'event' | string;
        type = type
    }
end

-- DebugProtocol.Request
function Messages.Request(command, arguments)
    return {
        -- ProtocolMessage
        seq = 0,
        type = 'request',

        -- Request
        command = command,
        arguments = arguments,
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

-- DebugProtocol.Response
function Messages.Response(request, message)
    return {
        -- ProtocolMessage
        seq = 0,
        type = 'response',

        -- Response
        request_seq = request.seq,
        command = request.command,
        success = message ~= nil,
        message = message ~= nil and message or 'cancelled',
    }
end

return Messages
