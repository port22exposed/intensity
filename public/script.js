function exit() {
	window.location.href = "about:blank"
}

function is_valid_username(username) {
	let valid = username != null
	const len = username.length

	if (len < 3 || len > 20) {
		valid = false
	}

	if (!/^[a-zA-Z0-9]+$/.test(username)) {
		valid = false
	}

	return valid
}

function createMessage(user, text, className) {
	const message = document.createElement("div")
	message.className = className || "message"
	message.innerHTML = `<span class="name">${user}</span>${text}`
	return message
}

function createSystemMessage(text) {
	const message = document.createElement("div")
	message.className = "message info"
	message.innerText = text
	return message
}

window.onload = () => {
	const username = prompt("Enter a username to join!", "user")

	if (!is_valid_username(username)) {
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
		messagelist.appendChild(createSystemMessage(text))
		updateScrollPosition()
	}

	sendSystem("Type `/help` for commands!")

	websocket.onmessage = function (e) {
		const packet = JSON.parse(e.data)
		if (packet.type == "update") {
			const data = packet.data
			if (data.userCount) {
				usercount.innerText = data.userCount
			}
			if (data.userJoining) {
				sendSystem(`${data.userJoining} has joined the chat.`)
			}
			if (data.userLeaving) {
				sendSystem(`${data.userLeaving} has left the chat.`)
			}
		}
	}

	function send() {
		const message = messagebox.value
		if (message.startsWith("/")) {
			const args = message.split(" ")
			const command = args[0].substring(1)
			if (command == "help") {
				window.open("/help.txt").focus();
			}
		}
		messagelist.appendChild(createMessage(username, messagebox.value))
		messagebox.value = ""
		messagelist.scrollTop = messagelist.scrollHeight
		updateScrollPosition()
	}

	messagebox.addEventListener("keydown", (e) => {
		if (e.key === "Enter") {
			send()
		}
	})

	sendbutton.onclick = send;
}
