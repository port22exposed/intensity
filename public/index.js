import {
	updateScrollPosition,
	createMessageElement,
	isValidUsername,
	sendSystem,
} from "./utility.js"
import { handleCommand } from "./commands.js"

let websocket

function exit() {
	window.location.replace("https://google.com");
}

export function getWebSocket() {
	return websocket
}

function promptForUsername() {
	const username = prompt(
		"Enter a username to join!\n\nlength : 3-20, charset: alphanumeric + `_` + `-`, cannot be already in use (case insensitive detection)\n\n[WARNING]: The username is shared with the server unencrypted!",
		Array.from(crypto.getRandomValues(new Uint8Array(2)), b => b.toString(16).padStart(2, '0')).join('')
	)

	if (!isValidUsername(username)) {
		alert("Username is invalid, please re-read the requirements and try again!")
		return promptForUsername()
	}

	return username
}

window.onload = () => {
	const usercount = document.getElementById("usercount")
	const messagelist = document.getElementById("messagelist")
	const messagebox = document.getElementById("message")
	const sendbutton = document.getElementById("send")

	function send() {
		const message = messagebox.value
		messagelist.appendChild(createMessageElement(username, messagebox.value))
		messagelist.scrollTop = messagelist.scrollHeight
		updateScrollPosition()
		if (message.startsWith("/")) {
			const args = message.split(" ")
			const command = args[0].substring(1)
			args.shift()
			handleCommand(command, args)
		} else {
			websocket.send(messagebox.value)
		}
		messagebox.value = ""
	}

	messagebox.addEventListener("keydown", (e) => {
		if (e.key === "Enter") {
			send()
		}
	})

	const username = promptForUsername()

	document.getElementById("name").innerText = username

	websocket = new WebSocket(
		`${window.location.protocol === "https:" ? "wss:" : "ws:"}//${
			window.location.host
		}/?username=${username}`
	)

	websocket.onerror = exit
	websocket.onclose = exit
	websocket.onmessage = function (e) {
		const packet = JSON.parse(e.data)
		const data = packet.data
		if (packet.type == "update") {
			if (data.userCount) {
				usercount.innerText = data.userCount
			}
		} else if (packet.type == "systemMessage") {
			sendSystem(data.message)
		}
	}

	messagebox.focus()

	sendSystem("Type `/help` for commands!")
	
	sendbutton.onclick = send
}
