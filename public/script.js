function createMessage(user, text) {
	const message = document.createElement("div");
	message.className = "message";
	message.innerHTML = `<span class="name">${user}</span>${text}`;
	return message;

}

document.getElementById("send").onclick = () => {
	
}