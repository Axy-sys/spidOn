class Particle {

  float x;
  float y;

  float speedX;
  float speedY;

  float size;
  float alpha;
  float pulse;

  color col = color(0, 180, 255);
  boolean isBackground = true;

  Particle() {
    x = random(-3000, 3000);
    y = random(-3000, 3000);

    speedX = random(-0.15, 0.15);
    speedY = random(0.2, 1.2);

    size = random(2, 5);
    alpha = random(40, 120);
    pulse = random(TWO_PI);
  }

  Particle(float x, float y, color col) {
    this.x = x;
    this.y = y;
    this.col = col;
    this.speedX = random(-3, 3);
    this.speedY = random(-3, 3);
    this.size = random(4, 8);
    this.alpha = 255;
    this.isBackground = false;
  }

  void update() {
    x += speedX;
    y += speedY;
    pulse += 0.03;

    if (isBackground) {
      if (y > 3000) {
        y = -3000;
      }
      if (x < -3000) {
        x = 3000;
      }
      if (x > 3000) {
        x = -3000;
      }
    } else {
      alpha -= 4; // fade out
    }
  }

  void render() {
    if (alpha <= 0) return;
    noStroke();
    if (isBackground) {
      fill(0, 180, 255, alpha);
    } else {
      fill(col, alpha);
    }
    ellipse(x, y, size, size);
  }
}
