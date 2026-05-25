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
}
