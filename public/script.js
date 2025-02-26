import { createMessageElement, createSystemMessageElement, isValidUsername } from "./utility"

function exit() {
	window.location.reload()
}

window.onload = () => {
	const username = prompt("Enter a username to join!\n\n[WARNING]: The username is shared with the server unencrypted!", "user")

	if (!isValidUsername(username)) {
		window.location.reload()
	}

	document.getElementById("name").innerText = username

	var websocket = new WebSocket(
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

	function updateScrollPosition () {
		if (
			messagelist.scrollTop + messagelist.clientHeight >=
			messagelist.scrollHeight - messagelist.lastChild.clientHeight * 2
		) {
			messagelist.scrollTop = messagelist.scrollHeight
		}
	}

	function sendSystem(text) {
		messagelist.appendChild(createSystemMessageElement(text))
		updateScrollPosition()
	}

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
		if (message.startsWith("/")) {
			const args = message.split(" ")
			const command = args[0].substring(1)
			if (command == "help") {
				sendSystem(`Intensity Chat - Commands List

EVERYONE:

/help - sends you here...
/host - displays the host in chat to you
/status - displays your current status in chat to you

OPERATOR:

/decline <username> - declines a user's entry into the group chat
/accept <username> - accepts a user's entry into the group chat
/kick <username> - kicks a user from the group chat and bans their IP address

OWNER:

/op <username> - gives the user operator status
/transfer <username> - transfers ownership of the group chat to another member`)
			}
		} else {
			messagelist.appendChild(createMessageElement(username, messagebox.value))
			messagelist.scrollTop = messagelist.scrollHeight
			updateScrollPosition()
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
