class Signal {

  Node from;
  Node to;

  String message;
  int signalColor;

  float progress = 0;
  boolean finished = false;
  float speed = 0.02;
  float pulse = random(TWO_PI);

  Signal(Node from, Node to, String message, int signalColor) {
    this.from = from;
    this.to = to;
    this.message = message;
    this.signalColor = signalColor;
  }

  void update() {
    progress += speed;
    if (progress >= 1) {
      progress = 1;
      finished = true;
    }
  }

  void render() {

    pushStyle();

    float x = lerp(from.x, to.x, progress);
    float y = lerp(from.y, to.y, progress);

    float p = 1 + sin(frameCount * 0.2 + pulse) * 0.15;

    stroke(signalColor, 80);
    strokeWeight(2);
    line(from.x, from.y, x, y);

    noStroke();

    fill(signalColor, 35);
    ellipse(x, y, 42 * p, 42 * p);

    fill(signalColor, 90);
    ellipse(x, y, 22 * p, 22 * p);

    fill(signalColor);
    ellipse(x, y, 10, 10);

    textSize(12);
    float boxW = max(90, textWidth(message) + 26);
    float boxH = 26;

    fill(0, 210);
    rect(x - boxW/2, y - 42, boxW, boxH, 10);

    stroke(signalColor);
    noFill();
    rect(x - boxW/2, y - 42, boxW, boxH, 10);

    fill(255);
    textAlign(CENTER, CENTER);
    text(message, x, y - 29);

    popStyle();
  }
}
