class MissionSelectScene extends Scene {

  int selectedMission = 0;
  int noticeTimer = 0;
  String noticeMessage = "";

  String[] missions = {
    "MISIÓN 01",
    "MISIÓN 02",
    "MISIÓN 03",
    "MISIÓN 04",
    "MISIÓN FINAL"
  };

  String[] subtitles = {
    "Rastros del Acoso",
    "Ruta Segura",
    "Reconstruir la Red",
    "Control del Impacto",
    "Red Segura"
  };

  String[] descriptions = {
    "Usa BFS y DFS para rastrear cómo se propaga el ciberacoso.",
    "Encuentra la ruta más segura para intervenir y proteger a la víctima.",
    "Reconstruye conexiones positivas con el menor costo posible.",
    "Controla la cantidad de contenido dañino que circula en la red.",
    "Integra todo lo aprendido para restaurar completamente la red."
  };

  boolean[] unlocked = {
    true,
    false,
    false,
    false,
    false
  };

  void enter() {
    selectedMission = 0;
    noticeTimer = 0;
    noticeMessage = "";
    if (game != null && game.unlockedMissions != null) {
      for (int i = 0; i < unlocked.length; i++) {
        unlocked[i] = game.unlockedMissions[i];
      }
    }
  }

  void update() {

    if (noticeTimer > 0) {
      noticeTimer--;
      if (noticeTimer == 0) noticeMessage = "";
    }
  }

  void render() {

    background(5, 10, 20);
    drawGrid();

    fill(0, 255, 255);
    textAlign(CENTER, CENTER);
    textSize(54);
    text("SELECCIÓN DE MISIÓN", width/2, 100);

    fill(255);
    textSize(18);
    text("EVA: Se detectó una campaña de ciberacoso dentro de la red.", width/2, 160);
    text("Elige una misión para investigar y proteger a los usuarios.", width/2, 190);

    for (int i = 0; i < missions.length; i++) {

      float y = 270 + i * 100;

      if (i == selectedMission) {
        fill(0, 255, 255);
        rect(width/2 - 320, y - 35, 640, 70, 12);
        fill(0);
      } else if (unlocked[i]) {
        fill(255);
      } else {
        fill(120);
      }

      textSize(28);
      text(missions[i], width/2, y - 10);

      textSize(16);
      text(subtitles[i], width/2, y + 18);

      fill(180);
      textSize(12);
      text(descriptions[i], width/2, y + 42);
    }

    if (noticeMessage.length() > 0) {
      fill(255, 0, 80);
      textSize(18);
      text(noticeMessage, width/2, height - 120);
    }

    fill(180);
    textSize(16);
    text("ARRIBA / ABAJO PARA NAVEGAR", width/2, height - 70);
    text("ENTER PARA INICIAR", width/2, height - 40);
  }

  void keyPressed() {

    if (keyCode == DOWN) {
      selectedMission++;
      if (selectedMission >= missions.length) selectedMission = 0;
    }

    if (keyCode == UP) {
      selectedMission--;
      if (selectedMission < 0) selectedMission = missions.length - 1;
    }

    if (key == ENTER || key == RETURN) {

      if (unlocked[selectedMission]) {
        game.sceneManager.changeScene(new MissionScene(selectedMission + 1));
      } else {
        noticeMessage = "MISIÓN BLOQUEADA — completa la anterior primero.";
        noticeTimer = 120;
      }
    }
  }

  void drawGrid() {

    stroke(0, 80, 120, 35);

    float offset = frameCount * 0.3;

    for (int x = -3000; x < 3000; x += 50) {
      line(x + offset % 50, -3000, x + offset % 50, 3000);
    }

    for (int y = -3000; y < 3000; y += 50) {
      line(-3000, y + offset % 50, 3000, y + offset % 50);
    }
  }
}
