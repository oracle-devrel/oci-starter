// -- Import  --------------------------------------------------------------- 

import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
mermaid.initialize({ startOnLoad: false });

// -- Variables ----------------------------------------------------------------- 

let BASE_URL = '/app';
let currentBackend = 'LangGraph';
const backends = [
    { name: 'LangGraph', baseUrl: '/app' }
];
let currentAgent = 'agent';
let currentUser = 'customer';
const users = ['employee', 'customer'];

let thread_id = null;
let last_message_id = -1;
const messagesEl = document.getElementById('messages');
const chatForm = document.getElementById('chat-form');
const chatInput = document.getElementById('chat-input');
const spinnerContainer = document.getElementById('spinner-container');
const micButton = document.getElementById('mic-button');

// See https://docs.oracle.com/en-us/iaas/Content/APIGateway/Tasks/apigatewayusingjwttokens.htm#Using_JSON_Web_Tokens_JWTs_to_Add_Authentication_and_Authorization_to_API_Deployments__section_csrf_protection
let csrfToken = "";

// -- Code -----------------------------------------------------------------


// -- ChatInput ---
// UX: Enter submits, Shift+Enter inserts newline.
chatInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        chatForm.requestSubmit();
    }
});
function autoGrowTextarea() {
    if (!chatInput) return;
    chatInput.style.height = 'auto';
    chatInput.style.height = `${chatInput.scrollHeight-36}px`;
}
chatInput.addEventListener('input', autoGrowTextarea);


// -- Rendering ---

// Utility: safely parse JSON
function safeParse(json) {
    try { return JSON.parse(json); }
    catch (e) { return {}; }
}

async function renderContent(input) 
{
    const MERMAID_FENCE_RE = /```(?:\s*)mermaid\s*\n([\s\S]*?)\n```/i;
    if (MERMAID_FENCE_RE.test(input)) {
        const m = input.match(/```mermaid\s*([\s\S]*?)\s*```/i);
        const m2 = m[1].trim();
        const value = await mermaid.render("diagram",m2);
        return value.svg;
    } else {
       return renderMarkdown(input);
    }
}

function renderMarkdown(md) {
    return marked.parse(md || "");
}
// Add or move spinner below last message (show while waiting for SSE)
function showSpinner() {
    spinnerContainer.innerHTML = `<div id="spinner"><div class="pulse-dot"></div></div>`;
    scrollToBottom();
}
// Remove spinner (when SSE is done)
function hideSpinner() {
    spinnerContainer.innerHTML = '';
}

function scrollToBottom() {
    // Scroll so the anchor div is visible
    document.getElementById('spinner-container').scrollIntoView({ behavior: "smooth" });
}

function renderJsTable(data) {
    if (!Array.isArray(data) || data.length === 0) return "<em>(No data)</em>";

    const headers = Object.keys(data[0]);
    let html = '<table>';
    html += '<thead><tr>' + headers.map(h => `<th>${h}</th>`).join('') + '</tr></thead>';
    html += '<tbody>';
    for (const row of data) {
        html += '<tr>';
        for (let h of headers) {
            let value = row[h];
            if (typeof value === 'string' && /^https?:\/\//.test(value)) {
                html += `<td><a href="${value}" target="_blank">URL</a></td>`;
            } else {
                html += `<td>${value}</td>`;
            }
        }
        html += '</tr>';
    }
    html += '</tbody></table>';
    return html;
}

async function renderMessage(msgObj) {
    const el = document.createElement('div');
    el.classList.add('message');
    el.classList.add(msgObj.type || 'ai');
    let innerHTML = '';
    // Human message
    if (msgObj.type === 'human') {
        innerHTML = `<div class="bubble"><div class="meta">You</div>${renderMarkdown(msgObj.content)}</div>`;
        } else if (msgObj.type === 'ai') {
            if (msgObj.content) {
                innerHTML = `<div class="bubble"><div class="meta">AI</div>${await renderContent(msgObj.content)}</div>`;
            } else if (msgObj.tool_calls && msgObj.tool_calls.length > 0) {
                const toolNames = msgObj.tool_calls.map(t => t.name).join(' - ');
                let bubble = `<div class="bubble"><div class="meta">Tool Calls - ${toolNames}</div>`;
                let tools = msgObj.tool_calls.map(t =>
                    `<tr><td>${t.name}</td><td>${JSON.stringify(t.args)}</td></tr>`
                ).join('');
                bubble += `<table class='tools-table'><thead><tr><th>Name</th><th>Arguments</th></tr></thead><tbody>${tools}</tbody></table>`;
                innerHTML = bubble;
            }
        } else if (msgObj.type === 'tool') {
        let data = msgObj.artifact?.structured_content ?? {};
        let bubble = "<div class='bubble'><div class='meta'>Tool - " + msgObj.name + "</div>";
        if (data?.response) {
            bubble += renderMarkdown(data.response);
        }
        if (data?.result) {
            bubble += renderJsTable(data.result);
        }
        bubble += "</div>";
        innerHTML = bubble;
    }
    el.innerHTML = innerHTML;
    messagesEl.appendChild(el);
    scrollToBottom();
}

function startSSE(reqBody, onMessage, onDone) {
    showSpinner();
    const url = `${BASE_URL}/threads/${thread_id}/runs/stream`;

    // SSE with POST is non-standard. We'll use fetch + stream reader
    fetch(url, {
        method: "POST",
        headers: { 
            "Content-Type": "application/json", 
            "Authorization": `User ${currentUser}`,
            "X-CSRF-TOKEN": csrfToken
        },
        credentials: 'include',
        body: JSON.stringify(reqBody)
    }).then(async response => {
        if (!response.ok || !response.body) {
            hideSpinner();
            onMessage({ type: "ai", content: "Network/server error." });
            if (onDone) onDone();
            return;
        }
        const reader = response.body.getReader();
        let pending = '';
        while (true) {
            let { done, value } = await reader.read();
            if (done) break;
            let chunk = new TextDecoder().decode(value);
            pending += chunk;
            // Handle SSE events: lines like `data: {...}\n\n`
            let parts = pending.split('\r\n\r\n');
            pending = parts.pop(); // Last piece (possibly incomplete)
            for (let part of parts) {
                let lines = part.split('\r\n');
                for (let line of lines) {
                    let match = line.match(/^data:\s*(.*)$/m);
                    if (match) {
                        let data = match[1];
                        let json = safeParse(data);
                        if (json?.messages) {
                            for (const id in json.messages) {
                                let nid = Number(id)
                                if (nid > last_message_id) {
                                    onMessage(json.messages[id]);
                                    last_message_id = nid
                                }
                            }
                        }
                    }
                }
            }
        }
        hideSpinner();
        if (onDone) onDone();
    }).catch(e => {
        hideSpinner();
        onMessage({ type: "ai", content: "Connection error." });
        if (onDone) onDone();
    });
}

async function getThreadId() {
    const url = `${BASE_URL}/threads`;
    try {
        const resp = await fetch(url, {
            method: "POST",
            body: "{}",
            headers: { 
                "Authorization": `User ${currentUser}`,
                "X-CSRF-TOKEN": csrfToken
            },
            credentials: 'include'
        });
        const data = await resp.json();
        return data.thread_id;
    } catch (e) {
        alert("Failed to connect to chat server.");
    }
}

async function addMessage(msgObj) {
    renderMessage(msgObj);
}

chatForm.addEventListener('submit', async function (e) {
    e.preventDefault();
    const msg = chatInput.value.trim();
    if (!msg) return;

    addMessage({ type: "human", content: msg });
    chatInput.value = '';

    const reqBody = {
        "assistant_id": "agent",
        input: { messages: [{ role: "human", content: msg }] }
    };

    startSSE(reqBody, respMsg => {
        try {
            if (!respMsg) return;
            // Filter out empty events
            if ("type" in respMsg && respMsg.type == "human") {
                console.log("Skip type=human");
            } else if ("content" in respMsg && (respMsg.content || (Array.isArray(respMsg.content) && respMsg.content.length))) {
                addMessage(respMsg);
            } else if (respMsg.tool_calls) {
                // Sometimes tool_calls is the main payload
                addMessage(respMsg);
            } else {
                // Sometimes tool_calls is the main payload
                addMessage(respMsg);
            }
        } catch (e) {
            console.log("Failed to add message:" + e);
        }
    });
});

// -- Reset Button --------------------------------------------------

const reset = document.getElementById('reset');
reset.addEventListener('click', () => {
    window.location.reload();
});

// -- Hamburger menu logic ------------------------------------------
const hamburger = document.querySelector('.hamburger');
const nav = document.getElementById('agentMenu');
hamburger.addEventListener('click', () => {
    const isOpen = nav.classList.toggle('open');
    hamburger.setAttribute('aria-expanded', isOpen);
});
document.addEventListener('keydown', function (e) {
    if (e.key === "Escape") {
        nav.classList.remove('open');
        hamburger.setAttribute('aria-expanded', 'false');
    }
});

// Users section
function renderBackendList() {
    const backendList = document.getElementById('backendList');
    backendList.innerHTML = '';
    backends.forEach(backend => {
        const li = document.createElement('li');
        li.textContent = backend.name;
        li.tabIndex = 0;
        li.setAttribute('aria-current', backend.name === currentBackend ? 'true' : 'false');
        li.addEventListener('click', () => setCurrentBackend(backend.name));
        backendList.appendChild(li);
    });
}

function renderUserList() {
    const userList = document.getElementById('userList');
    userList.innerHTML = '';
    if( csrfToken=="" ) {
        users.forEach(user => {
            const li = document.createElement('li');
            li.textContent = user;
            li.tabIndex = 0;
            li.setAttribute('aria-current', user === currentUser ? 'true' : 'false');
            li.addEventListener('click', () => setCurrentUser(user));
            userList.appendChild(li);
        });
    } else {
        const li = document.createElement('li');
        li.textContent = "Logout";
        li.addEventListener('click', () => { 
            /* window.location.href = '/openid/logout?postLogoutUrl='+window.location.origin+'/openid/chat.html'; */
            window.location.href = '/openid/logout?postLogoutUrl=https://www.oracle.com';
        });
        userList.appendChild(li);
    }
}

// Agents section
async function fetchAgents() {
    const response = await fetch(`${BASE_URL}/assistants/search`, {
        method: 'POST',
        headers: {
            "Content-Type": "application/json",
            "Authorization": `User ${currentUser}`,
            "X-CSRF-TOKEN": csrfToken
        },
        credentials: 'include',
        body: JSON.stringify({
            sort_by: 'assistant_id',
            sort_order: 'asc'
        })
    });
    if (!response.ok) throw new Error('Failed to fetch agents');
    return await response.json();
}

function renderAgentList(agents) {
    const agentList = document.getElementById('agentList');
    agentList.innerHTML = '';
    agents.forEach(agent => {
        const li = document.createElement('li');
        li.textContent = agent.graph_id;
        li.tabIndex = 0;
        li.setAttribute('aria-current', agent.graph_id === currentAgent ? 'true' : 'false');
        li.addEventListener('click', () => setCurrentAgent(agent.graph_id));
        agentList.appendChild(li);
    });
}

// Updating display
function updateDisplay() {
    document.getElementById('currentDisplay').textContent = `Backend: ${currentBackend} - Agent: ${currentAgent} - User: ${currentUser}`;
}

async function setCurrentBackend(backendName) {
    currentBackend = backendName;
    const backend = backends.find(b => b.name === backendName);
    if (backend) {
        BASE_URL = backend.baseUrl;
    }

    messagesEl.innerHTML = '';
    thread_id = await getThreadId();
    last_message_id = 0;
    if (!thread_id) {
        messagesEl.innerHTML = '<div class="message ai">Error: could not get thread_id from backend.</div>';
        chatInput.disabled = true;
    } else {
        chatInput.disabled = false;
    }

    updateDisplay();
    nav.classList.remove('open');
    hamburger.setAttribute('aria-expanded', 'false');
    fetchAgents().then(renderAgentList);
    renderUserList();
    renderBackendList();
}

function setCurrentAgent(agentName) {
    currentAgent = agentName;
    updateDisplay();
    nav.classList.remove('open');
    hamburger.setAttribute('aria-expanded', 'false');
    // Re-render to update aria-current
    fetchAgents().then(renderAgentList);
    renderUserList();
}
function setCurrentUser(user) {
    currentUser = user;
    updateDisplay();
    nav.classList.remove('open');
    hamburger.setAttribute('aria-expanded', 'false');
    // Re-render to update aria-current
    fetchAgents().then(renderAgentList);
    renderUserList();
}

async function fetchUserInfo() {
    BASE_URL = '/openid/server';
    const response = await fetch('/openid/userinfo', {
        method: 'GET',
        credentials: 'include'
    });
    if (!response.ok) throw new Error('Failed to fetch UserInfo');
    csrfToken = response.headers.get('x-csrf-token');
    console.log( `Found x-csrf-token ${csrfToken}` )    
    let data = await response.json();
    currentUser = data.sub;
    updateDisplay();
}

let recognition = null;

function initRecognition() {
    if (!('SpeechRecognition' in window) && !('webkitSpeechRecognition' in window)) {
        micButton.style.display = 'none';
        return;
    }

    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    recognition = new SpeechRecognition();
    recognition.continuous = false;
    recognition.interimResults = false;
    recognition.lang = 'en-US';

    recognition.onstart = () => {
        micButton.classList.add('recording');
        chatInput.placeholder = 'Listening...';
    };

    recognition.onresult = (event) => {
        const transcript = Array.from(event.results)
            .map(result => result[0].transcript)
            .join('');
        chatInput.value = transcript;
        chatInput.focus();
    };

    recognition.onerror = (event) => {
        console.error('Speech recognition error:', event.error);
        micButton.classList.remove('recording');
        chatInput.placeholder = 'Type your message...';
    };

    recognition.onend = () => {
        micButton.classList.remove('recording');
        chatInput.placeholder = 'Type your message...';
    };
}

micButton.addEventListener('click', (e) => {
    e.preventDefault();
    if (recognition) {
        recognition.start();
    }
});

// On page load
// If the URL is in openid, get the userinfo from IDCS via APIGW


(async function init() {
    if (window.location.pathname.startsWith('/openid')) {
        await fetchUserInfo(); 
    }            
    console.log( `before init x-csrf-token ${csrfToken}` );
    thread_id = await getThreadId();
    last_message_id = 0;
    if (!thread_id) {
        messagesEl.innerHTML = '<div class="message ai">Error: could not get thread_id from backend.</div>';
        chatInput.disabled = true;
    }
    initRecognition();
    renderBackendList();
    renderUserList();
    fetchAgents()
        .then(renderAgentList)
        .catch(error => alert("Could not load agents: " + error));
    updateDisplay();
})();

