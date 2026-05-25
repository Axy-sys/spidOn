class EmotionSystem {

  ArrayList<Node> nodes;
  DialogueSystem dialogueSystem;

  int timer = 0;
  int interval = 90;

  EmotionSystem(ArrayList<Node> nodes, DialogueSystem dialogueSystem) {
    this.nodes = nodes;
    this.dialogueSystem = dialogueSystem;
  }

  void update() {

    timer++;

    if (timer < interval) return;
    timer = 0;

    for (Node n : nodes) {

      if (n.infected) {
        n.stress = constrain(n.stress + 4, 0, 100);
        n.toxicity = constrain(n.toxicity + 2, 0, 100);
        n.support = constrain(n.support - 1, 0, 100);
      }

      if (n.supportive) {
        n.support = constrain(n.support + 2, 0, 100);
        n.stress = constrain(n.stress - 2, 0, 100);
      }

      if (!n.infected && n.stress > 70 && !n.supportive) {
        n.vulnerable = true;
      }

      if (n.support > 75 && !n.infected) {
        n.supportive = true;
      }

      if (n.stress < 35 && n.support > 55 && !n.infected) {
        n.vulnerable = false;
      }
    }

    applySupportRecovery();
  }

  void applySupportRecovery() {

    for (Node n : nodes) {

      if (!n.supportive) continue;

      for (Node neighbor : n.neighbors) {

        if (neighbor.infected) continue;

        neighbor.stress = constrain(neighbor.stress - 1.5, 0, 100);
        neighbor.support = constrain(neighbor.support + 1.2, 0, 100);

        if (neighbor.stress < 45 && neighbor.vulnerable) {
          neighbor.vulnerable = false;
        }
      }
    }
  }
}
