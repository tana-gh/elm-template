import { Elm } from './elm/Main.elm'
import '../assets/scss/style.scss'

const app = Elm.Main.init({
    node: document.getElementById('app')
})

setTimeout(() => {
    app.ports.loadingPort.send(false)
}, 1000)

app.ports.sendHelloPort.subscribe(message => {
    setTimeout(() => {
        app.ports.receiveHelloPort.send(message)
    }, 1000)
})
