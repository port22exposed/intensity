import { getWebSocket } from "./index.js"
import { sendSystem } from "./utility.js"

let helpMessage = ""

const commands = {
	EVERYONE: {
		highest: {
			description: "displays the host as a PM",
		},
		status: {
			description: "displays your current permission level as a PM",
		},
	},
	HIERARCHAL: {
		kick: {
			targetArg: true,
			description: "kicks a user from the chat",
		},
	},
	HIGHEST: {
		permup: {
			targetArg: true,
			description: "changes a user's permission level",
		},
		permdown: {
			targetArg: true,
			description: "changes a user's permission level",
		},
	},
}

const commandMap = new Map(
	Object.values(commands).flatMap((roleCommands) =>
		Object.entries(roleCommands)
	)
)

for (const [permissionLevel, commandList] of Object.entries(commands)) {
	const newLine = helpMessage == "" ? "" : "\n"
	helpMessage += `${newLine}${permissionLevel}:\n\n`

	for (const [commandName, data] of Object.entries(commandList)) {
		helpMessage += `/${commandName}${data.targetArg ? ` <username>` : ""} - ${
			data.description
		}\n`
	}
}

export function handleCommand(name, args) {
	if (name == "help") {
		sendSystem(helpMessage)
		return
	}
	const command = commandMap.get(name)
	if (command) {
		if (command.targetArg) {
			if (args[0]) {
				const ws = getWebSocket()
				ws.send(
					JSON.stringify({
						type: "command",
						name: name,
						target: args[0],
					})
				)
			} else {
				sendSystem(
					`failed to execute command, ${name}, no <username> argument provided!`
				)
			}
		} else {
			const ws = getWebSocket()
			ws.send(
				JSON.stringify({
					type: "command",
					name: name,
				})
			)
		}
	}
}
