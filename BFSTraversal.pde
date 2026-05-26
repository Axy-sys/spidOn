class BFSTraversal implements TraversalStrategy {

  ArrayList<Node> nodes;
  ArrayList<Edge> edges;
  ArrayList<Signal> signals;
  DialogueSystem dialogueSystem;
  MessageLog messageLog;

  ArrayList<Node> visitedNodes;
  ArrayList<Node> queue;

  Node current;
  Node origin;

  boolean running = false;
  boolean completionAnnounced = false;

  int timer = 0;
  int stepDelay = 32;
  boolean autoPlay = false;
  boolean stepRequested = false;

  float waveRadius = 0;
  float waveSpeed = 5.2;

  BFSTraversal(
    ArrayList<Node> nodes,
    ArrayList<Edge> edges,
    ArrayList<Signal> signals,
    DialogueSystem dialogueSystem,
    MessageLog messageLog
  ) {
    this.nodes = nodes;
    this.edges = edges;
    this.signals = signals;
    this.dialogueSystem = dialogueSystem;
    this.messageLog = messageLog;

    visitedNodes = new ArrayList<Node>();
    queue = new ArrayList<Node>();
  }

  void start(Node start) {

    if (start == null) return;

    reset();

    running = true;
    origin = start;
    current = start;
    waveRadius = 60;
    completionAnnounced = false;

    start.visited = true;
    start.level = 0;

    queue.add(start);
    visitedNodes.add(start);

    // Pop origin immediately to enqueue neighbors
    queue.remove(0);
    processNeighbors(start);

    dialogueSystem.eva("Rastreo por niveles iniciado.");
    dialogueSystem.eva("BFS nos ayuda a ver cómo se expande el acoso.");

    if (messageLog != null) {
      messageLog.add("EVA", start.name, "Rastreo por niveles iniciado", 2);
    }
  }

  void update() {

    if (!running) return;

    waveRadius += waveSpeed;

    if (!autoPlay) {
      if (!stepRequested) return;
      stepRequested = false;
    } else {
      timer++;
      if (timer < stepDelay) return;
      timer = 0;
    }

    if (queue.size() == 0) {

      running = false;

      if (!completionAnnounced) {
        dialogueSystem.eva("Recorrido BFS completado.");
        completionAnnounced = true;
      }

      return;
    }

    current = queue.remove(0);

    dialogueSystem.eva("Analizando: " + current.name + "...");

    if (messageLog != null) {
      messageLog.add("EVA", current.name, "Analizando " + current.name, 2);
    }

    processNeighbors(current);
  }

  void processNeighbors(Node node) {

    for (Node neighbor : node.neighbors) {

      if (neighbor.visited) continue;

      neighbor.visited = true;
      neighbor.level = node.level + 1;

      queue.add(neighbor);
      visitedNodes.add(neighbor);

      String msg = getTraversalMessage(node);
      int c = getTraversalColor(node);

      if (signals.size() < 10) {
        signals.add(
          new Signal(
            node,
            neighbor,
            msg,
            c
          )
        );
      }

      if (messageLog != null) {

        int type = 2;

        if (node.infected) {
          type = 0;
        } else if (node.supportive) {
          type = 1;
        }

        messageLog.add(
          node.name,
          neighbor.name,
          msg,
          type
        );
      }

      dialogueSystem.say(
        neighbor.x,
        neighbor.y - 55,
        msg + " (N" + neighbor.level + ")"
      );
    }
  }

  void render() {

    if (origin == null) return;

    pushStyle();

    noFill();
    stroke(0, 255, 255, 90);
    strokeWeight(4);

    ellipse(
      origin.x,
      origin.y,
      waveRadius,
      waveRadius
    );

    stroke(0, 255, 255, 30);
    strokeWeight(1);

    ellipse(
      origin.x,
      origin.y,
      waveRadius * 1.2,
      waveRadius * 1.2
    );

    for (Node n : visitedNodes) {

      float rr = 54 + n.level * 5;

      if (n == current) {
        stroke(255, 255, 255, 220);
        strokeWeight(3);
      } else if (n == origin) {
        stroke(0, 255, 255, 180);
        strokeWeight(3);
      } else {
        stroke(0, 255, 255, 110);
        strokeWeight(2);
      }

      noFill();
      ellipse(n.x, n.y, rr, rr);

      fill(255);
      noStroke();
      textAlign(CENTER, CENTER);
      textSize(10);
      text("N" + n.level, n.x, n.y - 38);
    }

    popStyle();
  }

  void reset() {

    running = false;
    completionAnnounced = false;
    timer = 0;
    waveRadius = 0;

    queue.clear();
    visitedNodes.clear();

    for (Node n : nodes) {
      n.visited = false;
      n.level = -1;
    }

    current = null;
    origin = null;
  }

  boolean isRunning() {
    return running;
  }

  ArrayList<Node> getVisitedNodes() {
    return visitedNodes;
  }

  String getTraversalMessage(Node from) {

    if (from.infected) {
      String[] toxic = {
        "mira esto",
        "compártelo",
        "qué vergüenza",
        "nadie te toma en serio",
        "deberías borrarlo"
      };
      return toxic[int(random(toxic.length))];
    }

    if (from.supportive) {
      String[] support = {
        "no estás sola",
        "te apoyamos",
        "ya reporté esto",
        "vamos a ayudarte",
        "respira, estamos contigo"
      };
      return support[int(random(support.length))];
    }

    String[] neutral = {
      "mensaje detectado",
      "interacción revisada",
      "ruta analizada"
    };

    return neutral[int(random(neutral.length))];
  }

  int getTraversalColor(Node from) {

    if (from.infected) {
      return color(255, 60, 80);
    }

    if (from.supportive) {
      return color(0, 255, 120);
    }

    return color(0, 255, 255);
  }
}
