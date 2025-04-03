import { getWebSocket } from "./index.js"
import { sendSystem } from "./utility.js"

let helpMessage = ""

const commands = {
	OWNER: {
		kick: {
			targetArg: true,
			description: "kicks a member from the chat",
		},
		invite: {
			targetArg: true,
			description: "generates an invite code for the user specified",
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
