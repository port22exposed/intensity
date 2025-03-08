import { getWebSocket } from "./index.js"
import { sendSystem } from "./utility.js"

let helpMessage = ""

const commands = {
	EVERYONE: {
		host: {
			description: "displays the host as a PM",
		},
		status: {
			description: "displays your current permission level as a PM",
		},
	},
	OPERATOR: {
		accept: {
			targetArg: true,
			description: "accepts a user's entry into the group chat",
		},
		deny: {
			targetArg: true,
			description: "denies a user's entry into the group chat",
		},
		kick: {
			targetArg: true,
			description: "kicks a user from the group chat and bans their IP address",
		},
	},
	OWNER: {
		op: {
			targetArg: true,
			description: "gives a user operator status",
		},
		deop: {
			targetArg: true,
			description: "removes a user's operator status",
		},
		transfer: {
			targetArg: true,
			description:
				"transfers ownership to another member of the group, you will retain operator status.",
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
					target: "",
				})
			)
		}
	}
}
