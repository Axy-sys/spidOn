class MenuNode {
  PVector pos;
  PVector vel;
  float radius;
  String name;
  boolean hovered = false;
  float pulse = 0;

  MenuNode(float x, float y, float r, String name) {
    this.pos = new PVector(x, y);
    this.vel = new PVector(random(-0.8, 0.8), random(-0.8, 0.8));
    this.radius = r;
    this.name = name;
  }

  void update() {
    pos.add(vel);
    if (pos.x < radius || pos.x > width - radius) vel.x *= -1;
    if (pos.y < radius || pos.y > height - radius) vel.y *= -1;
    pos.x = constrain(pos.x, radius, width - radius);
    pos.y = constrain(pos.y, radius, height - radius);
    pulse += 0.05;
  }

  void checkHover(float mx, float my) {
    hovered = dist(mx, my, pos.x, pos.y) < radius;
  }

  void render() {
    pushStyle();
    noStroke();
    float rPulse = radius + sin(pulse) * 2;
    
    // Outer glow
    if (colorblindMode) {
      fill(247, 247, 247, hovered ? 45 : 15);
    } else {
      fill(0, 255, 255, hovered ? 45 : 15);
    }
    ellipse(pos.x, pos.y, rPulse * 2.8, rPulse * 2.8);

    // Core circle
    strokeWeight(2.5);
    if (colorblindMode) {
      stroke(247, 247, 247);
      fill(20, 20, 20);
    } else {
      stroke(0, 220, 255);
      fill(10, 30, 50);
    }
    ellipse(pos.x, pos.y, rPulse * 2, rPulse * 2);

    // Label
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(largeTextMode ? 14 : 11);
    text(name, pos.x, pos.y);
    popStyle();
  }

  PVector pos() {
    return pos;
  }
}

class MenuScene extends Scene {

  ArrayList<MenuNode> menuNodes;
  LeaderboardManager leaderboardManager;
  int hoverOption = -1;
  float globalPulse = 0;
  
  // Overlay state flags
  boolean showingAccessibility = false;
  boolean showingLeaderboard = false;
  int hoverOverlayButton = -1;

  void enter() {
    hoverOption = -1;
    globalPulse = 0;
    showingAccessibility = false;
    showingLeaderboard = false;
    hoverOverlayButton = -1;

    // Load leaderboard
    leaderboardManager = new LeaderboardManager(sketchPath("data/leaderboard.txt"));

    // Create decorative floating nodes
    menuNodes = new ArrayList<MenuNode>();
    String[] names = {"Alicia", "Bruno", "Carla", "Diego", "Ghost", "Valeria", "Sara", "Andrés", "EVA", "Red", "Segura", "spidOn"};
    for (int i = 0; i < names.length; i++) {
      menuNodes.add(new MenuNode(random(100, width - 100), random(100, height - 100), 28, names[i]));
    }
  }

  void update() {
    globalPulse += 0.04;

    for (MenuNode mn : menuNodes) {
      mn.update();
      mn.checkHover(mouseX, mouseY);
    }

    int prevHover = hoverOption;
    int prevOverlayHover = hoverOverlayButton;

    if (showingAccessibility || showingLeaderboard) {
      updateOverlayHover();
    } else {
      updateHover();
    }

    if ((hoverOption != prevHover && hoverOption != -1) || 
        (hoverOverlayButton != prevOverlayHover && hoverOverlayButton != -1)) {
      soundManager.playClick();
    }
  }

  void render() {
    background(5, 10, 20);

    // Draw grid
    stroke(0, 80, 120, 25);
    for (int i = 0; i < width; i += 60) line(i, 0, i, height);
    for (int j = 0; j < height; j += 60) line(0, j, width, j);

    // Draw connection web between close floating nodes
    for (int i = 0; i < menuNodes.size(); i++) {
      for (int j = i + 1; j < menuNodes.size(); j++) {
        MenuNode n1 = menuNodes.get(i);
        MenuNode n2 = menuNodes.get(j);
        float d = dist(n1.pos.x, n1.pos.y, n2.pos.x, n2.pos.y);
        if (d < 180) {
          float alpha = map(d, 0, 180, 80, 0);
          stroke(0, 180, 255, alpha);
          strokeWeight(map(d, 0, 180, 2, 0.5));
          line(n1.pos.x, n1.pos.y, n2.pos.x, n2.pos.y);
        }
      }
    }

    // Render floating nodes
    for (MenuNode mn : menuNodes) {
      mn.render();
    }

    // Scanline cyber bar effect
    float barY = (frameCount * 1.5) % height;
    stroke(0, 255, 255, 12);
    strokeWeight(3);
    line(0, barY, width, barY);

    // Title area glow
    float g = 40 + sin(globalPulse) * 10;
    noStroke();
    if (colorblindMode) {
      fill(255, 25);
    } else {
      fill(0, 255, 255, 15);
    }
    ellipse(width/2, 160, 420 + g, 140 + g * 0.4);

    // Title Text
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(80);
    text("spidOn", width/2, 140);

    textSize(20);
    fill(colorblindMode ? color(253, 184, 99) : color(0, 255, 255));
    text("CAMPAÑA CONTRA EL CIBERACOSO", width/2, 215);

    textSize(16);
    fill(200);
    text("Rastrea. Protege. Conecta. Salva la red.", width/2, 260);

    // Render Buttons
    String[] options = {
      "[ 🟢 INICIAR CAMPAÑA ]",
      "[ 🛠️ CREAR RED (SANDBOX) ]",
      "[ ⚔️ DUELO LOCAL (1v1) ]",
      "[ ♿ ACCESIBILIDAD & AJUSTES ]",
      "[ 🏆 MEJORES PUNTAJES ]",
      "[ ❌ SALIR DEL JUEGO ]"
    };

    float startY = 320;
    float btnW = 360;
    float btnH = 46;
    float gap = 16;

    for (int i = 0; i < options.length; i++) {
      float y = startY + i * (btnH + gap);
      drawButton(width/2 - btnW/2, y, btnW, btnH, options[i], hoverOption == i);
    }

    // Footer info
    fill(130);
    textSize(largeTextMode ? 14 : 11);
    text("Proyecto Laboratorio Estructura de Datos II  ·  Mueve el mouse para interactuar", width/2, height - 25);

    // Draw Overlays
    if (showingAccessibility) {
      renderAccessibilityOverlay();
    } else if (showingLeaderboard) {
      renderLeaderboardOverlay();
    }
  }

  void drawButton(float x, float y, float w, float h, String label, boolean active) {
    pushStyle();
    noStroke();
    if (active) {
      if (colorblindMode) {
        fill(247, 247, 247);
        rect(x, y, w, h, 14);
        fill(0);
      } else {
        fill(0, 255, 255);
        rect(x, y, w, h, 14);
        fill(0);
      }
    } else {
      fill(14, 22, 40, 220);
      rect(x, y, w, h, 14);
      stroke(0, 150, 255, 80);
      strokeWeight(1.5);
      noFill();
      rect(x, y, w, h, 14);
      fill(255);
    }

    textAlign(CENTER, CENTER);
    textSize(largeTextMode ? 18 : 15);
    text(label, x + w/2, y + h/2);
    popStyle();
  }

  void updateHover() {
    hoverOption = -1;
    float startY = 320;
    float btnW = 360;
    float btnH = 46;
    float gap = 16;

    for (int i = 0; i < 6; i++) {
      float y = startY + i * (btnH + gap);
      if (mouseX > width/2 - btnW/2 && mouseX < width/2 + btnW/2 &&
          mouseY > y && mouseY < y + btnH) {
        hoverOption = i;
        break;
      }
    }
  }

  void updateOverlayHover() {
    hoverOverlayButton = -1;
    float cx = width/2;
    float cy = height/2;

    if (showingAccessibility) {
      // Toggle colorblind: cx - 180, cy - 60, 360, 36
      if (mouseX > cx - 180 && mouseX < cx + 180 && mouseY > cy - 60 && mouseY < cy - 24) hoverOverlayButton = 0;
      // Toggle large text: cx - 180, cy - 10, 360, 36
      if (mouseX > cx - 180 && mouseX < cx + 180 && mouseY > cy - 10 && mouseY < cy + 26) hoverOverlayButton = 1;
      // Cycle text speed: cx - 180, cy + 40, 360, 36
      if (mouseX > cx - 180 && mouseX < cx + 180 && mouseY > cy + 40 && mouseY < cy + 76) hoverOverlayButton = 2;
      // Close button: cx - 80, cy + 110, 160, 36
      if (mouseX > cx - 80 && mouseX < cx + 80 && mouseY > cy + 110 && mouseY < cy + 146) hoverOverlayButton = 3;
    } else if (showingLeaderboard) {
      // Close button: cx - 80, cy + 140, 160, 36
      if (mouseX > cx - 80 && mouseX < cx + 80 && mouseY > cy + 140 && mouseY < cy + 176) hoverOverlayButton = 0;
    }
  }

  void mousePressed() {
    if (showingAccessibility) {
      if (hoverOverlayButton == 0) {
        colorblindMode = !colorblindMode;
      } else if (hoverOverlayButton == 1) {
        largeTextMode = !largeTextMode;
      } else if (hoverOverlayButton == 2) {
        textSpeed = (textSpeed % 3) + 1;
      } else if (hoverOverlayButton == 3) {
        showingAccessibility = false;
      }
      return;
    }

    if (showingLeaderboard) {
      if (hoverOverlayButton == 0) {
        showingLeaderboard = false;
      }
      return;
    }

    if (hoverOption == 0) {
      soundManager.playSelect();
      game.sceneManager.changeScene(new IntroScene());
    } else if (hoverOption == 1) {
      soundManager.playSelect();
      game.sceneManager.changeScene(new SandboxScene());
    } else if (hoverOption == 2) {
      soundManager.playSelect();
      game.sceneManager.changeScene(new MultiplayerScene());
    } else if (hoverOption == 3) {
      soundManager.playClick();
      showingAccessibility = true;
    } else if (hoverOption == 4) {
      soundManager.playClick();
      showingLeaderboard = true;
      leaderboardManager.load();
    } else if (hoverOption == 5) {
      soundManager.playClick();
      exit();
    }
  }

  // ==========================================
  // RENDERING ACCESSIBILITY OVERLAY
  // ==========================================

  void renderAccessibilityOverlay() {
    pushStyle();
    // Dark transparent backing
    fill(0, 0, 0, 180);
    rect(0, 0, width, height);

    float cx = width/2;
    float cy = height/2;
    float w = 480;
    float h = 340;

    // Card background
    stroke(0, 255, 255, 100);
    strokeWeight(2);
    fill(10, 18, 36, 250);
    rect(cx - w/2, cy - h/2, w, h, 18);

    // Title
    textAlign(CENTER, TOP);
    fill(255);
    textSize(24);
    text("AJUSTES DE ACCESIBILIDAD", cx, cy - h/2 + 25);

    textSize(13);
    fill(160);
    text("Configura la interfaz para mejor visibilidad en la feria", cx, cy - h/2 + 55);

    // Buttons
    // 1. Colorblind Mode
    drawOverlayButton(cx - 180, cy - 60, 360, 36, 
      "Modo Daltónicos: " + (colorblindMode ? "ON" : "OFF"), hoverOverlayButton == 0);
    
    // 2. Large Text Mode
    drawOverlayButton(cx - 180, cy - 10, 360, 36, 
      "Texto Grande: " + (largeTextMode ? "ON" : "OFF"), hoverOverlayButton == 1);

    // 3. Text Speed
    String speedLabel = "Máquina de escribir: ";
    if (textSpeed == 1) speedLabel += "INSTANTÁNEO";
    else if (textSpeed == 2) speedLabel += "RÁPIDO";
    else speedLabel += "NORMAL";
    drawOverlayButton(cx - 180, cy + 40, 360, 36, speedLabel, hoverOverlayButton == 2);

    // 4. Close
    drawOverlayButton(cx - 80, cy + 110, 160, 36, "CERRAR", hoverOverlayButton == 3);

    popStyle();
  }

  // ==========================================
  // RENDERING LEADERBOARD OVERLAY
  // ==========================================

  void renderLeaderboardOverlay() {
    pushStyle();
    fill(0, 0, 0, 180);
    rect(0, 0, width, height);

    float cx = width/2;
    float cy = height/2;
    float w = 520;
    float h = 420;

    stroke(255, 200, 0, 120);
    strokeWeight(2);
    fill(10, 18, 36, 250);
    rect(cx - w/2, cy - h/2, w, h, 18);

    textAlign(CENTER, TOP);
    fill(255);
    textSize(26);
    text("🏆 MEJORES PUNTAJES DE LA FERIA", cx, cy - h/2 + 25);

    textSize(13);
    fill(160);
    text("¡Demuestra tu eficiencia y pon tus iniciales en el top!", cx, cy - h/2 + 55);

    // Table Header
    float yStart = cy - 110;
    fill(0, 255, 255);
    textSize(14);
    textAlign(LEFT, TOP);
    text("PUESTO", cx - 210, yStart);
    text("JUGADOR", cx - 120, yStart);
    text("MISIÓN", cx - 20, yStart);
    textAlign(RIGHT, TOP);
    text("PUNTAJE", cx + 210, yStart);

    stroke(0, 255, 255, 40);
    strokeWeight(1);
    line(cx - 220, yStart + 22, cx + 220, yStart + 22);

    // Render top 5
    ArrayList<LeaderboardEntry> top = leaderboardManager.getTop(5);
    float rowY = yStart + 32;
    textSize(16);
    for (int i = 0; i < 5; i++) {
      if (i < top.size()) {
        LeaderboardEntry entry = top.get(i);
        fill(255);
        textAlign(LEFT, TOP);
        text("#" + (i + 1), cx - 200, rowY);
        fill(0, 255, 120);
        text(entry.name, cx - 110, rowY);
        fill(200);
        String mLabel = entry.missionID == 5 ? "FINAL" : "M0" + entry.missionID;
        text(mLabel, cx - 10, rowY);
        textAlign(RIGHT, TOP);
        fill(255, 200, 0);
        text(int(entry.score) + " pts", cx + 200, rowY);
      } else {
        fill(100);
        textAlign(LEFT, TOP);
        text("#" + (i + 1), cx - 200, rowY);
        text("---", cx - 110, rowY);
        text("---", cx - 10, rowY);
        textAlign(RIGHT, TOP);
        text("---", cx + 200, rowY);
      }
      rowY += 38;
    }

    // Close button
    drawOverlayButton(cx - 80, cy + 140, 160, 36, "CERRAR", hoverOverlayButton == 0);

    popStyle();
  }

  void drawOverlayButton(float x, float y, float w, float h, String label, boolean active) {
    pushStyle();
    if (active) {
      fill(0, 255, 255);
      noStroke();
      rect(x, y, w, h, 8);
      fill(0);
    } else {
      fill(20, 32, 54);
      stroke(0, 255, 255, 60);
      strokeWeight(1);
      rect(x, y, w, h, 8);
      fill(255);
    }
    textAlign(CENTER, CENTER);
    textSize(14);
    text(label, x + w/2, y + h/2);
    popStyle();
  }
}
