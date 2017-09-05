import "phoenix_html"
import {Socket, Presence} from "phoenix"
import {Sketchpad, sanitize} from "./sketchpad"
import socket from "./socket"

socket.connect()

let App = {
  init() {
    this.padChannel = socket.channel("pad:lobby") 
    this.el = document.getElementById("sketchpad")
    this.pad = new Sketchpad(this.el, window.userId)
    this.clearButton = document.getElementById("clear-button")
    this.exportButton = document.getElementById("export-button")
    this.msgInput = document.getElementById("message-input")
    this.msgContainer = document.getElementById("messages")

    this.msgInput.addEventListener("keypress", e => {
      if(e.keyCode !== 13 || this.msgInput.value === "") {
        return
      }
      this.msgInput.disabled = true

      let onError = () => {
          this.msgInput.disabled = false
      }

      this.padChannel.push("new_message", {
        body: this.msgInput.value
      })
        .receive("ok", () => {
          this.msgInput.value = ""
          this.msgInput.disabled = false  
        })
        .receive("error", onError)
        .receive("timeout", onError)
    })

    this.padChannel.on("new_message", ({user_id, body}) => {
      this.msgContainer.innerHTML += `<br /><b>${sanitize(user_id)}</b>: ${sanitize(body)}`
      this.msgContainer.scrollTop = this.msgContainer.scrollHeight
    })

    this.exportButton.addEventListener("click", e => {
      e.preventDefault()
      window.open(this.pad.getImageURL())
    })

    this.clearButton.addEventListener("click", e => {
      e.preventDefault()
      this.pad.clear()
      this.padChannel.push("clear")
    })

    this.padChannel.on("clear", () => {
      this.pad.clear()
    })

    this.pad.on("stroke", data => {
      this.padChannel.push("stroke", data) 
        //.receive("ok", )
    })

    this.padChannel.on("stroke", ({user_id, stroke}) => {
      this.pad.putStroke(user_id, stroke, {color: "#000000"})    
    })

    let joinedAndSeed = ({strokes, user_id}) => {
      for(let r in strokes) {
        let stroke = strokes[r]
        this.pad.putStroke(user_id, stroke, {color: "#000000"})
      }
    }

    this.padChannel.join()
      .receive("ok", joinedAndSeed)
      .receive("error", resp => console.log("failed to join", resp))
      .receive("timeout", resp => console.log("timed out", resp))
  }  
}

App.init()




