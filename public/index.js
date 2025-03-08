import {
	updateScrollPosition,
	createMessageElement,
	isValidUsername,
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

function promptForUsername() {
	const username = prompt(
		"Enter a username to join!\n\nlength : 3-20, charset: alphanumeric + `_` + `-`, cannot be already in use (case insensitive detection)\n\n[WARNING]: The username is shared with the server unencrypted!",
		Array.from(crypto.getRandomValues(new Uint8Array(2)), (b) =>
			b.toString(16).padStart(2, "0")
		).join("")
	)

	if (!isValidUsername(username)) {
		alert("Username is invalid, please re-read the requirements and try again!")
		return promptForUsername()
	}

	return username
}

window.onload = () => {
	function send() {
		const message = dom.messagebox.value
		dom.messagelist.appendChild(createMessageElement(username, dom.messagebox.value))
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

	const username = promptForUsername()

	dom.clientUsername.innerText = username

	websocket = new WebSocket(
		`${window.location.protocol === "https:" ? "wss:" : "ws:"}//${
			window.location.host
		}/?username=${username}`
	)

	websocket.onerror = exit
	websocket.onclose = exit
	websocket.onmessage = onmessage

	dom.messagebox.focus()

	sendSystem("Type `/help` for commands!")

	dom.sendbutton.onclick = send
}
