import {
	updateScrollPosition,
	createMessageElement,
	sendSystem,
} from "./utility.js"
import { handleCommand } from "./commands.js"
import { onmessage } from "./packets.js"
import * as dom from "./dom.js"

let websocket

function exit() {
	window.location.replace("https://example.com")
}

export function getWebSocket() {
	return websocket
}

window.onload = async () => {
	function send() {
		const message = dom.messagebox.value
		dom.messagelist.appendChild(
			createMessageElement(username, dom.messagebox.value)
		)
		dom.messagelist.scrollTop = dom.messagelist.scrollHeight
		updateScrollPosition()
		if (message.startsWith("/")) {
			const args = message.split(" ")
			const command = args[0].substring(1)
			args.shift()
			handleCommand(command, args)
		} else {
			websocket.send(dom.messagebox.value)
		}
		dom.messagebox.value = ""
	}

	dom.messagebox.addEventListener("keydown", (e) => {
		if (e.key === "Enter") {
			send()
		}
	})

	const joinCode = prompt("Enter the join code provided by the inviter.")

	dom.clientUsername.innerText = "WILL BE SENT BY THE SERVER <3"

	websocket = new WebSocket(
		`${window.location.protocol === "https:" ? "wss:" : "ws:"}//${
			window.location.host
		}/?auth=${joinCode}`
	)

	websocket.onerror = exit
	websocket.onclose = exit
	websocket.onmessage = onmessage

	dom.messagebox.focus()

	sendSystem("Type `/help` for commands!")

	dom.sendbutton.onclick = send
}
