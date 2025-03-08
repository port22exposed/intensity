import { sendSystem } from "./utility.js"
import * as dom from './dom.js'

export function onmessage(e) {
	const packet = JSON.parse(e.data)
	const data = packet.data
	if (packet.type == "update") {
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
