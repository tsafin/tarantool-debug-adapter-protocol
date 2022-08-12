/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/
/*
 * activateTarantoolDap.ts containes the shared extension code that can be executed both in node.js and the browser.
 */
'use strict';
exports.__esModule = true;
exports.activateTarantoolDap = void 0;
var vscode = require("vscode");
// import { TarantoolDapSession } from './mockDebug';
// import { FileAccessor } from './mockRuntime';
function activateTarantoolDap(context, factory) {
    context.subscriptions.push(vscode.commands.registerCommand('extension.tarantool-debug.runEditorContents', function (resource) {
        var targetResource = resource;
        if (!targetResource && vscode.window.activeTextEditor) {
            targetResource = vscode.window.activeTextEditor.document.uri;
        }
        if (targetResource) {
            vscode.debug.startDebugging(undefined, {
                type: 'tarantool-dap',
                name: 'Run File',
                request: 'launch',
                program: targetResource.fsPath
            }, { noDebug: true });
        }
    }), vscode.commands.registerCommand('extension.tarantool-debug.debugEditorContents', function (resource) {
        var targetResource = resource;
        if (!targetResource && vscode.window.activeTextEditor) {
            targetResource = vscode.window.activeTextEditor.document.uri;
        }
        if (targetResource) {
            vscode.debug.startDebugging(undefined, {
                type: 'tarantool-dap',
                name: 'Debug File',
                request: 'launch',
                program: targetResource.fsPath,
                stopOnEntry: true
            });
        }
    }), vscode.commands.registerCommand('extension.tarantool-debug.toggleFormatting', function (variable) {
        var ds = vscode.debug.activeDebugSession;
        if (ds) {
            ds.customRequest('toggleFormatting');
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand('extension.tarantool-debug.getProgramName', function (config) {
        return vscode.window.showInputBox({
            placeHolder: "Please enter the name of a markdown file in the workspace folder",
            value: "readme.md"
        });
    }));
    // register a configuration provider for 'tarantool-dap' debug type
    var provider = new TaranoolDapConfigurationProvider();
    context.subscriptions.push(vscode.debug.registerDebugConfigurationProvider('tarantool-dap', provider));
    // register a dynamic configuration provider for 'tarantool-dap' debug type
    context.subscriptions.push(vscode.debug.registerDebugConfigurationProvider('tarantool-dap', {
        provideDebugConfigurations: function (folder) {
            return [
                {
                    name: "Dynamic Launch",
                    request: "launch",
                    type: "tarantool-dap",
                    program: "${file}"
                },
                {
                    name: "Another Dynamic Launch",
                    request: "launch",
                    type: "tarantool-dap",
                    program: "${file}"
                },
                {
                    name: "Mock Launch",
                    request: "launch",
                    type: "tarantool-dap",
                    program: "${file}"
                }
            ];
        }
    }, vscode.DebugConfigurationProviderTriggerKind.Dynamic));
    context.subscriptions.push(vscode.debug.registerDebugAdapterDescriptorFactory('tarantool-dap', factory));
    if ('dispose' in factory) {
        context.subscriptions.push(factory); // WTF??
    }
    // override VS Code's default implementation of the debug hover
    // here we match only Mock "variables", that are words starting with an '$'
    context.subscriptions.push(vscode.languages.registerEvaluatableExpressionProvider('markdown', {
        provideEvaluatableExpression: function (document, position) {
            var VARIABLE_REGEXP = /\$[a-z][a-z0-9]*/ig;
            var line = document.lineAt(position.line).text;
            var m;
            while (m = VARIABLE_REGEXP.exec(line)) {
                var varRange = new vscode.Range(position.line, m.index, position.line, m.index + m[0].length);
                if (varRange.contains(position)) {
                    return new vscode.EvaluatableExpression(varRange);
                }
            }
            return undefined;
        }
    }));
    // override VS Code's default implementation of the "inline values" feature"
    context.subscriptions.push(vscode.languages.registerInlineValuesProvider('markdown', {
        provideInlineValues: function (document, viewport, context) {
            var allValues = [];
            for (var l = viewport.start.line; l <= context.stoppedLocation.end.line; l++) {
                var line = document.lineAt(l);
                var regExp = /\$([a-z][a-z0-9]*)/ig; // variables are words starting with '$'
                do {
                    var m = regExp.exec(line.text);
                    if (m) {
                        var varName = m[1];
                        var varRange = new vscode.Range(l, m.index, l, m.index + varName.length);
                        // some literal text
                        //allValues.push(new vscode.InlineValueText(varRange, `${varName}: ${viewport.start.line}`));
                        // value found via variable lookup
                        allValues.push(new vscode.InlineValueVariableLookup(varRange, varName, false));
                        // value determined via expression evaluation
                        //allValues.push(new vscode.InlineValueEvaluatableExpression(varRange, varName));
                    }
                } while (m);
            }
            return allValues;
        }
    }));
}
exports.activateTarantoolDap = activateTarantoolDap;
var TaranoolDapConfigurationProvider = /** @class */ (function () {
    function TaranoolDapConfigurationProvider() {
    }
    /**
     * Massage a debug configuration just before a debug session is being launched,
     * e.g. add all missing attributes to the debug configuration.
     */
    TaranoolDapConfigurationProvider.prototype.resolveDebugConfiguration = function (folder, config, token) {
        // if launch.json is missing or empty
        if (!config.type && !config.request && !config.name) {
            var editor = vscode.window.activeTextEditor;
            if (editor && editor.document.languageId === 'markdown') {
                config.type = 'tarantool-dap';
                config.name = 'Launch';
                config.request = 'launch';
                config.program = '${file}';
                config.stopOnEntry = true;
            }
        }
        if (!config.program) {
            return vscode.window.showInformationMessage("Cannot find a program to debug").then(function (_) {
                return undefined; // abort launch
            });
        }
        return config;
    };
    return TaranoolDapConfigurationProvider;
}());
