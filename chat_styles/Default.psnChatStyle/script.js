/* TODO I know jack shit about javascript. It would be wonderful if someone who
 * knew what they were doing give this a nice clean up. */

function pushMessage(message) {
    console.log(message.type());
    console.log(message.dateString().toLocaleString())
    switch (message.type()) {
        case 0: {
            pushChatMessageFromMessage(message)
            break
        }
        case 1: {
            pushActionMessageFromMessage(message)
            break
        }
    }
}

function pushChatMessageFromMessage(message) {
    needToAppend = false
    a = document.getElementById("theme").getElementsByClassName("context")
    lastContext = a[a.length - 1]
    console.log(lastContext)
    if (!lastContext || lastContext.className.split(" ").indexOf("chat") == -1 || parseInt(lastContext.getElementsByClassName("sender")[0].getAttribute("sid")) != message.sender().friendNumber()) {
        context = document.createElement("div")
        context.className = "context chat"
        if (message.sender().isSelf()) {
            context.className += " ours"
        } else {
            context.className += " theirs"
        }
        // sender
        sender = document.createElement("div")
        sender.className = "context-item sender"
        sender.textContent = message.sender().displayName()
        sender.setAttribute("sid", message.sender().friendNumber());
        context.appendChild(sender)
        // timestamp
        timestamp = document.createElement("div")
        timestamp.className = "context-item timestamp"
        timestamp.textContent = message.dateString()
        context.appendChild(timestamp)
        // body
        messages = document.createElement("div")
        messages.className = "context-item messages"
        context.appendChild(messages);
        lastContext = context
        needToAppend = true
    }
    content = document.createElement("p")
    content.textContent = message.content()
    lastContext.getElementsByClassName("messages")[0].appendChild(content)
    if (needToAppend) {
        document.getElementById("theme").appendChild(lastContext)
    }
}
function pushActionMessageFromMessage(message) {
    context = document.createElement("div")
    context.className = "context action"
    if (message.sender().isSelf()) {
        context.className += " ours"
    } else {
        context.className += " theirs"
    }
    // sender
    sender = document.createElement("div")
    sender.className = "context-item sender"
    sender.textContent = "* " + message.sender().displayName() + " " + message.content()
    sender.setAttribute("sid", message.sender().friendNumber())
    context.appendChild(sender)
    // timestamp
    timestamp = document.createElement("div")
    timestamp.className = "context-item timestamp"
    timestamp.textContent = message.dateString()
    context.appendChild(timestamp)
    clearfix = document.createElement("div")
    clearfix.style.clear = "both"
    context.appendChild(clearfix)
    document.getElementById("theme").appendChild(context)
}