import * as dom from './dom.js'

const messagelist = document.getElementById("messagelist")

export function updateScrollPosition () {
	if (
		messagelist.scrollTop + messagelist.clientHeight >=
		messagelist.scrollHeight - messagelist.lastChild.clientHeight * 2
	) {
		messagelist.scrollTop = messagelist.scrollHeight
	}
}

export function createMessageElement(user, text, className) {
	const message = document.createElement("div")
	message.className = className || "message"
	const name = document.createElement("span")
	name.className = "name"
	name.innerText = `${user} `
	const textSpan = document.createElement("span")
	textSpan.innerText = text
	message.appendChild(name)
	message.appendChild(textSpan)
	return message
}

export function createSystemMessageElement(text) {
	return createMessageElement("[SYSTEM]:", text, "message info")
}

export function sendSystem(text) {
	dom.messagelist.appendChild(createSystemMessageElement(text))
	updateScrollPosition()
}