import {
	updateScrollPosition,
	createMessageElement,
	sendSystem,
} from "./utility.js"
import { handleCommand } from "./commands.js"
import { onmessage } from "./packets.js"
import { publicKey } from "./crypto.js"
import * as dom from "./dom.js"

let websocket

function exit() {
	// window.location.replace("https://example.com")
	// this sucks for debugging
}

export function getWebSocket() {
	return websocket
}

window.onload = async () => {
	function send() {
		const message = dom.messagebox.value
		dom.messagelist.appendChild(
			createMessageElement(dom.clientUsername.innerText, dom.messagebox.value)
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

	websocket = new WebSocket(
		`${window.location.protocol === "https:" ? "wss:" : "ws:"}//${
			window.location.host
		}/?auth=${joinCode}`
	)

	websocket.onmessage = onmessage
	websocket.onerror = exit
	websocket.onclose = exit

	dom.messagebox.focus()

	websocket.send(
		JSON.stringify({
			type: "keyExchange",
			stage: "publicKeyDisclosure",
			key: publicKey,
		})
	)

	sendSystem("Type `/help` for commands!")

	dom.sendbutton.onclick = send
}
