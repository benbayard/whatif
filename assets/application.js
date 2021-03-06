// Generated by CoffeeScript 1.7.1
(function() {
  var canvas, canvasArrow, canvasHeight, canvasLines, canvasWidth, context, displayCanvas, distance, drawGrid, drawPoints, numPaths, numPoints, padding, paths, pointSize, smallestDistance;

  window.conn = new WebSocket("ws://localhost:1337/ws");

  conn.onclose = function(evt) {
    return console.log("Connection Closed");
  };

  conn.onmessage = function(evt) {
    return console.log(evt.data);
  };

  displayCanvas = document.querySelector(".display-canvas");

  canvas = document.createElement("canvas");

  canvas.classList.add("longitude-latitude");

  canvasHeight = 800;

  canvasWidth = 800;

  canvasLines = 40;

  numPoints = 2;

  numPaths = 2;

  paths = new Array;

  pointSize = 20;

  padding = 0;

  canvas.height = (canvasHeight + 1) * 2;

  canvas.width = (canvasWidth + 1) * 2;

  context = canvas.getContext("2d");

  canvasArrow = function(context, fromx, fromy, tox, toy) {
    var angle, headlen;
    headlen = 20;
    angle = Math.atan2(toy - fromy, tox - fromx);
    context.moveTo(fromx, fromy);
    context.lineTo(tox, toy);
    context.lineTo(tox - headlen * Math.cos(angle - Math.PI / 6), toy - headlen * Math.sin(angle - Math.PI / 6));
    context.moveTo(tox, toy);
    return context.lineTo(tox - headlen * Math.cos(angle + Math.PI / 6), toy - headlen * Math.sin(angle + Math.PI / 6));
  };

  drawGrid = function() {
    var i, _i, _j, _results;
    for (i = _i = 0; canvasLines > 0 ? _i <= canvasHeight : _i >= canvasHeight; i = _i += canvasLines) {
      context.moveTo(0.5 + i + padding, padding);
      context.lineTo(0.5 + i + padding, canvasHeight + padding);
    }
    _results = [];
    for (i = _j = 0; canvasLines > 0 ? _j <= canvasWidth : _j >= canvasWidth; i = _j += canvasLines) {
      context.moveTo(padding, 0.5 + i + padding);
      context.lineTo(canvasWidth + padding, 0.5 + i + padding);
      context.strokeStyle = "black";
      _results.push(context.stroke());
    }
    return _results;
  };

  drawPoints = function() {
    var i, j, path, point, pointColor, randX, randY, _i, _j, _ref, _ref1;
    for (i = _i = 0, _ref = numPaths - 1; _i <= _ref; i = _i += 1) {
      pointColor = "rgb(" + (Math.floor(Math.random() * 255)) + ", " + (Math.floor(Math.random() * 255)) + ", " + (Math.floor(Math.random() * 255)) + ")";
      path = [];
      for (j = _j = 0, _ref1 = numPoints - 1; _j <= _ref1; j = _j += 1) {
        randX = Math.random() * canvasWidth + 1;
        randY = Math.random() * canvasHeight + 1;
        context.beginPath();
        context.arc(randX, randY, pointSize, 0, 2 * Math.PI, false);
        context.fillStyle = pointColor;
        context.fill();
        context.fillStyle = 'black';
        context.strokeStyle = 'white';
        context.textBaseline = "top";
        context.font = "" + (pointSize * 1.5) + " Helvetica";
        context.strokeText((j + 1).toString(), randX - 8, randY - 16);
        context.fillText((j + 1).toString(), randX - 8, randY - 16);
        point = {
          x: randX,
          y: randY
        };
        path.push(point);
      }
      paths.push(path);
    }
    conn.send(JSON.stringify(paths));
    return paths;
  };

  distance = function(p1, p2) {
    return Math.abs(Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2)));
  };

  smallestDistance = function() {
    var currentPath, currentPoint, currentPos, distances, i, initialPos, otherPath, pathSolved, solution, solutions, travel, _i, _j, _len, _ref;
    solutions = [];
    for (i = _i = 0, _ref = paths.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      currentPos = [i, 0];
      initialPos = currentPos;
      solution = {
        totalDistance: 0,
        points: [paths[currentPos[0]][currentPos[1]]]
      };
      pathSolved = false;
      while (!pathSolved) {
        distances = [];
        currentPath = paths[currentPos[0]];
        if (currentPos[0] === (paths.length - 1)) {
          otherPath = 0;
        } else {
          otherPath = paths.length - 1;
        }
        currentPoint = currentPath[currentPos[1]];
        if ((currentPos[1] !== currentPath.length - 1) && solution.points.indexOf(paths[currentPos[0]][currentPos[1] + 1])) {
          travel = {
            "the_distance": distance(paths[currentPos[0]][currentPos[1]], paths[currentPos[0]][currentPos[1] + 1]),
            position: [currentPos[0], currentPos[1] + 1]
          };
          distances.push(travel);
        }
        if (solution.points.indexOf(paths[otherPath][0]) === -1) {
          travel = {
            "the_distance": distance(paths[currentPos[0]][currentPos[1]], paths[otherPath][0]),
            position: [otherPath, 0]
          };
          distances.push(travel);
        } else if (solution.points.indexOf(paths[otherPath][1]) === -1) {
          travel = {
            the_distance: distance(paths[currentPos[0]][currentPos[1]], paths[otherPath][1]),
            position: [otherPath, 1]
          };
          distances.push(travel);
        }
        smallestDistance = 0;
        for (_j = 0, _len = distances.length; _j < _len; _j++) {
          travel = distances[_j];
          if (smallestDistance === 0) {
            smallestDistance = travel.the_distance;
            currentPos = travel.position;
          } else if (smallestDistance > travel.the_distance) {
            smallestDistance = travel.the_distance;
            currentPos = travel.position;
          }
        }
        solution.totalDistance += smallestDistance;
        solution.points.push(paths[currentPos[0]][currentPos[1]]);
        if (solution.points.indexOf(paths[0][paths[0].length - 1]) !== -1 && solution.points.indexOf(paths[1][paths[1].length - 1]) !== -1) {
          pathSolved = true;
        }
      }
      solutions.push(solution);
    }
    return solutions;
  };

  conn.onopen = function() {
    var correct, i, solutions, _i, _j, _ref, _ref1;
    drawGrid();
    paths = drawPoints();
    solutions = smallestDistance();
    console.log(solutions);
    correct = solutions[0];
    for (i = _i = 1, _ref = solutions.length - 1; 1 <= _ref ? _i <= _ref : _i >= _ref; i = 1 <= _ref ? ++_i : --_i) {
      if (solutions[i].totalDistance < correct.totalDistance) {
        correct = solutions[1];
      }
    }
    for (i = _j = 1, _ref1 = correct.points.length - 1; 1 <= _ref1 ? _j <= _ref1 : _j >= _ref1; i = 1 <= _ref1 ? ++_j : --_j) {
      context.beginPath();
      context.lineWidth = 7;
      context.strokeStyle = 'black';
      canvasArrow(context, correct.points[i - 1].x, correct.points[i - 1].y, correct.points[i].x, correct.points[i].y);
      context.stroke();
      context.strokeStyle = 'red';
      context.lineWidth = 5;
      canvasArrow(context, correct.points[i - 1].x, correct.points[i - 1].y, correct.points[i].x, correct.points[i].y);
      context.stroke();
    }
    return canvas.setAttribute("style", "height: " + (canvasHeight + 1) + "; width: " + (canvasWidth + 1));
  };

  displayCanvas.appendChild(canvas);

}).call(this);
