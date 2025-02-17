function createMessage(user, text) {
	const message = document.createElement("div");
	message.className = "message";
	message.innerHTML = `<span class="name">${user}</span>${text}`;
	return message;
}

const messagelist = document.getElementById("messagelist");
const messagebox = document.getElementById("message");
const sendbutton = document.getElementById("send");

function send() {
	messagelist.appendChild(createMessage("User1", messagebox.value));
	messagebox.value = "";
	messagelist.scrollTop = messagelist.scrollHeight;
}

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