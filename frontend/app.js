const API_URL = "/chat";
const sessionId = `sess_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;

const chatWindow = document.getElementById("chat-window");
const chatForm = document.getElementById("chat-form");
const messageInput = document.getElementById("message-input");

function addMessage(role, text) {
  const bubble = document.createElement("div");
  bubble.className = `bubble ${role}`;
  bubble.textContent = text;
  chatWindow.appendChild(bubble);
  chatWindow.scrollTop = chatWindow.scrollHeight;
}

async function sendMessage(message) {
  const res = await fetch(API_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      session_id: sessionId,
      message,
    }),
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.detail || "Request failed");
  }
  return data.response || "No response available.";
}

chatForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const message = messageInput.value.trim();
  if (!message) return;

  addMessage("user", message);
  messageInput.value = "";
  messageInput.disabled = true;

  try {
    const reply = await sendMessage(message);
    addMessage("assistant", reply);
  } catch (err) {
    addMessage("assistant", `Error: ${err.message}`);
  } finally {
    messageInput.disabled = false;
    messageInput.focus();
  }
});

addMessage("assistant", "Hello. How can I help with your health concern today?");
