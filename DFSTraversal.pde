class DFSTraversal implements TraversalStrategy {

  ArrayList<Node> nodes;
  ArrayList<Edge> edges;
  ArrayList<Signal> signals;
  DialogueSystem dialogueSystem;
  MessageLog messageLog;

  ArrayList<Node> visitedNodes;
  ArrayList<Node> stack;

  Node current;
  Node origin;

  boolean running = false;
  boolean completionAnnounced = false;

  int timer = 0;
  int stepDelay = 35;
  boolean autoPlay = true;
  boolean stepRequested = false;

  float deepPulse = 0;

  DFSTraversal(
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
    stack = new ArrayList<Node>();
  }

  void start(Node start) {

    if (start == null) return;

    reset();

    running = true;
    origin = start;
    current = start;
    deepPulse = 0;
    completionAnnounced = false;

    start.visited = true;
    start.level = 0;

    stack.add(start);
    visitedNodes.add(start);

    dialogueSystem.eva("DFS activado.");
    dialogueSystem.eva("Seguiremos la cadena más profunda.");
  }

  void update() {

    if (!running) return;

    deepPulse += 3.5;

    if (!autoPlay) {
      if (!stepRequested) return;
      stepRequested = false;
    } else {
      timer++;
      if (timer < stepDelay) return;
      timer = 0;
    }

    if (stack.size() == 0) {

      running = false;

      if (!completionAnnounced) {
        dialogueSystem.eva("Recorrido DFS completado.");
        completionAnnounced = true;
      }

      return;
    }

    current = stack.remove(stack.size() - 1);
    processNeighbors(current);
  }

  void processNeighbors(Node node) {

    for (int i = node.neighbors.size() - 1; i >= 0; i--) {

      Node neighbor = node.neighbors.get(i);

      if (neighbor.visited) continue;

      neighbor.visited = true;
      neighbor.level = node.level + 1;

      stack.add(neighbor);
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
    stroke(0, 255, 120, 90);
    strokeWeight(4);

    ellipse(
      origin.x,
      origin.y,
      60 + sin(deepPulse * 0.02) * 8,
      60 + sin(deepPulse * 0.02) * 8
    );

    stroke(0, 255, 120, 25);
    strokeWeight(1);

    ellipse(
      origin.x,
      origin.y,
      100 + sin(deepPulse * 0.015) * 12,
      100 + sin(deepPulse * 0.015) * 12
    );

    if (current != null) {
      stroke(0, 255, 120, 80);
      strokeWeight(2);
      line(origin.x, origin.y, current.x, current.y);
    }

    for (Node n : visitedNodes) {

      float rr = 50 + n.level * 5;

      if (n == current) {
        stroke(255, 255, 255, 220);
        strokeWeight(3);
      } else if (n == origin) {
        stroke(0, 255, 120, 180);
        strokeWeight(3);
      } else {
        stroke(0, 255, 120, 120);
        strokeWeight(2);
      }

      noFill();
      ellipse(n.x, n.y, rr, rr);

      fill(255);
      noStroke();
      textAlign(CENTER, CENTER);
      textSize(10);
      text("D" + n.level, n.x, n.y - 38);
    }

    popStyle();
  }

  void reset() {

    running = false;
    completionAnnounced = false;
    timer = 0;
    deepPulse = 0;

    stack.clear();
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
      "cadena analizada",
      "ruta revisada"
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
