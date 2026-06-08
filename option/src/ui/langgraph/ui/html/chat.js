// -- Import  --------------------------------------------------------------- 

import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
mermaid.initialize({ startOnLoad: false });

// -- Variables ----------------------------------------------------------------- 

let BASE_URL = 'app';
let currentBackend = 'LangGraph';
const backends = [
    { name: 'LangGraph', baseUrl: 'app' }
];
let currentAgent = 'agent';
let currentUser = 'customer';
const users = ['employee', 'customer'];

let thread_id = null;
let last_message_id = -1;
const messagesEl = document.getElementById('messages');
const chatStage = document.querySelector('.chat-stage');
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
    const maxHeight = Number.parseFloat(getComputedStyle(chatInput).maxHeight);
    chatInput.style.height = 'auto';
    chatInput.style.height = `${Math.min(chatInput.scrollHeight, maxHeight || chatInput.scrollHeight)}px`;
    chatInput.style.overflowY = maxHeight && chatInput.scrollHeight > maxHeight ? 'auto' : 'hidden';
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

function escapeHtml(value) {
    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

let toolDialog = null;

function ensureToolDialog() {
    if (toolDialog) return toolDialog;

    toolDialog = document.createElement('dialog');
    toolDialog.className = 'tool-dialog';
    toolDialog.innerHTML = `
        <form method="dialog" class="tool-dialog-panel">
            <button type="submit" class="tool-dialog-close" aria-label="Close dialog" title="Close">&times;</button>
            <div class="tool-dialog-body"></div>
        </form>
    `;
    toolDialog.addEventListener('click', (event) => {
        if (event.target === toolDialog) {
            toolDialog.close();
        }
    });
    document.body.appendChild(toolDialog);
    return toolDialog;
}

function openToolDialog(bodyHtml) {
    const dialog = ensureToolDialog();
    dialog.querySelector('.tool-dialog-body').innerHTML = bodyHtml;
    if (dialog.open) {
        dialog.close();
    }
    if (typeof dialog.showModal === 'function') {
        dialog.showModal();
    } else {
        dialog.setAttribute('open', '');
    }
}

function renderJsonBody(value, emptyText) {
    if (value === undefined || value === null || value === '') {
        return `<em>${emptyText}</em>`;
    }
    if (typeof value === 'string') {
        return `<pre>${escapeHtml(value)}</pre>`;
    }
    const json = JSON.stringify(value, null, 2);
    return `<pre>${escapeHtml(json ?? String(value))}</pre>`;
}

function renderToolCallBody(toolCall) {
    return renderJsonBody(toolCall.args, '(No arguments)');
}

function renderToolResponseBody(msgObj) {
    const data = msgObj.artifact?.structured_content ?? {};
    const body = [];

    if (data?.response) {
        body.push(renderMarkdown(data.response));
    }
    if (data?.result) {
        body.push(renderJsTable(data.result));
    }
    if (body.length > 0) {
        return body.join('');
    }
    if (msgObj.content) {
        return renderMarkdown(msgObj.content);
    }
    if (Object.keys(data).length === 0) {
        return '<em>(No response body)</em>';
    }
    return renderJsonBody(data, '(No response body)');
}

function createToolButton(label, bodyHtml) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'tool-event-button';
    button.textContent = label;
    button.addEventListener('click', () => openToolDialog(bodyHtml));
    return button;
}

function renderToolEventLine(el, buttons) {
    el.classList.add('tool-event');
    const line = document.createElement('div');
    line.className = 'tool-event-line';
    buttons.forEach(button => line.appendChild(button));
    el.appendChild(line);
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
    if (!chatStage) return;

    const scroll = () => {
        chatStage.scrollTop = chatStage.scrollHeight;
    };

    scroll();
    requestAnimationFrame(scroll);
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
    const msgType = msgObj.type || 'ai';
    el.classList.add('message');
    el.classList.add(msgType);
    let innerHTML = '';
    // Human message
    if (msgType === 'human') {
        innerHTML = `<div class="bubble"><div class="meta">You</div>${renderMarkdown(msgObj.content)}</div>`;
    } else if (msgType === 'ai') {
        if (msgObj.content) {
            innerHTML = `<div class="bubble"><div class="meta">AI</div>${await renderContent(msgObj.content)}</div>`;
        } else if (msgObj.tool_calls && msgObj.tool_calls.length > 0) {
            const buttons = msgObj.tool_calls.map(toolCall =>
                createToolButton(`Call: ${toolCall.name || 'tool'}`, renderToolCallBody(toolCall))
            );
            renderToolEventLine(el, buttons);
        }
    } else if (msgType === 'tool') {
        renderToolEventLine(el, [
            createToolButton(`Response: ${msgObj.name || 'tool'}`, renderToolResponseBody(msgObj))
        ]);
    }
    if (innerHTML) {
        el.innerHTML = innerHTML;
    }
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
                        console.log("SSE data:", json); // Debug log
                        if (json?.messages) {
                            for (const id in json.messages) {
                                let nid = Number(id)
                                if (nid > last_message_id) {
                                    onMessage(json.messages[id]);
                                    last_message_id = nid
                                }
                            }
                        } else if (json?.error || json?.ToolException) {
                            // Handle tool errors or LangGraph errors
                            let errorMsg = json.error || json.ToolException || json.message || "Unknown error occurred";
                            if (json.status === "tool_error") {
                                errorMsg = `Tool Error: ${errorMsg}. Please check the logs for details or try rephrasing your request.`;
                            } else {
                                errorMsg = `Error: ${errorMsg}. Please check the logs.`;
                            }
                            onMessage({
                                type: "ai",
                                content: `**Error occurred** - ${errorMsg}`
                            });
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
        if (!resp.ok) {
            throw new Error(`Backend responded with ${resp.status}`);
        }
        const contentType = resp.headers.get('content-type') || '';
        if (!contentType.includes('application/json')) {
            throw new Error('Backend did not return JSON');
        }
        const data = await resp.json();
        return data.thread_id;
    } catch (e) {
        console.warn("Failed to connect to chat server.", e);
    }
}

async function addMessage(msgObj) {
    await renderMessage(msgObj);
}

chatForm.addEventListener('submit', async function (e) {
    e.preventDefault();
    const msg = chatInput.value.trim();
    if (!msg) return;

    addMessage({ type: "human", content: msg });
    chatInput.value = '';
    autoGrowTextarea();

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

// -- Optional settings menu logic -----------------------------------
const hamburger = document.querySelector('.hamburger');
const nav = document.getElementById('agentMenu');

function closeSettingsPanel() {
    if (nav) {
        nav.classList.remove('open');
    }
    if (hamburger) {
        hamburger.setAttribute('aria-expanded', 'false');
    }
}

if (hamburger && nav) {
    hamburger.addEventListener('click', () => {
        const isOpen = nav.classList.toggle('open');
        hamburger.setAttribute('aria-expanded', isOpen);
    });
    document.addEventListener('keydown', function (e) {
        if (e.key === "Escape") {
            closeSettingsPanel();
        }
    });
}

// Users section
function renderBackendList() {
    const backendList = document.getElementById('backendList');
    if (!backendList) return;
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
    if (!userList) return;
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
    if (!agentList) return;
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
    const currentDisplay = document.getElementById('currentDisplay');
    if (currentDisplay) {
        currentDisplay.textContent = `Backend: ${currentBackend} - Agent: ${currentAgent} - User: ${currentUser}`;
    }
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
        messagesEl.innerHTML = '';
        await addMessage({ type: "ai", content: "The concierge service is currently unavailable." });
        chatInput.disabled = true;
    } else {
        chatInput.disabled = false;
    }

    updateDisplay();
    closeSettingsPanel();
    if (document.getElementById('agentList')) {
        fetchAgents().then(renderAgentList);
    }
    renderUserList();
    renderBackendList();
}

function setCurrentAgent(agentName) {
    currentAgent = agentName;
    updateDisplay();
    closeSettingsPanel();
    // Re-render to update aria-current
    if (document.getElementById('agentList')) {
        fetchAgents().then(renderAgentList);
    }
    renderUserList();
}
function setCurrentUser(user) {
    currentUser = user;
    updateDisplay();
    closeSettingsPanel();
    // Re-render to update aria-current
    if (document.getElementById('agentList')) {
        fetchAgents().then(renderAgentList);
    }
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

let currentLang = 'en';
let recognition = null;

function initRecognition() {
    if (!micButton) return;
    if (!('SpeechRecognition' in window) && !('webkitSpeechRecognition' in window)) {
        micButton.style.display = 'none';
        return;
    }

    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    recognition = new SpeechRecognition();
    recognition.continuous = false;
    recognition.interimResults = false;
    recognition.lang = getLangCode(currentLang);

    recognition.onstart = () => {
        micButton.classList.add('recording');
        chatInput.placeholder = getListeningPlaceholder();
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
        chatInput.placeholder = getInputPlaceholder();
    };

    recognition.onend = () => {
        micButton.classList.remove('recording');
        chatInput.placeholder = getInputPlaceholder();
    };
}

function getLangCode(lang) {
    return lang === 'fr' ? 'fr-FR' : 'en-US';
}

function getInputPlaceholder() {
    return currentLang === 'fr' ? 'Tapez votre message...' : 'Type your message...';
}

function getListeningPlaceholder() {
    return currentLang === 'fr' ? 'Écoute...' : 'Listening...';
}

function updateLanguage(lang) {
    currentLang = lang;
    document.documentElement.lang = lang;
    document
    .querySelector('h2').textContent = lang === 'fr' 
        ? 'Puis-je vous aider?'
        : 'How may I help?';
    chatInput.placeholder = getInputPlaceholder();
    if (recognition) {
        recognition.lang = getLangCode(lang);
    }

    const languageItems = document.querySelectorAll('#languageList [data-lang]');
    languageItems.forEach((item) => {
        item.setAttribute('aria-current', item.dataset.lang === lang ? 'true' : 'false');
    });
}

if (micButton) {
    micButton.addEventListener('click', (e) => {
        e.preventDefault();
        if (recognition) {
            recognition.start();
        }
    });
}

// Language selector
document.addEventListener('DOMContentLoaded', () => {
    const languageItems = document.querySelectorAll('#languageList [data-lang]');
    languageItems.forEach((item) => {
        item.addEventListener('click', () => {
            updateLanguage(item.dataset.lang);
        });
    });
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
        messagesEl.innerHTML = '';
        await addMessage({ type: "ai", content: "The service is currently unavailable." });
        chatInput.disabled = true;
    }
    initRecognition();
    renderBackendList();
    renderUserList();
    if (document.getElementById('agentList')) {
        fetchAgents()
            .then(renderAgentList)
            .catch(error => console.error("Could not load agents:", error));
    }
    updateDisplay();
})();
