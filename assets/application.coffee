# window.addEventListener "load", ->
#   
window.conn = new WebSocket "ws://localhost:1337/ws"

conn.onclose   = (evt) ->
  console.log "Connection Closed"
conn.onmessage = (evt) ->
  console.log evt.data


displayCanvas = document.querySelector ".display-canvas"
 # ->
canvas = document.createElement "canvas"
canvas.classList.add "longitude-latitude"

canvasHeight = 800 
canvasWidth  = 800 
canvasLines  = 40  

numPoints    = 2
numPaths     = 2 

paths        = new Array
pointSize    = 20;

padding = 0

canvas.height = (canvasHeight + 1) * 2
canvas.width  = (canvasWidth  + 1) * 2

context = canvas.getContext "2d"
# context.imageSmoothingEnabled = true;

canvasArrow = (context, fromx, fromy, tox, toy) ->
  headlen = 20;   # length of head in pixels
  angle = Math.atan2(toy-fromy,tox-fromx);
  context.moveTo(fromx, fromy);
  context.lineTo(tox, toy);
  context.lineTo(tox-headlen*Math.cos(angle-Math.PI/6),toy-headlen*Math.sin(angle-Math.PI/6));
  context.moveTo(tox, toy);
  context.lineTo(tox-headlen*Math.cos(angle+Math.PI/6),toy-headlen*Math.sin(angle+Math.PI/6));

drawGrid = () ->
  for i in [0..canvasHeight] by canvasLines
    context.moveTo 0.5 + i + padding, padding
    context.lineTo 0.5 + i + padding, canvasHeight + padding

  for i in [0..canvasWidth] by canvasLines
    context.moveTo padding, 0.5 + i + padding
    context.lineTo canvasWidth + padding, 0.5 + i + padding

    context.strokeStyle = "black"
    context.stroke()

drawPoints = () ->
  for i in [0..numPaths - 1] by 1
    pointColor = "rgb(#{Math.floor(Math.random() * 255)}, #{Math.floor(Math.random() * 255)}, #{Math.floor(Math.random() * 255)})"
    # console.log pointColor
    path = []
    for j in [0..numPoints - 1] by 1
      randX = Math.random() * canvasWidth  + 1
      randY = Math.random() * canvasHeight + 1
      context.beginPath()
      context.arc randX, randY, pointSize, 0, 2 * Math.PI, false
      context.fillStyle = pointColor
      context.fill()
      context.fillStyle    = 'black'
      context.strokeStyle  = 'white'
      context.textBaseline = "top"
      context.font = "#{pointSize*1.5} Helvetica"
      context.strokeText (j+1).toString(), randX - 8, randY - 16
      context.fillText   (j+1).toString(), randX - 8, randY - 16
      point = 
        x: randX
        y: randY
      path.push point
    paths.push path
  conn.send(JSON.stringify(paths))
  return paths

distance = (p1, p2) ->
  Math.abs(Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2)))

smallestDistance = () ->
  # so here's how this works:
  # if you start at path[0] you must also stop
  # at all points along path[1] while also going to path[1,0] before path[1,1]
  # this means you can do this: 
  # path[0,0] -> path[0,1] -> path[1,0] -> path[1,1]
  # path[0,0] -> path[1,0] -> path[0,1] -> path[1,1]
  # path[1,0] -> path[0,0] -> path[1,1] -> path[0,1]
  # path[1,0] -> path[1,1] -> path[0,0] -> path[0,1]
  # so we are just going to go through each and determine the path.
  # this is not the best way to determine the algorithm.
  # but this is my way
  solutions = []
  
  for i in [0..paths.length - 1]
    currentPos = [i,0]
    initialPos = currentPos
    solution = 
      totalDistance: 0
      points: [paths[currentPos[0]][currentPos[1]]]
    # (i == paths.length - 1) ? last = true : last = false
    # until pathSolved
    pathSolved = false
    until pathSolved
    # for i in [0..3]
      # first go in sequence
      # here are the valid points: It can go to either 
      # 1) The next point in the line (i+1) 
      # 2) The first point in the next line.
      # 3) If you're not on the first point of either line
      #    go to whichever point is closest.
      distances = []
      currentPath  = paths[currentPos[0]]
      if currentPos[0] == (paths.length - 1 )
        otherPath = 0
      else
        otherPath = paths.length - 1 

      currentPoint = currentPath[currentPos[1]]
      # console.log("The currentPos is:          #{currentPos}. \nThe current path length is: #{currentPath.length - 1}")
      if (currentPos[1] != currentPath.length - 1) && solution.points.indexOf(paths[currentPos[0]][currentPos[1]+1])
        # console.log("this isn't working is it?")
        travel = 
          "the_distance":   distance(paths[currentPos[0]][currentPos[1]], paths[currentPos[0]][currentPos[1]+1])
          position: [currentPos[0], currentPos[1] + 1]
        distances.push travel
      # console.log("Index Of Other Path's initial location: #{solution.points.indexOf([otherPath, 0])}")
      if solution.points.indexOf(paths[otherPath][0]) == -1
        # console.log("did this work?")
        travel = 
          "the_distance":   distance(paths[currentPos[0]][currentPos[1]], paths[otherPath][0])
          position: [otherPath, 0]
        # console.log travel
        distances.push travel
      else if solution.points.indexOf(paths[otherPath][1]) == -1
        # if the other path is on the list
        travel = 
          the_distance:   distance(paths[currentPos[0]][currentPos[1]], paths[otherPath][1])
          position: [otherPath, 1]
        # console.log travel
        distances.push travel
      # console.log("The Distances Are:")
      # console.log(distances)
      smallestDistance = 0
      for travel in distances
        # console.log(smallestDistance)
        # console.log(travel.the_distance)
        if smallestDistance == 0
          # console.log("Smallest Distance is 0")
          smallestDistance = travel.the_distance
          currentPos = travel.position
        else if smallestDistance > travel.the_distance
          # console.log("The Traveling distance is smaller than the smallestDistance")

          smallestDistance = travel.the_distance
          currentPos = travel.position

      solution.totalDistance += smallestDistance

      solution.points.push paths[currentPos[0]][currentPos[1]]

      if solution.points.indexOf(paths[0][paths[0].length-1]) != -1 && solution.points.indexOf(paths[1][paths[1].length-1]) != -1
        pathSolved = true
      # console.log "Index Of Last in First Path: #{solution.points.indexOf(paths[0][paths[0].length-1])}"
      # console.log "Index Of Last in Last  Path: #{solution.points.indexOf(paths[1][paths[1].length-1])}"
      # console.log "Path Solved #{pathSolved}"

    solutions.push solution
  return solutions

conn.onopen = ->
  drawGrid()
  paths = drawPoints()

  solutions = smallestDistance()

  console.log solutions

  correct = solutions[0]
  for i in [1..solutions.length - 1]
    correct = solutions[1] if solutions[i].totalDistance < correct.totalDistance

  # now we have to draw the points
  for i in [1..correct.points.length - 1]
    context.beginPath()
    context.lineWidth  = 7
    context.strokeStyle  = 'black'

    canvasArrow(context, correct.points[i-1].x, correct.points[i-1].y, correct.points[i].x, correct.points[i].y)
    context.stroke()

    context.strokeStyle  = 'red'
    context.lineWidth  = 5
    canvasArrow(context, correct.points[i-1].x, correct.points[i-1].y, correct.points[i].x, correct.points[i].y)

    context.stroke()

  canvas.setAttribute "style", "height: #{ canvasHeight + 1 }; width: #{ canvasWidth + 1 }"

displayCanvas.appendChild canvas
