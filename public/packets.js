import { sendSystem } from "./utility.js"

export function onmessage(e) {
	const packet = JSON.parse(e.data)
	const data = packet.data
	if (packet.type == "update") {
		if (data.userCount) {
			console.log(data.userCount)
			if (data.userCount == "1") {
				usercount.innerText = `${data.userCount} user`
			} else {
				usercount.innerText = `${data.userCount} users`
			}
		}
	} else if (packet.type == "systemMessage") {
		sendSystem(data.message)
	}
}
