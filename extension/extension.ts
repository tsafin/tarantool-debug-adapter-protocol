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

"use strict";

import { exec } from "child_process";
import * as vscode from "vscode";
import { ProviderResult } from "vscode";
// import { TarantoolDapSession } from './mockDebug';
import { activateTarantoolDap } from "./activateTarantoolDap";
import { DebugProxy } from "debugProxy";

export function activate(context: vscode.ExtensionContext) {
	// run the debug adapter as a separate process
	activateTarantoolDap(context, new DebugAdapterExecutableFactory());
}

export function deactivate() {
	// nothing to do
}

class DebugAdapterExecutableFactory
	implements vscode.DebugAdapterDescriptorFactory
{
	// The following use of a DebugAdapter factory shows how to control what debug adapter executable is used.
	// Since the code implements the default behavior, it is absolutely not neccessary and we show it here only for educational purpose.

	createDebugAdapterDescriptor(
		_session: vscode.DebugSession,
		executable: vscode.DebugAdapterExecutable | undefined
	): ProviderResult<vscode.DebugAdapterDescriptor> {
		console.log('createDebugAdapterDescriptor', _session, executable);
		// param "executable" contains the executable optionally specified in the package.json (if any)

		// override automatically constructed executable
		const command =
			"/home/tsafin/debug/tarantool-debug-adapter-protocol/bins/tarantool";
		const args = ["/home/tsafin/debug/tarantool-debug-adapter-protocol/bins/echojson", "another arg"];
		const options = {
			cwd: "/home/tsafin/debug/tarantool-debug-adapter-protocol/bins/",
			env: { envVariable: "some value" },
		};
		executable = new vscode.DebugAdapterExecutable(
			command,
			args,
			options
		);
		console.log(executable);

		// make VS Code launch the DA executable
		return executable;
	}
}

