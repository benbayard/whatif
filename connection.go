package main

import (
  "github.com/gorilla/websocket"
  "time"
  "log"
  "net/http"
  "tritium_oss/tr"
  "encoding/json"
)

const (
  // Time allowed to write a message to the peer.
  writeWait = 10 * time.Second

  // Time allowed to read the next pong message from the peer.
  pongWait = 60 * time.Second

  // Send pings to peer with this period. Must be less than pongWait.
  pingPeriod = (pongWait * 9) / 10

  // Maximum message size allowed from peer.
  maxMessageSize = 4096
)

var upgrader = websocket.Upgrader{
  ReadBufferSize:  1024,
  WriteBufferSize: 1024,
}

type connection struct {
  ws *websocket.Conn
  send chan []byte
}

type transformer struct {
  Tritium string `json: tritium`
  Html    string `json: html`
}


// readPump pumps messages from the websocket connection to the hub.
func (c *connection) readPump() {
  defer func() {
    h.unregister <- c
    c.ws.Close()
  }()
  c.ws.SetReadLimit(maxMessageSize)
  c.ws.SetReadDeadline(time.Now().Add(pongWait))
  c.ws.SetPongHandler(func(string) error { c.ws.SetReadDeadline(time.Now().Add(pongWait)); return nil })
  for {
    currTime := time.Now().Unix()
    _, message, err := c.ws.ReadMessage()
    // log.Print(string(message))
    if err != nil {
      log.Print("There was an error reading the message")
      log.Print(err.Error())
      break
    } else {
      fetch := &transformer{}
      err   := json.Unmarshal(message, fetch)
      if err != nil {
        log.Print("There was an error")
        log.Print(err.Error())
      }
      if fetch == nil {
        log.Print("WHY DO YOU HATE ME")
      }
      html := tritium.Transform(fetch.Tritium, fetch.Html)
      h.broadcast <- []byte(html)
      log.Print(time.Now().Unix() - currTime)
    }
  }
}

// write writes a message with the given message type and payload.
func (c *connection) write(mt int, payload []byte) error {
  c.ws.SetWriteDeadline(time.Now().Add(writeWait))
  return c.ws.WriteMessage(mt, payload)
}

// writePump pumps messages from the hub to the websocket connection.
func (c *connection) writePump() {
  ticker := time.NewTicker(pingPeriod)
  defer func() {
    ticker.Stop()
    c.ws.Close()
  }()
  for {
    select {
    case message, ok := <-c.send:
      if !ok {
        c.write(websocket.CloseMessage, []byte{})
        return
      }
      if err := c.write(websocket.TextMessage, message); err != nil {
        return
      }
    case <-ticker.C:
      if err := c.write(websocket.PingMessage, []byte{}); err != nil {
        return
      }
    }
  }
}

// serverWs handles webocket requests from the peer.
func serveWs(w http.ResponseWriter, r *http.Request) {
  if r.Method != "GET" {
    http.Error(w, "Method not allowed", 405)
    return
  }
  ws, err := upgrader.Upgrade(w, r, nil)
  if err != nil {
    log.Println(err)
    return
  }
  c := &connection{send: make(chan []byte, 256), ws: ws}
  h.register <- c
  go c.writePump()
  c.readPump()
}