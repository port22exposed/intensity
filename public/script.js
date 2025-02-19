function is_valid_username (username) {
	let valid = username != null;
	const len = username.length;

	if (len < 3 || len > 20) {
		valid = false;
	}

	if (!(/^[a-zA-Z0-9]+$/.test(username))) {
		valid = false;
	}
	
	return valid;
}

function createMessage(user, text) {
	const message = document.createElement("div");
	message.className = "message";
	message.innerHTML = `<span class="name">${user}</span>${text}`;
	return message;
}

setTimeout(() => {
	const username = prompt("Enter a username to join!", "user");
	
	if (!is_valid_username(username)) {
		window.location.reload();
	}
	
	document.getElementById("name").innerText = username;
	
	const websocket = new WebSocket(`${window.location.protocol === "https:" ? "wss:" : "ws:"}//${window.location.host}/?username=${username}`);
	
	function send() {
		messagelist.appendChild(createMessage(username, messagebox.value));
		messagebox.value = "";
		messagelist.scrollTop = messagelist.scrollHeight;
	}

	const messagelist = document.getElementById("messagelist");
	const messagebox = document.getElementById("message");
	const sendbutton = document.getElementById("send");
	
	messagebox.addEventListener("keydown", (e) => {
		if (e.key === "Enter") {
			send()
		}
	});
	
	sendbutton.onclick = () => {
		send()
	}
	
	const observer = new MutationObserver(() => {
		if (messagelist.scrollTop + messagelist.clientHeight >= messagelist.scrollHeight - messagelist.lastChild.clientHeight*2) {
			messagelist.scrollTop = messagelist.scrollHeight;
		}
	});
	
	
	const config = { childList: true };
	observer.observe(messagelist, config);
}, 50)