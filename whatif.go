package main

import (
  "log"
  "net/http"
)

func main() {
  go h.run()
  http.HandleFunc("/", start)
  http.HandleFunc("/ws", serveWs)
  log.Print("Starting Server...")
  err := http.ListenAndServe("127.0.0.1:1337", nil)
  if err != nil {
    log.Fatal("ListenAndServe: ", err)
  }
}

func start(writer http.ResponseWriter, reader *http.Request) {
  log.Println(reader.URL.Path)
  if reader.URL.Path != "/" {
    if reader.URL.Path == "/application.js" {
      http.ServeFile(writer, reader, "assets/application.js")
    }
    http.Error(writer, "Not found", 404)
    return
  }
  if reader.Method != "GET" {
    http.Error(writer, "Method not allowed", 405)
    return
  }
  writer.Header().Set("Content-Type", "text/html; charset=utf-8")
  http.ServeFile(writer, reader, "assets/index.html")
}