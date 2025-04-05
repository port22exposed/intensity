import { sendSystem } from "./utility.js"
import * as dom from "./dom.js"

export function onmessage(e) {
	const packet = JSON.parse(e.data)
	const data = packet.data
	console.log(e)
	if (packet.type == "pong") {
		if (data.username) {
			dom.clientUsername.innerText = data.username
		}
	} else if (packet.type == "userCountChange") {
		if (data.userCount) {
			if (data.userCount == "1") {
				dom.usercount.innerText = `${data.userCount} user`
			} else {
				dom.usercount.innerText = `${data.userCount} users`
			}
		}
	} else if (packet.type == "systemMessage") {
		sendSystem(data.message)
	}
}
