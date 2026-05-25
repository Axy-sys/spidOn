class IntroScene extends Scene {

  String[] dialogue = {
    "EVA INICIADA...",
    "Se detectó una campaña de ciberacoso.",
    "Varias cuentas están enviando mensajes dañinos.",
    "Algunos usuarios ya están siendo afectados.",
    "Necesitamos rastrear cómo se propaga el acoso.",
    "Luego deberemos contener el daño antes de que la red colapse."
  };

  int currentLine = 0;
  float pulse = 0;

  void enter() {
    currentLine = 0;
    pulse = 0;
  }

  void update() {
    pulse += 0.04;
  }

  void render() {

    background(0);

    noStroke();
    fill(0, 255, 255, 35);
    ellipse(width/2, height/2, 420, 420);

    fill(0, 255, 255, 18);
    ellipse(width/2, height/2, 620, 620);

    fill(255);
    textAlign(CENTER, CENTER);

    textSize(34);
    text(dialogue[currentLine], width/2, height/2 - 10);

    textSize(18);
    fill(0, 255, 255);
    text("[ ESPACIO ] CONTINUAR", width/2, height - 100);

    fill(200);
    textSize(14);
    text("Presiona ESPACIO para avanzar la narrativa", width/2, height - 70);

    stroke(0, 255, 255, 80);
    noFill();
    ellipse(width/2, height/2, 240 + sin(pulse) * 10, 240 + sin(pulse) * 10);
  }

  void keyPressed() {

    if (key == ' ') {
      currentLine++;

      if (currentLine >= dialogue.length) {
        game.sceneManager.changeScene(new MissionSelectScene());
      }
    }
  }
}
