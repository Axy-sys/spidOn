import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;

class KruskalMST {

  ArrayList<Node> nodes;
  ArrayList<Edge> edges;

  // Step-by-step state
  ArrayList<Edge> sortedEdges;
  ArrayList<String> decisionHistory;
  UnionFind uf;
  int edgeIndex = 0;
  float totalCost = 0;
  int edgesAdded = 0;
  boolean running = false;
  boolean finished = false;
  Edge currentEdge = null;
  String currentStatus = "No iniciado";

  boolean manualMode = false;
  boolean waitingForDecision = false;

  KruskalMST(ArrayList<Node> nodes, ArrayList<Edge> edges) {
    this.nodes = nodes;
    this.edges = edges;
    sortedEdges = new ArrayList<Edge>();
    decisionHistory = new ArrayList<String>();
  }

  // Runs Kruskal instantly and returns total cost
  float calculateMST() {
    startStepByStep();
    while (running) {
      step();
    }
    return totalCost;
  }

  void startStepByStep() {
    this.running = true;
    this.finished = false;
    this.edgeIndex = 0;
    this.totalCost = 0;
    this.edgesAdded = 0;
    this.currentEdge = null;
    this.currentStatus = "Inicializando Kruskal. Ordenando aristas...";
    this.decisionHistory.clear();
    this.waitingForDecision = false;

    for (Edge e : edges) {
      e.partOfMST = false;
    }

    uf = new UnionFind(nodes);

    // Pre-accept Dijkstra safest path edges if in Mission 5 Stage 3
    if (game != null && game.sceneManager.currentScene != null && game.sceneManager.currentScene instanceof MissionScene) {
      MissionScene ms = (MissionScene) game.sceneManager.currentScene;
      if (ms.missionID == 5 && ms.missionStage == 3 && ms.dijkstraPath != null && ms.dijkstraPath.size() > 1) {
        for (int i = 0; i < ms.dijkstraPath.size() - 1; i++) {
          Node u = ms.dijkstraPath.get(i);
          Node v = ms.dijkstraPath.get(i + 1);
          Edge e = getEdge(u, v);
          if (e != null) {
            e.partOfMST = true;
            uf.union(u, v);
            totalCost += e.cost;
            edgesAdded++;
            decisionHistory.add(u.name + " - " + v.name + " (Costo " + (int)e.cost + "): CONECTADO (Ruta Segura)");
          }
        }
      }
    }

    sortedEdges.clear();
    for (Edge e : edges) {
      if (!e.blocked && !e.partOfMST) {
        sortedEdges.add(e);
      }
    }

    Collections.sort(sortedEdges, new Comparator<Edge>() {
      public int compare(Edge e1, Edge e2) {
        return Float.compare(e1.cost, e2.cost);
      }
    });
  }

  boolean step() {
    if (!running || finished) return true;

    if (edgeIndex >= sortedEdges.size() || edgesAdded == nodes.size() - 1) {
      running = false;
      finished = true;
      currentEdge = null;
      waitingForDecision = false;
      if (edgesAdded < nodes.size() - 1) {
        currentStatus = "Kruskal terminado. Red fragmentada: MST incompleto. Costo: " + (int)totalCost;
      } else {
        currentStatus = "Kruskal terminado. Árbol de Expansión Mínima trazado. Costo: " + (int)totalCost;
      }
      return true;
    }

    Edge e = sortedEdges.get(edgeIndex);
    currentEdge = e;

    if (manualMode) {
      waitingForDecision = true;
      currentStatus = "Analizando conexión " + e.a.name + " - " + e.b.name + " (Costo: " + (int)e.cost + "). ¿Aceptar o Rechazar?";
      return false; // Wait for manual choice
    }

    if (uf.union(e.a, e.b)) {
      e.partOfMST = true;
      totalCost += e.cost;
      edgesAdded++;
      decisionHistory.add(e.a.name + " - " + e.b.name + " (Costo " + (int)e.cost + "): CONECTADO");
    } else {
      decisionHistory.add(e.a.name + " - " + e.b.name + " (Costo " + (int)e.cost + "): RECHAZADO (Ciclo)");
    }

    edgeIndex++;
    return false;
  }

  void makeDecision(boolean accept) {
    if (!waitingForDecision || currentEdge == null) return;

    Edge e = currentEdge;
    boolean formsCycle = (uf.find(e.a) == uf.find(e.b));
    boolean correct = false;

    if (accept) {
      if (!formsCycle) {
        uf.union(e.a, e.b);
        e.partOfMST = true;
        totalCost += e.cost;
        edgesAdded++;
        decisionHistory.add(e.a.name + " - " + e.b.name + " (Costo " + (int)e.cost + "): CONECTADO");
        correct = true;
      } else {
        decisionHistory.add(e.a.name + " - " + e.b.name + " (Costo " + (int)e.cost + "): RECHAZADO (Ciclo)");
        correct = false;
      }
    } else {
      if (formsCycle) {
        decisionHistory.add(e.a.name + " - " + e.b.name + " (Costo " + (int)e.cost + "): RECHAZADO (Ciclo)");
        correct = true;
      } else {
        uf.union(e.a, e.b);
        e.partOfMST = true;
        totalCost += e.cost;
        edgesAdded++;
        decisionHistory.add(e.a.name + " - " + e.b.name + " (Costo " + (int)e.cost + "): CONECTADO (Forzado)");
        correct = false;
      }
    }

    if (game != null && game.sceneManager.currentScene instanceof MissionScene) {
      MissionScene ms = (MissionScene) game.sceneManager.currentScene;
      if (correct) {
        ms.score += 500;
        soundManager.playCorrectDecision();
        ms.dialogueSystem.eva("¡Excelente elección! " + (accept ? "Esa arista conecta sin hacer ciclos." : "Evitamos un ciclo en la red."));
        ms.triggerAlert("+500 PUNTOS");
      } else {
        ms.score = max(0, ms.score - 300);
        ms.loseShield();
        ms.dialogueSystem.eva("Oh... " + (accept ? "Esa conexión creaba un bucle redundante en el árbol." : "Teníamos que aceptar esa conexión para asegurar la cobertura."));
      }
    } else {
      if (correct) {
        soundManager.playSuccess();
      } else {
        soundManager.playError();
      }
    }

    waitingForDecision = false;
    edgeIndex++;

    if (edgeIndex >= sortedEdges.size() || edgesAdded == nodes.size() - 1) {
      running = false;
      finished = true;
      currentEdge = null;
      if (edgesAdded < nodes.size() - 1) {
        currentStatus = "Kruskal terminado. Red fragmentada: MST incompleto. Costo: " + (int)totalCost;
      } else {
        currentStatus = "Kruskal terminado. Árbol de Expansión Mínima trazado. Costo: " + (int)totalCost;
      }
      if (game != null && game.sceneManager.currentScene instanceof MissionScene) {
        MissionScene ms = (MissionScene) game.sceneManager.currentScene;
        ms.mstCost = totalCost;
      }
    } else {
      step();
    }
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

// Disjoint Set Union (DSU) helper class for Kruskal's algorithm
class UnionFind {
  HashMap<Node, Node> parent = new HashMap<Node, Node>();

  UnionFind(ArrayList<Node> nodes) {
    for (Node n : nodes) {
      parent.put(n, n);
    }
  }

  Node find(Node n) {
    Node p = parent.get(n);
    if (p == n) return n;
    
    // Path compression
    Node root = find(p);
    parent.put(n, root);
    return root;
  }

  boolean union(Node a, Node b) {
    Node rootA = find(a);
    Node rootB = find(b);
    if (rootA != rootB) {
      parent.put(rootA, rootB); // Union rootA to rootB
      return true;
    }
    return false;
  }
}
