local Messages = require 'messages'
local Response = Messages.Response
local Request = Messages.Request
local Event = Messages.Event
local bit = require 'bit'

-- try/finally helpers
function try(do_f, catch_f)
    local status, error = pcall(do_f)
    if not status then
        catch_f(error)
    end
end

-- module
local M = {}

function M.Source(name, path, id, origin, data)
    return {
        name = name,
        path = path,
        sourceReference = id,
        origin = origin,
        adapterData = data,
    }
end

function M.Scope(name, reference, expensive)
    return {
        name = name,
        variablesReference = reference,
        expensive = expensive,
    }
end

function M.StackFrame(o, nm, src, ln, col)
    return {
        id = i,
        source = src,
        line = ln,
        column = col,
        name = nm,
    }
end

function M.Thread(id, name)
    return {
        id = id,
        name = name or ('Thread #%d'):format(id)
    }
end

local function checkedNumber(v)
    return type(v) == 'number' and v or nil
end

local function checkedText(v)
    return type(v) == 'string' and v or nil
end

local function checkedBoolean(v)
    return type(v) == 'boolean' and v or nil
end

function M.Variable(name, value, ref, indexedVariables,
                               namedVariables)
    return {
        name = name,
        value = value,
        variablesReference = ref,
        namedVariables = checkedNumber(namedVariables),
        indexedVariables = checkedNumber(indexedVariables),
    }
end

function M.Breakpoint(verified, line, column, source)
    return {
        id = 0, -- FIXME
        verified = verified,
        line = checkedNumber(line),
        column = checkedNumber(column),
        source = source,
    }
end

-- M.Module

-- M.CompletionItem

function M.StoppedEvent(reason, threadId, exceptionText)
    local self = Event('stopped', {
                            reason = reason,
                            text = checkedText(exceptionText)
                        })
    self.threadId = checkedNumber(threadId)
    return self
end

function M.ContinuedEvent(threadId, allThreadsContinued)
    return Event('continued', {
                    threadId = threadId,
                    allThreadsContinued =
                    checkedBoolean(allThreadsContinued)
                })
end

function M.InitializedEvent()
    return Event('initialized')
end

function M.TerminatedEvent(restart)
    return Event('terminated', {restart = checkedBoolean(restart)})
end

function M.ExitedEvent(exitCode)
    return Event('exited', {exitCode = exitCode})
end

function M.OutputEvent(output, category, data)
    return Event('output', {
                    category = category,
                    output = output,
                    data = data,
                })
end

function M.ThreadEvent(reason, threadId)
    return Event('thread', {
                    reason = reason,
                    threadId = threadId,
                })
end

function M.BreakpointEvent(reason, breakpoint)
    return Event('breakpoint', {
                    reason = reason,
                    breakpoint = breakpoint,
                })
end

-- M.ModuleEvent

function M.LoadedSourceEvent(reason, source)
    return Event('loadedSource', {
                    reason = reason,
                    source = source,
                })
end

function M.CapabilitiesEvent(capabilities)
    return Event('capabilities', {capabilities = capabilities})
end

-- M.ProgressStartEvent

-- M.ProgressUpdateEvent

-- M.ProgressEndEvent

function M.InvalidatedEvent(areas, threadId, stackFrameId)
    return Event('invalidated', {
                    areas = areas,
                    threadId = threadId,
                    stackFrameId = stackFrameId,
                })
end

-- M.MemoryEvent

local ErrorDestination = {
	User = 1,
	Telemetry = 2
}

function M.DebugSession()
    local session = {
        debuggerPathsAreURIs = false,

        clientLinesStartAt1 = true,
        clientColumnsStartAt1 = true,
        clientPathsAreURIs = false,
        isServer = false,
    }

    function session:setDebuggerPathFormat(format)
        self.debuggerPathsAreURIs = format ~= 'path';
    end

    function session:setDebuggerPathFormat(format)
        self.debuggerPathsAreURIs = format ~= 'path'
    end

    function session:setDebuggerLinesStartAt1(enable)
        self.debuggerLinesStartAt1 = enable
    end

    function session:setDebuggerColumnsStartAt1(enable)
        self.debuggerColumnsStartAt1 = enable
    end

    function session:setRunAsServer(enable)
        self.isServer = enable;
    end

    function session:run()
        -- TODO
        return self
    end

    function session.shutdown()
        os.exit(0)
    end

    function session:sendErrorResponse(response, codeOrMessage, format,
                                       variables, dest)
        local msg = {}
        if (type(codeOrMessage) == 'number') then
            msg = {
                id = codeOrMessage,
                format = format,
                variables = variables,
                showUser = bit.band(dest, ErrorDestination.User) ~= 0 and true,
                sendTelemetry = bit.band(dest, ErrorDestination.Telemetry) ~= 0
                                and true,
            }
        else
            msg = codeOrMessage
        end
        response.success = false
        response.message = self:formatPII(msg.format, true, ,sg.variables)
        response.body = response.body or {}
        self:sendResponse(response)
    end

    function session:runInTerminalRequest(args, timeout, cb)
        self:sendRequest('runInTerminal', args, timeout, cb)
    end

    function session:dispatchRequest(request)
        local response = Response(request)
        try(
            function()
                local commands = {
                ['initialize'] = function()
                    local args = request.arguments
                    if type(args.linesStartAt1) == 'boolean' then
                        self.clientLinesStartAt1 = args.linesStartAt1
                    else if type(args.columnsStartAt1) == 'boolean' then
                        self.clientColumnsStartAt1 = args.columnsStartAt1
                    end
                    if args.pathFormat ~= 'path' then
                        self:sendErrorResponse(response, 2018, 
                                               'debug adapter only supports native paths',
                                               nil, ErrorDestination.Telemetry)
                    else
                        local initializeResponse = response
                        initializeResponse.body = {}
                        self:initializeRequest(initializeResponse, args)
                    end
                end,

                ['launch'] = function ()
                    self:launchRequest(response, request.arguments, request)
                end,

                ['attach'] = function ()
                    self:attachRequest(response, request.arguments, request)
                end,

                ['disconnect'] = function ()
                    self:disconnectRequest(response, request.arguments, request)
                end,

                ['terminate'] = function ()
                    self:terminateRequest(response, request.arguments, request)
                end,

                ['restart'] = function ()
                    self:restartRequest(response, request.arguments, request)
                end,

                ['setBreakpoints'] = function ()
                    self:setBreakPointsRequest(response, request.arguments, request)
                end,

                ['setFunctionBreakpoints'] = function()
                    self:setFunctionBreakPointsRequest(response, request.arguments, request)
                end,

                ['setExceptionBreakpoints'] = function()
                    self:setExceptionBreakPointsRequest(response, request.arguments, request)
                end,

                ['configurationDone'] = function()
                    self:configurationDoneRequest(response, request.arguments, request)
                end,

                ['continue'] = function()
                    self:continueRequest(response, request.arguments, request)
                end,

                ['next'] = function()
                    self:nextRequest(response, request.arguments, request)
                end,

                ['stepIn'] = function()
                    self:stepInRequest(response, request.arguments, request)
                end,

                ['stepOut'] = function()
                    self:stepOutRequest(response, request.arguments, request)
                end,

                ['stepBack'] = function()
                    self:stepBackRequest(response, request.arguments, request)
                end,

                ['reverseContinue'] = function()
                    self:reverseContinueRequest(response, request.arguments, request)
                end,

                ['restartFrame'] = function()
                    self:restartFrameRequest(response, request.arguments, request)
                end,

                ['goto'] = function()
                    self:gotoRequest(response, request.arguments, request)
                end,

                ['pause'] = function()
                    self:pauseRequest(response, request.arguments, request)
                end,

                ['stackTrace'] = function()
                    self:stackTraceRequest(response, request.arguments, request)
                end,

                ['scopes'] = function()
                    self:scopesRequest(response, request.arguments, request)
                end,

                ['variables'] = function()
                    self:variablesRequest(response, request.arguments, request)
                end,

                ['setVariable'] = function()
                    self:setVariableRequest(response, request.arguments, request)
                end,

                ['setExpression'] = function()
                    self:setExpressionRequest(response, request.arguments, request)
                end,

                ['source'] = function()
                    self:sourceRequest(response, request.arguments, request)
                end,

                ['threads'] = function()
                    self:threadsRequest(response, request.arguments, request)
                end,

                ['terminateThreads'] = function()
                    self:terminateThreadsRequest(response, request.arguments, request)
                end,

                ['evaluate'] = function()
                    self:evaluateRequest(response, request.arguments, request)
                end,

                ['stepInTargets'] = function()
                    self:stepInTargetsRequest(response, request.arguments, request)
                end,

                ['gotoTargets'] = function()
                    self:gotoTargetsRequest(response, request.arguments, request)
                end,

                ['completions'] = function()
                    self:completionsRequest(response, request.arguments, request)
                end,

                ['exceptionInfo'] = function()
                    self:exceptionInfoRequest(response, request.arguments, request)
                end,

                ['loadedSources'] = function()
                    self:loadedSourcesRequest(response, request.arguments, request)
                end,

                ['dataBreakpointInfo'] = function()
                    self:dataBreakpointInfoRequest(response, request.arguments, request)
                end,

                ['setDataBreakpoints'] = function()
                    self:setDataBreakpointsRequest(response, request.arguments, request)
                end,

                ['readMemory'] = function()
                    self:readMemoryRequest(response, request.arguments, request)
                end,

                ['writeMemory'] = function()
                    self:writeMemoryRequest(response, request.arguments, request)
                end,

                ['disassemble'] = function()
                    self:disassembleRequest(response, request.arguments, request)
                end,

                ['cancel'] = function()
                    self:cancelRequest(response, request.arguments, request)
                end,

                ['breakpointLocations'] = function()
                    self:breakpointLocationsRequest(response, request.arguments, request)
                end,

                ['setInstructionBreakpoints'] = function()
                    self:setInstructionBreakpointsRequest(response, request.arguments, request)
                end,
                }
                local commandHandler = commands[request.command]
                commandHandler and commandHandler() or
                    self:customRequest(request.command, response,
                                       request.arguments, request)
            end,
        -- catch
            function(error)
                self:sendErrorResponse(response, 1104, '{no_stack}',
                                       { _exception: error},
                                       ErrorDestination.Telemetry)
            end
        )
    end

    return session
end

return M
