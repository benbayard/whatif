package main

import (
  "log"
  "net/http"
)

func main() {
  http.HandleFunc("/", start)
  err := http.ListenAndServe("127.0.0.1:3000", nil)
  if err != nil {
    log.Fatal("ListenAndServe: ", err)
  }
  // http.HandleFunc("/ws", serveWs)
}

func start(writer http.ResponseWriter, reader *http.Request) {
  if reader.URL.Path != "/" {
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