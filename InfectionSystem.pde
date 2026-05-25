class InfectionSystem {

  ArrayList<Node> nodes;
  ArrayList<Edge> edges;
  ArrayList<Signal> signals;
  DialogueSystem dialogueSystem;
  MessageLog messageLog;

  int timer = 0;
  int interval = 180;

  boolean active = false;
  boolean failed = false;

  InfectionSystem(
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
  }

  void setActive(boolean active) {
    this.active = active;
  }

  void setInterval(int interval) {
    this.interval = interval;
  }

  void update() {

    if (!active || failed) return;

    timer++;

    if (timer < interval) return;
    timer = 0;

    spreadInfection();
    checkFailure();
  }

  void spreadInfection() {

    ArrayList<Node> newlyInfected = new ArrayList<Node>();

    for (Node n : nodes) {

      if (!n.infected) continue;

      for (Node neighbor : n.neighbors) {

        if (neighbor.infected) continue;
        if (isBlocked(n, neighbor)) continue;

        if (random(1) < 0.35) {
          newlyInfected.add(neighbor);

          String msg = getRandomToxicMessage();

          if (signals.size() < 8) {
            signals.add(new Signal(n, neighbor, msg, color(255, 60, 80)));
          }

          if (messageLog != null) {
            messageLog.add(n.name, neighbor.name, msg, 0);
          }

          dialogueSystem.say(
            neighbor.x,
            neighbor.y - 60,
            "Usuarios afectados"
          );
        }
      }
    }

    for (Node n : newlyInfected) {
      n.infected = true;
      n.stress = constrain(n.stress + 25, 0, 100);
      n.toxicity = constrain(n.toxicity + 30, 0, 100);
    }
  }

  boolean isBlocked(Node a, Node b) {

    for (Edge e : edges) {

      boolean sameConnection =
        (e.a == a && e.b == b) ||
        (e.a == b && e.b == a);

      if (sameConnection && e.blocked) return true;
    }

    return false;
  }

  void checkFailure() {

    int infectedCount = 0;

    for (Node n : nodes) {
      if (n.infected) infectedCount++;
    }

    if (infectedCount >= nodes.size() * 0.75) {
      failed = true;
      dialogueSystem.alert("La red está a punto de colapsar.");
    }
  }

  boolean hasFailed() {
    return failed;
  }

  int getTimer() {
    return timer;
  }

  int getInterval() {
    return interval;
  }

  String getRandomToxicMessage() {

    String[] toxic = {
      "todos vieron eso",
      "comparte esto",
      "qué vergüenza",
      "mira lo que publicó",
      "deberías borrarlo",
      "nadie te toma en serio",
      "esto se está saliendo de control",
      "ya déjenla en paz"
    };

    return toxic[int(random(toxic.length))];
  }
}
