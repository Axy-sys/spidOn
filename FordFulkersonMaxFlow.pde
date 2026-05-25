import java.util.HashSet;
import java.util.HashMap;

class FordFulkersonMaxFlow {

  ArrayList<Node> nodes;
  ArrayList<Edge> edges;

  // Step-by-step state
  Node sourceNode, sinkNode;
  ArrayList<String> augmentingPathsHistory;
  boolean running = false;
  boolean finished = false;
  float maxFlow = 0;
  String currentStatus = "No iniciado";
  ArrayList<Node> currentPath = null;
  float currentBottleneck = 0;

  boolean manualMode = false;
  ArrayList<Node> playerPath = new ArrayList<Node>();

  FordFulkersonMaxFlow(ArrayList<Node> nodes, ArrayList<Edge> edges) {
    this.nodes = nodes;
    this.edges = edges;
    augmentingPathsHistory = new ArrayList<String>();
  }

  // Calculates the Max Flow instantly and returns it
  float calculateMaxFlow(Node source, Node sink) {
    if (source == null || sink == null) return 0;
    startStepByStep(source, sink);
    while (running) {
      step();
    }
    return maxFlow;
  }

  void startStepByStep(Node source, Node sink) {
    this.sourceNode = source;
    this.sinkNode = sink;
    this.running = true;
    this.finished = false;
    this.maxFlow = 0;
    this.currentStatus = "Inicializando Ford-Fulkerson desde " + source.name + " hasta " + sink.name;
    this.augmentingPathsHistory.clear();
    this.currentPath = null;
    this.currentBottleneck = 0;
    this.playerPath.clear();

    for (Edge e : edges) {
      e.flow = 0;
    }
  }

  boolean step() {
    if (!running || finished) return true;

    // Find an augmenting path using BFS
    ArrayList<Node> queue = new ArrayList<Node>();
    HashMap<Node, Edge> parentEdge = new HashMap<Node, Edge>();
    HashMap<Node, Boolean> isForward = new HashMap<Node, Boolean>();
    HashSet<Node> visited = new HashSet<Node>();

    queue.add(sourceNode);
    visited.add(sourceNode);

    boolean pathFound = false;

    while (queue.size() > 0) {
      Node curr = queue.remove(0);

      if (curr == sinkNode) {
        pathFound = true;
        break;
      }

      for (Node neighbor : curr.neighbors) {
        if (visited.contains(neighbor)) continue;

        Edge e = getEdge(curr, neighbor);
        if (e == null || e.blocked) continue;

        float residualCapacity = 0;
        boolean forward = (e.a == curr);

        if (forward) {
          residualCapacity = e.capacity - e.flow;
        } else {
          residualCapacity = e.flow;
        }

        if (residualCapacity > 0.01) {
          visited.add(neighbor);
          parentEdge.put(neighbor, e);
          isForward.put(neighbor, forward);
          queue.add(neighbor);
        }
      }
    }

    if (!pathFound) {
      running = false;
      finished = true;
      currentPath = null;
      currentStatus = "No quedan más caminos de aumento. Flujo Máximo calculado: " + (int)maxFlow;
      return true;
    }

    // Reconstruct path and find bottleneck
    float bottleneck = Float.MAX_VALUE;
    Node currNode = sinkNode;
    ArrayList<Node> path = new ArrayList<Node>();
    
    while (currNode != sourceNode) {
      path.add(0, currNode);
      Edge e = parentEdge.get(currNode);
      boolean forward = isForward.get(currNode);
      float resCap = forward ? (e.capacity - e.flow) : e.flow;
      bottleneck = min(bottleneck, resCap);
      currNode = forward ? e.a : e.b;
    }
    path.add(0, sourceNode);
    
    this.currentPath = path;
    this.currentBottleneck = bottleneck;

    // Update flow on the path
    currNode = sinkNode;
    while (currNode != sourceNode) {
      Edge e = parentEdge.get(currNode);
      boolean forward = isForward.get(currNode);
      if (forward) {
        e.flow += bottleneck;
      } else {
        e.flow -= bottleneck;
      }
      currNode = forward ? e.a : e.b;
    }

    maxFlow += bottleneck;
    
    // Construct path string for history
    String pathStr = "";
    for (int i = 0; i < path.size(); i++) {
      pathStr += path.get(i).name;
      if (i < path.size() - 1) pathStr += " → ";
    }
    augmentingPathsHistory.add("Ruta: " + pathStr + " (Cuello de Botella: " + (int)bottleneck + ")");
    currentStatus = "Camino de aumento encontrado! Enviados +" + (int)bottleneck + " mensajes. Flujo acumulado: " + (int)maxFlow;

    return false;
  }

  Edge getEdge(Node u, Node v) {
    for (Edge e : edges) {
      if ((e.a == u && e.b == v) || (e.a == v && e.b == u)) {
        return e;
      }
    }
    return null;
  }

  void handleNodeClick(Node n) {
    if (!running || finished || !manualMode) return;

    if (playerPath.isEmpty()) {
      if (n == sourceNode) {
        playerPath.add(n);
        soundManager.playSelect();
        currentStatus = "Trazando camino: " + n.name;
        if (game.sceneManager.currentScene instanceof MissionScene) {
          ((MissionScene)game.sceneManager.currentScene).triggerAlert("CAMINO INICIADO");
        }
      } else {
        soundManager.playError();
        currentStatus = "Debes iniciar el camino desde la Fuente (" + sourceNode.name + ").";
      }
    } else {
      Node lastNode = playerPath.get(playerPath.size() - 1);
      if (n == lastNode) return;

      Edge e = getEdge(lastNode, n);
      if (e == null || e.blocked) {
        soundManager.playError();
        currentStatus = "No hay enlace directo activo entre " + lastNode.name + " y " + n.name;
        return;
      }

      boolean forward = (e.a == lastNode);
      float residual = forward ? (e.capacity - e.flow) : e.flow;
      if (residual <= 0.01) {
        soundManager.playError();
        currentStatus = "Enlace " + lastNode.name + " - " + n.name + " sin capacidad residual.";
        return;
      }

      if (playerPath.contains(n)) {
        soundManager.playError();
        currentStatus = "El camino ya contiene a " + n.name + " (evita ciclos).";
        return;
      }

      playerPath.add(n);
      soundManager.playSelect();

      String pathStr = "";
      for (int i = 0; i < playerPath.size(); i++) {
        pathStr += playerPath.get(i).name + (i < playerPath.size() - 1 ? " → " : "");
      }
      currentStatus = "Trazando camino: " + pathStr;

      if (n == sinkNode) {
        float bottleneck = Float.MAX_VALUE;
        for (int i = 0; i < playerPath.size() - 1; i++) {
          Node u = playerPath.get(i);
          Node v = playerPath.get(i + 1);
          Edge ed = getEdge(u, v);
          boolean fwd = (ed.a == u);
          float res = fwd ? (ed.capacity - ed.flow) : ed.flow;
          bottleneck = min(bottleneck, res);
        }

        for (int i = 0; i < playerPath.size() - 1; i++) {
          Node u = playerPath.get(i);
          Node v = playerPath.get(i + 1);
          Edge ed = getEdge(u, v);
          boolean fwd = (ed.a == u);
          if (fwd) {
            ed.flow += bottleneck;
          } else {
            ed.flow -= bottleneck;
          }
        }

        maxFlow += bottleneck;
        augmentingPathsHistory.add("Ruta: " + pathStr + " (Cuello: " + (int)bottleneck + ")");
        soundManager.playSuccess();

        if (game.sceneManager.currentScene instanceof MissionScene) {
          MissionScene ms = (MissionScene) game.sceneManager.currentScene;
          ms.score += 1000;
          ms.dialogueSystem.eva("¡Camino completado! Cuello de botella: " + (int)bottleneck + ". Flujo acumulado: " + (int)maxFlow);
          ms.triggerAlert("+1000 PUNTOS");
        }

        playerPath.clear();

        if (!hasAnyAugmentingPath()) {
          running = false;
          finished = true;
          currentStatus = "No quedan más caminos de aumento. Flujo Máximo: " + (int)maxFlow;
          if (game.sceneManager.currentScene instanceof MissionScene) {
            MissionScene ms = (MissionScene) game.sceneManager.currentScene;
            ms.calculatedMaxFlow = maxFlow;
          }
        }
      }
    }
  }

  boolean hasAnyAugmentingPath() {
    ArrayList<Node> queue = new ArrayList<Node>();
    HashSet<Node> visited = new HashSet<Node>();
    queue.add(sourceNode);
    visited.add(sourceNode);
    boolean found = false;

    while (queue.size() > 0) {
      Node curr = queue.remove(0);
      if (curr == sinkNode) {
        found = true;
        break;
      }
      for (Node neighbor : curr.neighbors) {
        if (visited.contains(neighbor)) continue;
        Edge e = getEdge(curr, neighbor);
        if (e == null || e.blocked) continue;
        float residual = (e.a == curr) ? (e.capacity - e.flow) : e.flow;
        if (residual > 0.01) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }
    return found;
  }

  void resetPlayerPath() {
    playerPath.clear();
    currentStatus = "Camino reiniciado. Empieza de nuevo en la Fuente (" + sourceNode.name + ").";
  }
}
