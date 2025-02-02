import { serve, file } from "bun";

const pendingUsers = new Map();
const activeUsers = new Map();

const server = serve({
  port: 3000,
  fetch(req, server) {
    // Serve the HTML file for the root URL
    if (req.url.endsWith("/")) {
      return new Response(file("index.html"));
    }

    // Upgrade the connection to WebSocket if possible
    if (server.upgrade(req, { data: })) {
      return;
    }

    return new Response("Upgrade failed", { status: 400 });
  },
  websocket: {
    open(ws) {
      const username = new URL(ws.url).searchParams.get("username");
      if (!username) {
        ws.close(1000, "Username is required");
        return;
      }
      pendingUsers.set(ws, username);
      notifyHost(ws, username);
    },
    message(ws, message) {
      if (activeUsers.has(ws)) {
        const username = activeUsers.get(ws);
        broadcast(`${username}: ${message}`);
      }
    },
    close(ws) {
      const username = activeUsers.get(ws);
      if (username) {
        activeUsers.delete(ws);
        broadcast(`${username} has left the chat.`);
      }
      pendingUsers.delete(ws);
    },
  },
});

function notifyHost(ws, username) {
  console.log(`New user ${username} wants to join. Accept? (y/n)`);
  process.stdin.once("data", (data) => {
    const response = data.toString().trim().toLowerCase();
    if (response === 'y') {
      acceptUser(ws, username);
    } else {
      rejectUser(ws, username);
    }
  });
}

function acceptUser(ws, username) {
  pendingUsers.delete(ws);
  activeUsers.set(ws, username);
  ws.send(`Welcome to the chat, ${username}!`);
  broadcast(`${username} has joined the chat.`);
}

function rejectUser(ws, username) {
  pendingUsers.delete(ws);
  ws.close(1000, "Your request to join was rejected by the host.");
}

function broadcast(message) {
  for (const [ws] of activeUsers) {
    ws.send(message);
  }
}

console.log(`Chat server is running on http://localhost:${server.port}`);
