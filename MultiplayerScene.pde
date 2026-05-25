import java.util.ArrayList;

class MultiplayerScene extends Scene {

  ArrayList<Node> nodes;
  ArrayList<Edge> edges;
  ArrayList<Particle> particles;

  // Turn-based state
  int activePlayer = 1;     // 1 = Hacker (Ghost), 2 = Defender (EVA)
  int actionPoints = 3;     // 3 PA per turn
  int currentTurn = 1;
  int victoryState = 0;     // 0 = ongoing, 1 = Hacker wins, 2 = Defender wins

  // Selection state
  Node selectedNode = null;
  Edge selectedEdge = null;
  int activeAction = 0;     // 0 = none, 1 = Infect, 2 = Boost, 3 = Sabotage, 4 = Heal, 5 = Shield, 6 = Block

  // Logs
  ArrayList<String> turnLogs;

  // Visual alerts
  String alertMessage = "";
  float alertAlpha = 0;

  void enter() {
    nodes = new ArrayList<Node>();
    edges = new ArrayList<Edge>();
    particles = new ArrayList<Particle>();
    turnLogs = new ArrayList<String>();

    activePlayer = 1;
    actionPoints = 3;
    currentTurn = 1;
    victoryState = 0;
    selectedNode = null;
    selectedEdge = null;
    activeAction = 0;

    for (int i = 0; i < 100; i++) {
      particles.add(new Particle());
    }

    createNetwork();
    turnLogs.add("--- INICIA EL DUELO ---");
    turnLogs.add("Ghost (Hacker) vs EVA (Defensa)");
    turnLogs.add("Turno 1: Ghost tiene el control");
    
    soundManager.playSelect();
  }

  void createNetwork() {
    // Generate a balanced 8-node network
    Node a = new Node(300, 250, "Alicia", "víctima");
    Node b = new Node(520, 180, "Bruno", "apoyo");
    Node c = new Node(680, 360, "Carla", "observadora");
    Node d = new Node(460, 500, "Diego", "vulnerable");
    Node e = new Node(820, 240, "Ghost", "agresor");
    Node f = new Node(980, 420, "Valeria", "apoyo");
    Node g = new Node(1180, 300, "Andrés", "observador");
    Node h = new Node(940, 580, "Sara", "apoyo");

    // Initial setup
    e.infected = true;
    e.toxicity = 100;
    a.stress = 20;
    d.vulnerable = true;
    f.supportive = true;
    h.supportive = true;

    nodes.add(a);
    nodes.add(b);
    nodes.add(c);
    nodes.add(d);
    nodes.add(e);
    nodes.add(f);
    nodes.add(g);
    nodes.add(h);

    connect(a, b); // Alicia - Bruno
    connect(b, c); // Bruno - Carla
    connect(a, d); // Alicia - Diego
    connect(c, e); // Carla - Ghost
    connect(b, e); // Bruno - Ghost
    connect(e, f); // Ghost - Valeria
    connect(f, g); // Valeria - Andrés
    connect(d, h); // Diego - Sara
    connect(h, g); // Sara - Andrés
    connect(c, h); // Carla - Sara
  }

  void connect(Node u, Node v) {
    u.connect(v);
    v.connect(u);
    Edge ed = new Edge(u, v);
    ed.capacity = 10;
    ed.flow = 0;
    edges.add(ed);
  }

  void update() {
    for (Node n : nodes) {
      n.update(mouseX, mouseY);
    }
    for (Particle p : particles) {
      p.update();
    }
    if (alertAlpha > 0) alertAlpha -= 2;

    checkVictory();
  }

  void render() {
    background(5, 10, 20);

    // Draw Grid
    stroke(0, 80, 120, 25);
    for (int i = 0; i < width - 340; i += 50) line(i, 0, i, height);
    for (int j = 0; j < height; j += 50) line(0, j, width - 340, j);

    // Render components
    for (Particle p : particles) {
      p.render();
    }
    for (Edge e : edges) {
      e.render();
    }
    for (Node n : nodes) {
      n.render();
    }

    // Highlight action ranges if active
    drawActionHighlights();

    // Side HUD Panel
    drawSidePanel();

    // Alert
    if (alertAlpha > 0 && alertMessage.length() > 0) {
      pushStyle();
      fill(activePlayer == 1 ? color(255, 60, 90, alertAlpha) : color(0, 255, 255, alertAlpha));
      textAlign(CENTER, CENTER);
      textSize(24);
      text(alertMessage, (width - 340)/2, 60);
      popStyle();
    }

    // Victory Screen Overlay
    if (victoryState > 0) {
      drawVictoryOverlay();
    }
  }

  void drawActionHighlights() {
    pushStyle();
    noFill();
    strokeWeight(2);
    
    if (activeAction == 1) { // Infectable nodes (clean neighbors of infected)
      stroke(255, 0, 80, 150);
      for (Node n : nodes) {
        if (!n.infected && isNearInfected(n)) {
          float blink = sin(frameCount * 0.12) * 4 + 8;
          ellipse(n.x, n.y, (26 + blink) * 2, (26 + blink) * 2);
        }
      }
    } else if (activeAction == 4) { // Cleanable nodes (infected)
      stroke(0, 255, 120, 150);
      for (Node n : nodes) {
        if (n.infected) {
          float blink = sin(frameCount * 0.12) * 4 + 8;
          ellipse(n.x, n.y, (26 + blink) * 2, (26 + blink) * 2);
        }
      }
    } else if (activeAction == 5) { // Shieldable nodes (clean, unshielded)
      stroke(0, 180, 255, 150);
      for (Node n : nodes) {
        if (!n.infected && !n.shielded) {
          float blink = sin(frameCount * 0.12) * 4 + 8;
          ellipse(n.x, n.y, (26 + blink) * 2, (26 + blink) * 2);
        }
      }
    }
    popStyle();
  }

  boolean isNearInfected(Node n) {
    for (Node neighbor : n.neighbors) {
      if (neighbor.infected) {
        // Must check that the connecting edge is active/not blocked
        Edge e = getEdge(n, neighbor);
        if (e != null && !e.blocked) return true;
      }
    }
    return false;
  }

  Edge getEdge(Node u, Node v) {
    for (Edge e : edges) {
      if ((e.a == u && e.b == v) || (e.a == v && e.b == u)) return e;
    }
    return null;
  }

  void drawSidePanel() {
    float px = width - 340;
    noStroke();
    fill(8, 14, 28, 230);
    rect(px, 0, 340, height);

    stroke(activePlayer == 1 ? color(255, 60, 90, 70) : color(0, 255, 255, 70));
    strokeWeight(1.5);
    line(px, 0, px, height);
    noStroke();

    float cx = px + 16;
    float cy = 16;
    float cardW = 340 - 32;

    // 1. Header (Turn, Player, PA)
    cy = drawHUDHeader(cx, cy, cardW);

    // 2. Action Buttons Selector
    cy = drawHUDActionButtons(cx, cy, cardW);

    // 3. Selected Element Details
    cy = drawHUDDetails(cx, cy, cardW);

    // 4. Logs
    cy = drawHUDLogs(cx, cy, cardW);
  }

  float beginCard(float x, float y, float w, float h, color strokeCol) {
    noStroke();
    fill(0, 30);
    rect(x + 2, y + 2, w, h, 12);
    stroke(strokeCol);
    strokeWeight(1);
    fill(14, 22, 40, 200);
    rect(x, y, w, h, 12);
    noStroke();
    return y + 12;
  }

  float drawHUDHeader(float x, float y, float w) {
    float h = largeTextMode ? 100 : 86;
    color turnCol = activePlayer == 1 ? color(255, 60, 90, 90) : color(0, 255, 255, 90);
    float iy = beginCard(x, y, w, h, turnCol);

    fill(255);
    textAlign(LEFT, TOP);
    textSize(largeTextMode ? 14 : 11);
    text("TURNO " + currentTurn, x + 12, iy);

    textSize(largeTextMode ? 22 : 18);
    if (activePlayer == 1) {
      fill(255, 60, 90);
      text("HACKER: GHOST", x + 12, iy + (largeTextMode ? 20 : 16));
    } else {
      fill(0, 255, 255);
      text("DEFENSA: EVA", x + 12, iy + (largeTextMode ? 20 : 16));
    }

    // Action Points Dots
    float dx = x + w - 85;
    float dy = y + 16;
    for (int i = 0; i < 3; i++) {
      if (i < actionPoints) {
        fill(255, 200, 0); // Gold for available PA
      } else {
        fill(35, 45, 60);
      }
      ellipse(dx + i * 22, dy + 10, 14, 14);
    }
    fill(200);
    textSize(largeTextMode ? 12 : 9);
    textAlign(RIGHT, TOP);
    text("PUNTOS DE ACCIÓN", dx + 60, dy + 22);

    return y + h + 8;
  }

  float drawHUDActionButtons(float x, float y, float w) {
    float h = 180;
    float iy = beginCard(x, y, w, h, activePlayer == 1 ? color(255, 60, 90, 40) : color(0, 255, 255, 40));

    fill(255, 200, 0);
    textAlign(LEFT, TOP);
    textSize(11);
    text("ACCIONES DISPONIBLES:", x + 12, iy);

    float btnY = iy + 16;
    float btnW = w - 24;

    if (activePlayer == 1) {
      // Hacker actions
      drawButton(x + 12, btnY, btnW, 30, "🔴 INFECTAR NODO (2 PA)", activeAction == 1, 2 <= actionPoints);
      drawButton(x + 12, btnY + 36, btnW, 30, "⚡ SOBRECARGAR ENLACE (1 PA)", activeAction == 2, 1 <= actionPoints);
      drawButton(x + 12, btnY + 72, btnW, 30, "🚫 SABOTEAR ENLACE (1 PA)", activeAction == 3, 1 <= actionPoints);
    } else {
      // Defender actions
      drawButton(x + 12, btnY, btnW, 30, "🔵 SANAR NODO (2 PA)", activeAction == 4, 2 <= actionPoints);
      drawButton(x + 12, btnY + 36, btnW, 30, "🛡️ PROTEGER NODO (1 PA)", activeAction == 5, 1 <= actionPoints);
      drawButton(x + 12, btnY + 72, btnW, 30, "⛔ BLOQUEAR ENLACE (1 PA)", activeAction == 6, 1 <= actionPoints);
    }

    // End turn button
    drawButton(x + 12, btnY + 114, btnW, 30, "⏭️ PASAR TURNO", false, true);

    return y + h + 8;
  }

  float drawHUDDetails(float x, float y, float w) {
    float h = 90;
    float iy = beginCard(x, y, w, h, color(255, 255, 255, 20));

    fill(180);
    textAlign(LEFT, TOP);
    textSize(11);
    text("ELEMENTO SELECCIONADO:", x + 12, iy);

    float cy = iy + 16;
    fill(255);
    textSize(12);

    if (selectedNode != null) {
      text("Usuario: " + selectedNode.name + " (" + selectedNode.role + ")", x + 12, cy);
      String status = selectedNode.infected ? "INFECTADO" : (selectedNode.shielded ? "ESCUDADO" : "LIMPIO");
      text("Estado: " + status + " | Stress: " + (int)selectedNode.stress + "%", x + 12, cy + 16);
    } else if (selectedEdge != null) {
      text("Conexión: " + selectedEdge.a.name + " - " + selectedEdge.b.name, x + 12, cy);
      String state = selectedEdge.blocked ? "BLOQUEADO" : "ACTIVO";
      text("Estado: " + state + " | Capacidad: " + (int)selectedEdge.capacity, x + 12, cy + 16);
    } else {
      fill(140);
      text("(Haz clic sobre un nodo o enlace)", x + 12, cy);
    }

    return y + h + 8;
  }

  float drawHUDLogs(float x, float y, float w) {
    float h = height - y - 16;
    float iy = beginCard(x, y, w, h, color(255, 255, 255, 15));

    fill(180);
    textAlign(LEFT, TOP);
    textSize(11);
    text("REGISTRO DE ACCIONES:", x + 12, iy);

    float rowY = iy + 18;
    textSize(11);

    int start = max(0, turnLogs.size() - 6);
    for (int i = start; i < turnLogs.size(); i++) {
      String log = turnLogs.get(i);
      if (log.startsWith("Ghost") || log.startsWith("P1")) fill(255, 100, 120);
      else if (log.startsWith("EVA") || log.startsWith("P2")) fill(100, 220, 255);
      else fill(180);

      text(log, x + 12, rowY);
      rowY += largeTextMode ? 20 : 16;
    }

    return y + h;
  }

  void drawButton(float x, float y, float w, float h, String label, boolean selected, boolean enabled) {
    pushStyle();
    if (!enabled) {
      fill(15, 20, 30);
      stroke(40, 50, 60);
      rect(x, y, w, h, 6);
      fill(80);
    } else if (selected) {
      fill(activePlayer == 1 ? color(255, 60, 90, 120) : color(0, 255, 255, 120));
      stroke(activePlayer == 1 ? color(255, 60, 90) : color(0, 255, 255));
      strokeWeight(1.5);
      rect(x, y, w, h, 6);
      fill(255);
    } else if (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h) {
      fill(activePlayer == 1 ? color(255, 60, 90) : color(0, 255, 255));
      rect(x, y, w, h, 6);
      fill(0);
    } else {
      fill(22, 34, 58);
      stroke(activePlayer == 1 ? color(255, 60, 90, 80) : color(0, 255, 255, 80));
      rect(x, y, w, h, 6);
      fill(230);
    }
    textAlign(CENTER, CENTER);
    textSize(largeTextMode ? 13 : 11);
    text(label, x + w/2, y + h/2 - 1);
    popStyle();
  }

  void mousePressed() {
    if (victoryState > 0) {
      handleVictoryClicks();
      return;
    }

    // Check side panel clicks first
    if (mouseX >= width - 340) {
      handleHUDClicks();
      return;
    }

    // Gameplay view clicks: Node or Edge selection/action execution
    Node clickedNode = null;
    for (Node n : nodes) {
      if (dist(mouseX, mouseY, n.x, n.y) < n.radius) {
        clickedNode = n;
        break;
      }
    }

    if (clickedNode != null) {
      selectedNode = clickedNode;
      selectedEdge = null;
      soundManager.playClick();

      // Execute targeted action on node
      if (activeAction == 1 && activePlayer == 1) { // Infect
        if (!clickedNode.infected) {
          if (clickedNode.shielded) {
            clickedNode.shielded = false;
            actionPoints -= 2;
            activeAction = 0;
            turnLogs.add("Ghost intentó infectar a " + clickedNode.name + " (Escudo roto).");
            triggerAlert("ESCUDO ROTO");
            soundManager.playError();
          } else if (isNearInfected(clickedNode)) {
            clickedNode.infected = true;
            clickedNode.toxicity = 50;
            clickedNode.stress = 50;
            actionPoints -= 2;
            activeAction = 0;
            turnLogs.add("Ghost infectó a " + clickedNode.name + " (Toxicity +50).");
            triggerAlert("NODO INFECTADO");
            soundManager.playInfect();
          } else {
            triggerAlert("SIN NODO INFECTADO CERCANO");
            soundManager.playError();
          }
        } else {
          triggerAlert("YA ESTÁ INFECTADO");
          soundManager.playError();
        }
      } else if (activeAction == 4 && activePlayer == 2) { // Heal
        if (clickedNode.infected) {
          clickedNode.infected = false;
          clickedNode.toxicity = 0;
          clickedNode.stress = 0;
          actionPoints -= 2;
          activeAction = 0;
          turnLogs.add("EVA sanó a " + clickedNode.name + ".");
          triggerAlert("NODO SANADO");
          soundManager.playHeal();
        } else {
          triggerAlert("EL NODO NO ESTÁ INFECTADO");
          soundManager.playError();
        }
      } else if (activeAction == 5 && activePlayer == 2) { // Shield
        if (!clickedNode.infected && !clickedNode.shielded) {
          clickedNode.shielded = true;
          actionPoints -= 1;
          activeAction = 0;
          turnLogs.add("EVA colocó un escudo en " + clickedNode.name + ".");
          triggerAlert("ESCUDO APLICADO");
          soundManager.playHeal();
        } else {
          triggerAlert("YA TIENE ESCUDO O ESTÁ INFECTADO");
          soundManager.playError();
        }
      }
      return;
    }

    Edge clickedEdge = null;
    for (Edge e : edges) {
      if (e.isMouseNear(mouseX, mouseY)) {
        clickedEdge = e;
        break;
      }
    }

    if (clickedEdge != null) {
      selectedEdge = clickedEdge;
      selectedNode = null;
      soundManager.playClick();

      // Execute targeted action on edge
      if (activeAction == 2 && activePlayer == 1) { // Boost capacity
        clickedEdge.capacity += 5;
        actionPoints -= 1;
        activeAction = 0;
        turnLogs.add("Ghost sobrecargó enlace " + clickedEdge.a.name + "-" + clickedEdge.b.name + " (Cap: " + (int)clickedEdge.capacity + ").");
        triggerAlert("ENLACE SOBRECARGADO");
        soundManager.playSelect();
      } else if (activeAction == 3 && activePlayer == 1) { // Sabotage (block)
        clickedEdge.blocked = true;
        actionPoints -= 1;
        activeAction = 0;
        turnLogs.add("Ghost saboteó enlace " + clickedEdge.a.name + "-" + clickedEdge.b.name + ".");
        triggerAlert("ENLACE BLOQUEADO");
        soundManager.playSelect();
      } else if (activeAction == 6 && activePlayer == 2) { // Toggle block
        clickedEdge.blocked = !clickedEdge.blocked;
        actionPoints -= 1;
        activeAction = 0;
        turnLogs.add("EVA " + (clickedEdge.blocked ? "bloqueó" : "restauró") + " enlace " + clickedEdge.a.name + "-" + clickedEdge.b.name + ".");
        triggerAlert(clickedEdge.blocked ? "ENLACE BLOQUEADO" : "ENLACE ACTIVO");
        soundManager.playSelect();
      }
    }
  }

  void handleHUDClicks() {
    float px = width - 340;
    float cx = px + 16;

    // Header Y size is 86 + 10 gap = 96
    float btnY = 16 + (largeTextMode ? 100 : 86) + 12 + 16;
    float btnW = 340 - 32;

    if (activePlayer == 1) {
      // Infect Node (2 PA)
      if (mouseX > cx && mouseX < cx + btnW && mouseY > btnY && mouseY < btnY + 30) {
        if (actionPoints >= 2) {
          activeAction = (activeAction == 1) ? 0 : 1;
          soundManager.playClick();
        }
      }
      // Overload Edge (1 PA)
      if (mouseX > cx && mouseX < cx + btnW && mouseY > btnY + 36 && mouseY < btnY + 66) {
        if (actionPoints >= 1) {
          activeAction = (activeAction == 2) ? 0 : 2;
          soundManager.playClick();
        }
      }
      // Sabotage Edge (1 PA)
      if (mouseX > cx && mouseX < cx + btnW && mouseY > btnY + 72 && mouseY < btnY + 102) {
        if (actionPoints >= 1) {
          activeAction = (activeAction == 3) ? 0 : 3;
          soundManager.playClick();
        }
      }
    } else {
      // Heal Node (2 PA)
      if (mouseX > cx && mouseX < cx + btnW && mouseY > btnY && mouseY < btnY + 30) {
        if (actionPoints >= 2) {
          activeAction = (activeAction == 4) ? 0 : 4;
          soundManager.playClick();
        }
      }
      // Shield Node (1 PA)
      if (mouseX > cx && mouseX < cx + btnW && mouseY > btnY + 36 && mouseY < btnY + 66) {
        if (actionPoints >= 1) {
          activeAction = (activeAction == 5) ? 0 : 5;
          soundManager.playClick();
        }
      }
      // Block Edge (1 PA)
      if (mouseX > cx && mouseX < cx + btnW && mouseY > btnY + 72 && mouseY < btnY + 102) {
        if (actionPoints >= 1) {
          activeAction = (activeAction == 6) ? 0 : 6;
          soundManager.playClick();
        }
      }
    }

    // End Turn button (btnY + 114)
    if (mouseX > cx && mouseX < cx + btnW && mouseY > btnY + 114 && mouseY < btnY + 144) {
      soundManager.playSelect();
      endTurn();
    }
  }

  void endTurn() {
    activeAction = 0;
    if (activePlayer == 1) {
      activePlayer = 2;
      actionPoints = 3;
      turnLogs.add("--- Turno de EVA (Defensa) ---");
    } else {
      activePlayer = 1;
      actionPoints = 3;
      currentTurn++;
      
      // Perform infection spread and stress updates at the end of full round (turn end of P2)
      tickNetworkInfections();
      turnLogs.add("--- Turno de Ghost (Hacker) ---");
    }
  }

  void tickNetworkInfections() {
    ArrayList<Node> nodesToInfect = new ArrayList<Node>();
    
    for (Node n : nodes) {
      if (n.infected) {
        n.stress = constrain(n.stress + 10, 0, 100);
        n.toxicity = constrain(n.toxicity + 15, 0, 100);

        // Check clean neighbors
        for (Node neighbor : n.neighbors) {
          if (!neighbor.infected && !nodesToInfect.contains(neighbor)) {
            // Check link is active (not blocked)
            Edge e = getEdge(n, neighbor);
            if (e != null && !e.blocked) {
              nodesToInfect.add(neighbor);
            }
          }
        }
      }
    }

    // Apply spreads
    for (Node target : nodesToInfect) {
      if (target.shielded) {
        target.shielded = false; // block infection, consume shield
        turnLogs.add("Escudo bloqueó propagación en " + target.name + ".");
      } else {
        target.infected = true;
        target.toxicity = 50;
        target.stress = min(100, target.stress + 40);
        turnLogs.add("Infección se propagó a " + target.name + ".");
      }
    }
  }

  void checkVictory() {
    // Hacker wins if Alicia is infected and stress reaches 100%, OR if 60% of network is infected
    Node alicia = getNode("Alicia");
    if (alicia != null && alicia.infected && alicia.stress >= 99) {
      victoryState = 1;
      return;
    }

    int infectedCount = 0;
    for (Node n : nodes) {
      if (n.infected) infectedCount++;
    }

    if (infectedCount >= nodes.size() * 0.6) {
      victoryState = 1;
      return;
    }

    // Defender wins if all nodes are clean (no infected) OR survives 10 turns
    if (infectedCount == 0) {
      victoryState = 2;
      return;
    }

    if (currentTurn > 10) {
      victoryState = 2;
      return;
    }
  }

  Node getNode(String name) {
    for (Node n : nodes) {
      if (n.name.equals(name)) return n;
    }
    return null;
  }

  void triggerAlert(String msg) {
    alertMessage = msg;
    alertAlpha = 255;
  }

  void drawVictoryOverlay() {
    pushStyle();
    fill(0, 0, 0, 190);
    rect(0, 0, width, height);

    float cx = width / 2;
    float cy = height / 2;
    float w = 550;
    float h = 300;

    stroke(victoryState == 1 ? color(255, 60, 90, 180) : color(0, 255, 255, 180));
    strokeWeight(2.5);
    fill(10, 18, 36, 250);
    rect(cx - w/2, cy - h/2, w, h, 18);

    textAlign(CENTER, CENTER);
    fill(255);
    textSize(28);
    
    if (victoryState == 1) {
      text("🔥 ¡VICTORIA DE GHOST! 🔥", cx, cy - 60);
      textSize(16);
      fill(255, 100, 120);
      text("La red de seguridad ha sido vulnerada.\nEl ciberacoso logró colapsar las defensas.", cx, cy - 10);
    } else {
      text("🏆 ¡VICTORIA DE EVA! 🏆", cx, cy - 60);
      textSize(16);
      fill(100, 220, 255);
      text("¡Felicidades! La red ha sido completamente protegida.\nLa propagación tóxica fue contenida a tiempo.", cx, cy - 10);
    }

    // Options
    float btnY = cy + 50;
    float btnW = 180;
    float btnH = 38;

    // Play again: cx - 200
    drawVictoryButton(cx - 200, btnY, btnW, btnH, "JUGAR DE NUEVO", 1);
    // Exit to menu: cx + 20
    drawVictoryButton(cx + 20, btnY, btnW, btnH, "VOLVER AL MENÚ", 2);

    popStyle();
  }

  void drawVictoryButton(float x, float y, float w, float h, String label, int id) {
    pushStyle();
    if (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h) {
      fill(victoryState == 1 ? color(255, 60, 90) : color(0, 255, 255));
      noStroke();
      rect(x, y, w, h, 8);
      fill(0);
    } else {
      fill(20, 32, 54);
      stroke(victoryState == 1 ? color(255, 60, 90, 120) : color(0, 255, 255, 120));
      rect(x, y, w, h, 8);
      fill(255);
    }
    textAlign(CENTER, CENTER);
    textSize(14);
    text(label, x + w/2, y + h/2 - 1);
    popStyle();
  }

  void handleVictoryClicks() {
    float cx = width / 2;
    float cy = height / 2;
    float btnY = cy + 50;
    float btnW = 180;
    float btnH = 38;

    // Play again: cx - 200
    if (mouseX > cx - 200 && mouseX < cx - 20 && mouseY > btnY && mouseY < btnY + btnH) {
      soundManager.playSelect();
      enter();
    }
    // Return to menu: cx + 20
    if (mouseX > cx + 20 && mouseX < cx + 200 && mouseY > btnY && mouseY < btnY + btnH) {
      soundManager.playClick();
      game.sceneManager.changeScene(new MenuScene());
    }
  }

  void keyPressed() {
    if (key == ESC) {
      key = 0;
      game.sceneManager.changeScene(new MenuScene());
    }
  }
}
