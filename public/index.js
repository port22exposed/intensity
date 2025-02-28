import { updateScrollPosition, createMessageElement, isValidUsername, sendSystem } from "./utility.js"
import { handleCommand } from "./commands.js"

let websocket

function exit() {
	window.location.reload()
}

export function getWebSocket () {
	return websocket
}

window.onload = () => {
	const username = prompt("Enter a username to join!\n\n[WARNING]: The username is shared with the server unencrypted!", "user")

	if (!isValidUsername(username)) {
		window.location.reload()
	}

	document.getElementById("name").innerText = username

	websocket = new WebSocket(
		`${window.location.protocol === "https:" ? "wss:" : "ws:"}//${
			window.location.host
		}/?username=${username}`
	)

	websocket.onerror = exit
	websocket.onclose = exit

	const usercount = document.getElementById("usercount")
	const messagelist = document.getElementById("messagelist")
	const messagebox = document.getElementById("message")
	const sendbutton = document.getElementById("send")

	messagebox.focus()

	sendSystem("Type `/help` for commands!")

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

	sendbutton.onclick = send;
}
