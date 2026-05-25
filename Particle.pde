class Particle {

  float x;
  float y;

  float speedX;
  float speedY;

  float size;
  float alpha;
  float pulse;

  Particle() {
    x = random(-3000, 3000);
    y = random(-3000, 3000);

    speedX = random(-0.15, 0.15);
    speedY = random(0.2, 1.2);

    size = random(2, 5);
    alpha = random(40, 120);
    pulse = random(TWO_PI);
  }

  void update() {
    x += speedX;
    y += speedY;
    pulse += 0.03;

    if (y > 3000) {
      y = -3000;
    }

    if (x < -3000) {
      x = 3000;
    }

    if (x > 3000) {
      x = -3000;
    }
  }

  void render() {
    noStroke();
    fill(0, 180, 255, alpha);
    ellipse(x, y, size, size);
  }
}
