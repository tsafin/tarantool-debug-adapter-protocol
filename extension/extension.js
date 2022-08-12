"use strict";
/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/
/*
 * extension.ts (and activateTarantoolDap.ts) forms the "plugin" that plugs into VS Code and contains the code that
 * connects VS Code with the debug adapter.
 *
 * extension.ts contains code for launching the debug adapter in three different ways:
 * - as an external program communicating with VS Code via stdin/stdout,
 * - as a server process communicating with VS Code via sockets or named pipes, or
 * - as inlined code running in the extension itself (default).
 *
 * Since the code in extension.ts uses node.js APIs it cannot run in the browser.
 */
exports.__esModule = true;
exports.deactivate = exports.activate = void 0;
//"use strict";
var vscode = require("vscode");
// import { TarantoolDapSession } from './mockDebug';
var activateTarantoolDap_1 = require("./activateTarantoolDap");
function activate(context) {
    // run the debug adapter as a separate process
    (0, activateTarantoolDap_1.activateTarantoolDap)(context, new DebugAdapterExecutableFactory());
}
exports.activate = activate;
function deactivate() {
    // nothing to do
}
exports.deactivate = deactivate;
var DebugAdapterExecutableFactory = /** @class */ (function () {
    function DebugAdapterExecutableFactory() {
    }
    // The following use of a DebugAdapter factory shows how to control what debug adapter executable is used.
    // Since the code implements the default behavior, it is absolutely not neccessary and we show it here only for educational purpose.
    DebugAdapterExecutableFactory.prototype.createDebugAdapterDescriptor = function (_session, executable) {
        // param "executable" contains the executable optionally specified in the package.json (if any)
        // use the executable specified in the package.json if it exists or determine it based on some other information (e.g. the session)
        if (!executable) {
            var command = "//home/tsafin/debug/tarantool-debug-adapter-protocol/bins/readline.lua";
            var args = ["some args", "another arg"];
            var options = {
                cwd: "working directory for executable",
                env: { envVariable: "some value" }
            };
            executable = new vscode.DebugAdapterExecutable(command, args, options);
        }
        // make VS Code launch the DA executable
        return executable;
    };
    return DebugAdapterExecutableFactory;
}());
