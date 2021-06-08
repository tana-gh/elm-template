import { Elm } from './elm/Main.elm'
import '../assets/scss/style.scss'

const app = Elm.Main.init({
    node: document.getElementById('app')
})

const socket = new WebSocket('wss://echo.websocket.org')

socket.addEventListener('open', () => {
    app.ports.loadingPort.send(false)
})

app.ports.sendHelloPort.subscribe(message => {
    socket.send(message)
})

socket.addEventListener('message', ev => {
    app.ports.receiveHelloPort.send(ev.data)
})
