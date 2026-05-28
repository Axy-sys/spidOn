class DijkstraPathfinder {

  ArrayList<Node> nodes;
  ArrayList<Edge> edges;

  // Step-by-step state
  Node startNode, endNode;
  ArrayList<Node> unvisited;
  boolean running = false;
  boolean finished = false;
  Node currentNode = null;
  String currentStatus = "No iniciado";

  boolean manualMode = false;
  boolean waitingForNodeSelection = false;
  boolean waitingForRelaxations = false;
  Node expectedMinNode = null;
  ArrayList<Node> relaxedNeighbors = new ArrayList<Node>();

  DijkstraPathfinder(ArrayList<Node> nodes, ArrayList<Edge> edges) {
    this.nodes = nodes;
    this.edges = edges;
    unvisited = new ArrayList<Node>();
  }

  // Find the shortest path from start node to end node (Alicia) instantly
  ArrayList<Node> findPath(Node start, Node end) {
    if (start == null || end == null) return null;
    startStepByStep(start, end);
    while (running) {
      step();
    }
    return getPath();
  }

  void startStepByStep(Node start, Node end) {
    this.startNode = start;
    this.endNode = end;
    this.running = true;
    this.finished = false;
    this.currentNode = null;
    this.currentStatus = "Inicializando Dijkstra desde " + start.name;
    this.waitingForNodeSelection = true;
    this.waitingForRelaxations = false;
    this.expectedMinNode = start;
    this.relaxedNeighbors.clear();

    for (Node n : nodes) {
      n.dijkstraDist = Float.MAX_VALUE;
      n.dijkstraParent = null;
      n.visited = false;
    }

    start.dijkstraDist = 0;
    unvisited.clear();
    for (Node n : nodes) {
      unvisited.add(n);
    }
  }

  boolean step() {
    if (!running || finished) return true;

    // Find the unvisited node with the minimum distance
    Node current = null;
    float minDist = Float.MAX_VALUE;

    for (Node n : unvisited) {
      if (n.dijkstraDist < minDist) {
        minDist = n.dijkstraDist;
        current = n;
      }
    }

    if (current == null || current == endNode) {
      running = false;
      finished = true;
      currentNode = null;
      if (current == endNode) {
        currentStatus = "Destino " + endNode.name + " alcanzado. Ruta trazada.";
      } else {
        currentStatus = "Búsqueda terminada. Nodos restantes inalcanzables.";
      }
      return true;
    }

    currentNode = current;
    current.visited = true;
    unvisited.remove(current);
    currentStatus = "Procesando " + current.name + " (Dist: " + (int)current.dijkstraDist + "). Relajando vecinos...";

    // Relax neighbors
    for (Node neighbor : current.neighbors) {
      if (neighbor.visited) continue;

      Edge e = getEdge(current, neighbor);
      if (e == null || e.blocked) continue;

      float altDist = current.dijkstraDist + e.weight;
      if (altDist < neighbor.dijkstraDist) {
        neighbor.dijkstraDist = altDist;
        neighbor.dijkstraParent = current;
      }
    }

    return false;
  }

  ArrayList<Node> getPath() {
    if (endNode == null || endNode.dijkstraDist == Float.MAX_VALUE) {
      return null;
    }
    ArrayList<Node> path = new ArrayList<Node>();
    Node curr = endNode;
    while (curr != null) {
      path.add(0, curr);
      curr = curr.dijkstraParent;
    }
    return path;
  }

  Edge getEdge(Node u, Node v) {
    for (Edge e : edges) {
      if ((e.a == u && e.b == v) || (e.a == v && e.b == u)) {
        return e;
      }
    }
    return null;
  }

  Node findNextExpectedMinNode() {
    Node minNode = null;
    float minDist = Float.MAX_VALUE;
    for (Node n : unvisited) {
      if (n.dijkstraDist < minDist) {
        minDist = n.dijkstraDist;
        minNode = n;
      }
    }
    return minNode;
  }

  void handleNodeClick(Node n) {
    if (!running || finished || !manualMode) return;

    if (waitingForNodeSelection) {
      expectedMinNode = findNextExpectedMinNode();
      if (expectedMinNode == null) {
        running = false;
        finished = true;
        currentNode = null;
        currentStatus = "Búsqueda terminada. Nodos restantes inalcanzables.";
        return;
      }

      if (n == expectedMinNode) {
        currentNode = n;
        n.visited = true;
        unvisited.remove(n);
        soundManager.playSuccess();

        if (n == endNode) {
          running = false;
          finished = true;
          currentNode = null;
          currentStatus = "Destino " + endNode.name + " alcanzado. ¡Ruta óptima calculada!";
          if (game.sceneManager.currentScene instanceof MissionScene) {
            MissionScene ms = (MissionScene) game.sceneManager.currentScene;
            ms.dijkstraPath = getPath();
          }
        } else {
          // Prepare neighbors to relax
          relaxedNeighbors.clear();
          for (Node neighbor : currentNode.neighbors) {
            if (!neighbor.visited) {
              Edge e = getEdge(currentNode, neighbor);
              if (e != null && !e.blocked) {
                relaxedNeighbors.add(neighbor);
              }
            }
          }

          if (relaxedNeighbors.isEmpty()) {
            waitingForNodeSelection = true;
            expectedMinNode = findNextExpectedMinNode();
            currentStatus = "Nodo " + currentNode.name + " procesado. Selecciona el siguiente nodo no visitado con menor distancia.";
          } else {
            waitingForNodeSelection = false;
            waitingForRelaxations = true;
            String neighborsStr = "";
            for (int i = 0; i < relaxedNeighbors.size(); i++) {
              neighborsStr += relaxedNeighbors.get(i).name + (i < relaxedNeighbors.size() - 1 ? ", " : "");
            }
            currentStatus = "Procesando " + currentNode.name + ". Haz clic en sus vecinos (" + neighborsStr + ") para relajar sus distancias.";
          }
        }
      } else {
        if (game.sceneManager.currentScene instanceof MissionScene) {
          MissionScene ms = (MissionScene) game.sceneManager.currentScene;
          ms.score = max(0, ms.score - 150);
          ms.loseShield();
          ms.dialogueSystem.eva("¡Incorrecto! Debes seleccionar el nodo no visitado con menor distancia tentativa: " + expectedMinNode.name + " (-150 pts).");
        } else {
          soundManager.playError();
        }
      }
    } else if (waitingForRelaxations) {
      if (relaxedNeighbors.contains(n)) {
        Edge e = getEdge(currentNode, n);
        float altDist = currentNode.dijkstraDist + e.weight;
        boolean updated = false;
        if (altDist < n.dijkstraDist) {
          n.dijkstraDist = altDist;
          n.dijkstraParent = currentNode;
          updated = true;
        }

        relaxedNeighbors.remove(n);
        soundManager.playSelect();
        
        if (game.sceneManager.currentScene instanceof MissionScene) {
          MissionScene ms = (MissionScene) game.sceneManager.currentScene;
          ms.score += 200;
          ms.triggerAlert("+200 RELAJACIÓN");
          if (updated) {
            ms.dialogueSystem.eva("¡Relajado! " + n.name + " ahora está a distancia " + (int)n.dijkstraDist + " vía " + currentNode.name + ".");
          } else {
            ms.dialogueSystem.eva(n.name + " ya tiene un camino más corto de longitud " + (int)n.dijkstraDist + ".");
          }
        }

        if (relaxedNeighbors.isEmpty()) {
          waitingForRelaxations = false;
          waitingForNodeSelection = true;
          expectedMinNode = findNextExpectedMinNode();
          if (expectedMinNode == null) {
            running = false;
            finished = true;
            currentNode = null;
            currentStatus = "Búsqueda terminada. Nodos restantes inalcanzables.";
          } else {
            currentStatus = "Relajaciones completadas. Selecciona el siguiente nodo no visitado con menor distancia tentativa (" + expectedMinNode.name + ").";
          }
        } else {
          String neighborsStr = "";
          for (int i = 0; i < relaxedNeighbors.size(); i++) {
            neighborsStr += relaxedNeighbors.get(i).name + (i < relaxedNeighbors.size() - 1 ? ", " : "");
          }
          currentStatus = "Relajando vecinos... Quedan: " + neighborsStr;
        }
      } else {
        soundManager.playError();
        if (game.sceneManager.currentScene instanceof MissionScene) {
          MissionScene ms = (MissionScene) game.sceneManager.currentScene;
          ms.dialogueSystem.eva("Debes relajar los vecinos del nodo activo (" + currentNode.name + ").");
        }
      }
    }
  }
}
