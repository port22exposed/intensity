export function createMessageElement(user, text, className) {
	const message = document.createElement("div")
	message.className = className || "message"
	message.innerHTML = `<span class="name">${user}</span>${text}`
	return message
}

export function createSystemMessageElement(text) {
	const message = document.createElement("div")
	message.className = "message info"
	message.innerText = text
	return message
}

export function isValidUsername(username) {
	let valid = username != null
	const len = username.length

	if (len <= 3 || len > 20) {
		valid = false
	}

	if (!/^[a-zA-Z0-9]+$/.test(username)) {
		valid = false
	}

	return valid
}