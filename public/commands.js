import { getWebSocket } from "./index.js";
import { sendSystem } from "./utility.js";

let helpMessage = ""

const commands = {
    EVERYONE: {
        help: {
            description: "sends you here...",
            execute: (args) => {
                sendSystem(helpMessage)
            }
        },
        host: {
            description: "displays the host as a PM",
        },
        status: {
            description: "displays your current permission level as a PM",
        }
    },
    OPERATOR: {
        accept: {
            args: "<username>",
            description: "accepts a user's entry into the group chat",
        },
        deny: {
            args: "<username>",
            description: "denies a user's entry into the group chat",
        },
        kick: {
            args: "<username>",
            description: "kicks a user from the group chat and bans their IP address",
            execute: (args) => {
                if (args && args[0]) {
                    const ws = getWebSocket()
                    ws.send(JSON.stringify({
                        type: "command",
                        name: "kick",
                        target: args[0]
                    }));
                } else {
                    sendSystem("failed to execute, provide a user to kick!")
                }
            }
        }
    },
    OWNER: {
        op: {
            args: "<username>",
            description: "gives a user operator status"
        },
        deop: {
            args: "<username>",
            description: "removes a user's operator status"
        },
        transfer: {
            args: "<username>",
            description: "transfers ownership to another member of the group, you will retain operator status."
        }
    }
}

const commandMap = new Map(
    Object.values(commands).flatMap(roleCommands => 
      Object.entries(roleCommands)
    )
);

for (const [permissionLevel, commandList] of Object.entries(commands)) {
    const newLine = helpMessage == "" ? "" : "\n"
    helpMessage += `${newLine}${permissionLevel}:\n\n`;
    
    for (const [commandName, data] of Object.entries(commandList)) {
        helpMessage += `/${commandName}${data.args ?  ` ${data.args}` : ""} - ${data.description}\n`;
    }
}

export function handleCommand (name, args) {
    const command = commandMap.get(name)
    if (command) {
        command.execute(args)
    }
}
