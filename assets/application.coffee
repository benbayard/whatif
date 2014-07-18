# window.addEventListener "load", ->
#   
window.conn = new WebSocket "ws://localhost:1337/ws"

conn.onclose   = (evt) ->
  console.log "Connection Closed"
conn.onmessage = (evt) ->
  console.log evt.data

  document.querySelector(".tritium-time").innerHTML = Date.now() - window.currTime
  document.querySelector(".tritium-results").innerHTML = evt.data
  

document.querySelector(".transform").addEventListener "click", ->
  tritium    = document.querySelector(".tritium").value
  html       = document.querySelector(".html").value
  javascript = document.querySelector(".javascript").value

  document.querySelector(".results").find(".javascript-results, .tritium-results").each(function() {this.innerHTML = ''})

  data =     
    tritium: tritium
    html:    html

  document.querySelector(".results").scrollIntoView()

  console.log data

  window.currTime = Date.now();

  conn.send JSON.stringify(data)

  document.querySelector(".javascript-results").innerHTML = eval("(function(){" + javascript + "})();")


# drawPoints = () ->
  # conn.send(JSON.stringify(paths))


  # return paths


# conn.onopen = ->

