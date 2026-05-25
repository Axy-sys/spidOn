class DialogueBubble {

  float x;
  float y;
  String message;

  float timer = 0;
  float duration = 220;
  boolean finished = false;

  int offsetIndex = 0;

  DialogueBubble(float x, float y, String message, int offsetIndex) {
    this.x = x;
    this.y = y;
    this.message = message;
    this.offsetIndex = offsetIndex;
  }

  void update() {
    timer++;
    y -= 0.08;

    if (timer >= duration) {
      finished = true;
    }
  }

  void render() {

    float alpha = 255;

    if (timer > duration - 50) {
      alpha = map(timer, duration - 50, duration, 255, 0);
    }

    textSize(13);

    float w = max(150, textWidth(message) + 34);
    float h = 46;
    float offsetY = offsetIndex * -52;

    noStroke();
    fill(0, alpha * 0.35);
    rect(x - w/2 + 3, y - h/2 + 3 + offsetY, w, h, 10);

    fill(255, alpha);
    stroke(0, alpha);
    strokeWeight(2);
    rect(x - w/2, y - h/2 + offsetY, w, h, 10);

    noStroke();
    fill(255, alpha);
    triangle(
      x - 10, y + h/2 + offsetY,
      x + 10, y + h/2 + offsetY,
      x, y + h/2 + 12 + offsetY
    );

    fill(0, alpha);
    textAlign(CENTER, CENTER);
    text(message, x, y + offsetY);
  }
}
