// ═══════════════════════════════════════════════════════════════
// HUDView.pde — Cyberpunk HUD Panel (Right Side, 340px wide)
// Modern card-based layout with step progress, network health,
// algorithm visualizers (Queue, Stack, Distance Table, Edge Sorting),
// and player score system.
// ═══════════════════════════════════════════════════════════════

class HUDView {

  MissionScene mission;

  // Layout constants
  final float PANEL_W = 340;
  final float PAD = 16;          // outer padding from panel edges
  final float CARD_PAD = 14;     // inner padding inside cards
  final float CARD_GAP = 10;     // vertical gap between cards
  final float CARD_R = 14;       // corner radius

  // Color palette
  color COL_BG;
  color COL_CARD_BG;
  color COL_CARD_BORDER;
  color COL_CYAN;
  color COL_GREEN;
  color COL_RED;
  color COL_GOLD;
  color COL_WHITE;
  color COL_DIM;
  color COL_BAR_TRACK;

  HUDView(MissionScene mission) {
    this.mission = mission;
    initColors();
  }

  void initColors() {
    COL_BG        = color(8, 14, 28, 230);
    COL_CARD_BG   = color(14, 22, 40, 200);
    COL_CARD_BORDER = color(0, 255, 255, 60);
    COL_CYAN      = color(0, 255, 255);
    COL_GREEN     = color(0, 255, 140);
    COL_RED       = color(255, 60, 90);
    COL_GOLD      = color(255, 200, 40);
    COL_WHITE     = color(255);
    COL_DIM       = color(160, 175, 195);
    COL_BAR_TRACK = color(35, 45, 60);
  }

  // ─────────────────────────────────────────────
  // MAIN RENDER
  // ─────────────────────────────────────────────

  void render() {
    pushStyle();
    
    // Update colors based on Accessibility Mode
    if (colorblindMode) {
      COL_GREEN = color(94, 60, 153); // purple
      COL_RED = color(230, 97, 1);   // orange
      COL_GOLD = color(253, 184, 99); // light yellow/gold
      COL_CYAN = color(247, 247, 247); // white contrast
    } else {
      initColors();
    }

    float px = width - PANEL_W;  // panel X origin
    float cy = PAD;              // running Y cursor

    // Panel background
    drawPanelBackground(px);

    float cardW = PANEL_W - PAD * 2;

    // 1. Mission Header & Score
    cy = drawMissionHeader(px + PAD, cy, cardW);

    // 2. Algorithm Tracing (Visual Queue / Stack / Distance Table / Cost List)
    cy = drawAlgorithmVisualizer(px + PAD, cy, cardW);

    // 3. Step Progress
    cy = drawStepProgress(px + PAD, cy, cardW);

    // 4. What To Do
    cy = drawWhatToDo(px + PAD, cy, cardW);

    // 5. Network Health
    cy = drawNetworkHealth(px + PAD, cy, cardW);

    // 6. Controls
    cy = drawControls(px + PAD, cy, cardW);

    popStyle();
  }

  // ─────────────────────────────────────────────
  // PANEL BACKGROUND
  // ─────────────────────────────────────────────

  void drawPanelBackground(float px) {
    noStroke();
    fill(COL_BG);
    rect(px, 0, PANEL_W, height);

    // Left edge accent line
    stroke(COL_CYAN & 0x00FFFFFF | (70 << 24));
    strokeWeight(1.5);
    line(px, 0, px, height);
    noStroke();
  }

  // ─────────────────────────────────────────────
  // CARD DRAWING HELPERS
  // ─────────────────────────────────────────────

  float beginCard(float x, float y, float w, float h) {
    noStroke();
    fill(0, 30);
    rect(x + 2, y + 2, w, h, CARD_R);

    stroke(COL_CARD_BORDER);
    strokeWeight(1);
    fill(COL_CARD_BG);
    rect(x, y, w, h, CARD_R);
    noStroke();

    return y + CARD_PAD;
  }

  // ─────────────────────────────────────────────
  // 1. MISSION HEADER CARD & SCORE
  // ─────────────────────────────────────────────

  float drawMissionHeader(float x, float y, float w) {
    int mid = mission.missionID;
    String title = getMissionTitle(mid);
    String phase = getPhaseLabel(mid);

    float cardH = largeTextMode ? 100 : 86;
    float iy = beginCard(x, y, w, cardH);
    float ix = x + CARD_PAD;

    // Mission number badge
    textAlign(LEFT, TOP);
    textSize(largeTextMode ? 14 : 11);
    fill(COL_CYAN);
    text("MISIÓN " + mid, ix, iy);

    // Title
    textSize(largeTextMode ? 22 : 18);
    fill(COL_WHITE);
    text(title, ix, iy + (largeTextMode ? 20 : 16));

    // Phase subtitle
    textSize(largeTextMode ? 13 : 10);
    fill(COL_GREEN);
    text(phase, ix, iy + (largeTextMode ? 46 : 38));

    // SCORE
    textAlign(LEFT, TOP);
    textSize(largeTextMode ? 15 : 12);
    fill(COL_GOLD);
    text("PUNTAJE: " + int(mission.score) + " pts", ix, iy + (largeTextMode ? 66 : 54));

    // PERSISTENT HELP BUTTON [?]
    float helpX = x + w - 40;
    float helpY = y + 10;
    float helpSize = 30;
    
    // Draw help button circle
    pushStyle();
    if (mouseX > helpX && mouseX < helpX + helpSize && mouseY > helpY && mouseY < helpY + helpSize) {
      fill(COL_CYAN);
      stroke(255);
      strokeWeight(1.5);
      ellipse(helpX + helpSize/2, helpY + helpSize/2, helpSize, helpSize);
      fill(0);
    } else {
      fill(20, 32, 56);
      stroke(COL_CYAN, 120);
      strokeWeight(1);
      ellipse(helpX + helpSize/2, helpY + helpSize/2, helpSize, helpSize);
      fill(COL_CYAN);
    }
    textAlign(CENTER, CENTER);
    textSize(16);
    text("?", helpX + helpSize/2, helpY + helpSize/2 - 1);
    popStyle();

    return y + cardH + CARD_GAP;
  }

  String getMissionTitle(int mid) {
    if (mid == 1) return "Rastros del Acoso";
    if (mid == 2) return "Ruta Segura";
    if (mid == 3) return "Reconstruir la Red";
    if (mid == 4) return "Control del Impacto";
    if (mid == 5) return "Red Segura (Final)";
    return "";
  }

  String getPhaseLabel(int mid) {
    if (mid == 5) {
      String[] stageNames = {"Rastreo", "Ruta", "Reconstruir", "Control"};
      int s = constrain(mission.missionStage, 1, 4);
      return "Etapa " + s + "/4: " + stageNames[s - 1];
    }
    if (mid == 1) {
      return (mission.missionPhase == 1) ? "Fase 1 — Rastrear" : "Fase 2 — Contener";
    }
    if (mid == 2) return "Elegir aliado → Calcular ruta";
    if (mid == 3) return "Analizar red → Reconstruir";
    if (mid == 4) return "Analizar flujo → Aplicar control";
    return "";
  }

  // ─────────────────────────────────────────────
  // 2. ALGORITHM VISUALIZER CARD (QUEUE / STACK / TABLE / EDGES)
  // ─────────────────────────────────────────────

  float drawAlgorithmVisualizer(float x, float y, float w) {
    int mid = mission.missionID;
    int stage = (mid == 5) ? mission.missionStage : 0;
    
    // Choose visualizer based on algorithm
    int algType = 0; // 0=None, 1=BFS (Queue), 2=DFS (Stack), 3=Dijkstra (Table), 4=Kruskal (Cost List), 5=MaxFlow (Augmenting Paths)
    
    if (mid == 1 || stage == 1) {
      algType = mission.traversalName.equals("BFS") ? 1 : 2;
    } else if (mid == 2 || stage == 2) {
      algType = 3;
    } else if (mid == 3 || stage == 3) {
      algType = 4;
    } else if (mid == 4 || stage == 4) {
      algType = 5;
    }

    if (algType == 0) return y;

    float cardH = largeTextMode ? 210 : 180;
    float iy = beginCard(x, y, w, cardH);
    float ix = x + CARD_PAD;
    float innerW = w - CARD_PAD * 2;

    // Visualizer Title
    textAlign(LEFT, TOP);
    textSize(largeTextMode ? 14 : 11);
    fill(COL_CYAN);
    
    if (algType == 1) text("ESTRUCTURA BFS: COLA (FIFO)", ix, iy);
    else if (algType == 2) text("ESTRUCTURA DFS: PILA (LIFO)", ix, iy);
    else if (algType == 3) text("TABLA DE DISTANCIAS DIJKSTRA", ix, iy);
    else if (algType == 4) text("CONEXIONES ORDENADAS (KRUSKAL)", ix, iy);
    else if (algType == 5) text("CAMINOS DE AUMENTO (FORD-FULKERSON)", ix, iy);

    float contentY = iy + 18;

    // Render contents
    if (algType == 1) {
      // Draw BFS Queue
      drawQueueOrStack(ix, contentY, innerW, mission.bfsTraversal.queue, true);
    } else if (algType == 2) {
      // Draw DFS Stack
      drawQueueOrStack(ix, contentY, innerW, mission.dfsTraversal.stack, false);
    } else if (algType == 3) {
      // Draw Dijkstra Table
      drawDijkstraTable(ix, contentY, innerW);
    } else if (algType == 4) {
      // Draw Kruskal Cost List
      drawKruskalCostList(ix, contentY, innerW);
    } else if (algType == 5) {
      // Draw Ford-Fulkerson Augmenting Paths
      drawMaxFlowHistory(ix, contentY, innerW);
    }

    // DRAW PLAY/PAUSE/STEP CONTROLS
    float ctrlY = y + cardH - 42;
    boolean auto = isAlgAuto(algType);
    float btnW = (innerW - 10) / 2;

    if (algType == 4 && mission.kruskalMST.running && mission.kruskalMST.waitingForDecision) {
      drawSmallButton(ix, ctrlY, btnW, 26, "[ ✅ ACEPTAR ]", false, 3);
      drawSmallButton(ix + btnW + 10, ctrlY, btnW, 26, "[ ❌ RECHAZAR ]", false, 4);
    } else if (algType == 5 && mission.maxFlowCalculator.running && mission.maxFlowCalculator.manualMode) {
      drawSmallButton(ix, ctrlY, innerW, 26, "[ 🔄 REINICIAR CAMINO ]", false, 5);
    } else {
      drawSmallButton(ix, ctrlY, btnW, 26, auto ? "[ ⏸ PAUSA ]" : "[ ▶ AUTO ]", auto, 1);
      drawSmallButton(ix + btnW + 10, ctrlY, btnW, 26, "[ ⏭ PASO ]", false, 2);
    }

    return y + cardH + CARD_GAP;
  }

  boolean isAlgAuto(int type) {
    if (type == 1) return mission.bfsTraversal.autoPlay;
    if (type == 2) return mission.dfsTraversal.autoPlay;
    // For Dijkstra, Kruskal, MaxFlow we'll reference fields we'll use in MissionScene
    return mission.algorithmAutoPlay;
  }

  void drawSmallButton(float x, float y, float w, float h, String label, boolean active, int btnID) {
    pushStyle();
    if (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h) {
      fill(COL_CYAN);
      noStroke();
      rect(x, y, w, h, 6);
      fill(0);
    } else if (active) {
      fill(COL_CYAN & 0x00FFFFFF | (80 << 24));
      stroke(COL_CYAN, 200);
      strokeWeight(1);
      rect(x, y, w, h, 6);
      fill(COL_WHITE);
    } else {
      fill(20, 30, 48);
      stroke(COL_CYAN, 80);
      strokeWeight(1);
      rect(x, y, w, h, 6);
      fill(COL_DIM);
    }
    textAlign(CENTER, CENTER);
    textSize(largeTextMode ? 13 : 11);
    text(label, x + w/2, y + h/2 - 1);
    popStyle();
  }

  // --- RENDERING BFS/DFS CONTAINERS ---
  void drawQueueOrStack(float x, float y, float w, ArrayList<Node> container, boolean isQueue) {
    pushStyle();
    
    // Render status string
    String status = "";
    if (isQueue) {
      status = mission.bfsTraversal.running ? "Procesando: " + (mission.bfsTraversal.current != null ? mission.bfsTraversal.current.name : "...") : "BFS Inactivo";
    } else {
      status = mission.dfsTraversal.running ? "Procesando: " + (mission.dfsTraversal.current != null ? mission.dfsTraversal.current.name : "...") : "DFS Inactivo";
    }
    fill(255);
    textSize(largeTextMode ? 14 : 11);
    textAlign(LEFT, TOP);
    text(status, x, y);

    // Draw horizontal boxes
    float boxY = y + 20;
    float boxH = largeTextMode ? 36 : 28;
    float boxW = (w - 20) / 5;
    
    for (int i = 0; i < 5; i++) {
      float bx = x + i * (boxW + 4);
      noFill();
      stroke(COL_CYAN, 60);
      strokeWeight(1);
      rect(bx, boxY, boxW, boxH, 4);

      if (i < container.size()) {
        Node n = container.get(i);
        // Highlight active elements
        if (i == 0 && isQueue) {
          fill(COL_GREEN, 50);
          noStroke();
          rect(bx, boxY, boxW, boxH, 4);
        } else if (i == container.size() - 1 && !isQueue) {
          fill(COL_GREEN, 50);
          noStroke();
          rect(bx, boxY, boxW, boxH, 4);
        }
        
        fill(255);
        textAlign(CENTER, CENTER);
        textSize(largeTextMode ? 13 : 11);
        text(n.name, bx + boxW/2, boxY + boxH/2);
      } else {
        fill(100, 100);
        textAlign(CENTER, CENTER);
        textSize(largeTextMode ? 13 : 11);
        text("-", bx + boxW/2, boxY + boxH/2);
      }
    }

    // Explain FIFO / LIFO
    fill(COL_DIM);
    textSize(largeTextMode ? 12 : 9);
    textAlign(LEFT, TOP);
    if (isQueue) {
      text("FIFO: El primer nodo en entrar es el primero en salir.", x, boxY + boxH + 8);
    } else {
      text("LIFO: El último nodo en entrar es el primero en salir.", x, boxY + boxH + 8);
    }
    popStyle();
  }

  // --- RENDERING DIJKSTRA TABLE ---
  void drawDijkstraTable(float x, float y, float w) {
    pushStyle();
    
    // Status text
    fill(255);
    textSize(largeTextMode ? 13 : 10);
    textAlign(LEFT, TOP);
    text(mission.dijkstraPathfinder.currentStatus, x, y);

    float rowY = y + 16;
    float rowH = largeTextMode ? 18 : 14;

    // Header
    fill(COL_DIM);
    textSize(largeTextMode ? 12 : 9);
    text("Nodo", x, rowY);
    text("Distancia", x + 80, rowY);
    text("Predecesor", x + 160, rowY);
    text("Estado", x + 240, rowY);

    stroke(COL_CYAN, 40);
    line(x, rowY + rowH - 2, x + w, rowY + rowH - 2);
    rowY += rowH;

    // Show 4 interesting nodes (Alicia + startNode + current + others)
    int count = 0;
    textSize(largeTextMode ? 13 : 10);
    for (Node n : mission.nodes) {
      if (count >= 4) break;
      
      // Filter nodes to show relevant ones
      if (n.name.equals("Alicia") || n.visited || n == mission.dijkstraPathfinder.currentNode) {
        fill(n == mission.dijkstraPathfinder.currentNode ? COL_GREEN : 255);
        text(n.name, x, rowY);
        
        String dVal = n.dijkstraDist == Float.MAX_VALUE ? "∞" : String.valueOf((int)n.dijkstraDist);
        text(dVal, x + 80, rowY);
        
        String parentVal = n.dijkstraParent != null ? n.dijkstraParent.name : "-";
        text(parentVal, x + 160, rowY);

        String stateVal = n.visited ? "VISITADO" : (n.dijkstraDist < Float.MAX_VALUE ? "ABIERTO" : "NO VIST.");
        if (n.visited) fill(COL_GREEN);
        else if (n.dijkstraDist < Float.MAX_VALUE) fill(COL_GOLD);
        else fill(COL_DIM);
        text(stateVal, x + 240, rowY);

        rowY += rowH;
        count++;
      }
    }
    popStyle();
  }

  // --- RENDERING KRUSKAL LIST ---
  void drawKruskalCostList(float x, float y, float w) {
    pushStyle();
    
    // Status text
    fill(255);
    textSize(largeTextMode ? 13 : 10);
    textAlign(LEFT, TOP);
    text(mission.kruskalMST.currentStatus, x, y);

    float rowY = y + 16;
    float rowH = largeTextMode ? 18 : 14;

    // List header
    fill(COL_DIM);
    textSize(largeTextMode ? 12 : 9);
    text("Conexión", x, rowY);
    text("Costo", x + 120, rowY);
    text("Decisión", x + 200, rowY);

    stroke(COL_CYAN, 40);
    line(x, rowY + rowH - 2, x + w, rowY + rowH - 2);
    rowY += rowH;

    // Render the last 4 decisions from history or pending edges
    ArrayList<String> history = mission.kruskalMST.decisionHistory;
    int totalItems = history.size();
    
    textSize(largeTextMode ? 12 : 10);
    int shown = 0;
    
    // First show completed decisions (last 3)
    int startIdx = max(0, totalItems - 3);
    for (int i = startIdx; i < totalItems; i++) {
      String line = history.get(i);
      String[] parts = split(line, ':');
      if (parts.length >= 2) {
        fill(parts[1].contains("CONECTADO") ? COL_GREEN : COL_RED);
        text(parts[0], x, rowY);
        text(parts[1].trim(), x + 200, rowY);
      }
      rowY += rowH;
      shown++;
    }

    // Then show the next edge to process
    if (mission.kruskalMST.running && mission.kruskalMST.edgeIndex < mission.kruskalMST.sortedEdges.size()) {
      Edge nextE = mission.kruskalMST.sortedEdges.get(mission.kruskalMST.edgeIndex);
      fill(COL_GOLD);
      text(nextE.a.name + " - " + nextE.b.name, x, rowY);
      text((int)nextE.cost, x + 120, rowY);
      text("SIGUIENTE...", x + 200, rowY);
    }
    popStyle();
  }

  // --- RENDERING MAX FLOW PATHS ---
  void drawMaxFlowHistory(float x, float y, float w) {
    pushStyle();
    
    // Status text
    fill(255);
    textSize(largeTextMode ? 13 : 10);
    textAlign(LEFT, TOP);
    String status = mission.maxFlowCalculator.currentStatus;
    if (!mission.maxFlowCalculator.running && !mission.maxFlowCalculator.finished) {
      String srcName = mission.selectedStartNode != null ? mission.selectedStartNode.name : "?";
      String dstName = mission.selectedEndNode != null ? mission.selectedEndNode.name : "?";
      status = "Fuente: " + srcName + "  |  Destino: " + dstName;
    }
    text(status, x, y);

    float rowY = y + 16;
    float rowH = largeTextMode ? 18 : 14;

    // Header
    fill(COL_DIM);
    textSize(largeTextMode ? 12 : 9);
    text("Historial de Caminos de Aumento", x, rowY);
    stroke(COL_CYAN, 40);
    line(x, rowY + rowH - 2, x + w, rowY + rowH - 2);
    rowY += rowH;

    // Render history (last 3 entries)
    ArrayList<String> history = mission.maxFlowCalculator.augmentingPathsHistory;
    textSize(largeTextMode ? 12 : 9);
    fill(COL_GREEN);
    
    int startIdx = max(0, history.size() - 3);
    for (int i = startIdx; i < history.size(); i++) {
      text(history.get(i), x, rowY);
      rowY += rowH;
    }

    if (history.size() == 0) {
      fill(COL_DIM);
      text("(Ningún camino procesado aún)", x, rowY);
    }
    popStyle();
  }

  // ─────────────────────────────────────────────
  // 3. STEP PROGRESS CARD
  // ─────────────────────────────────────────────

  float drawStepProgress(float x, float y, float w) {
    String[] steps;
    int currentStep;

    int mid = mission.missionID;

    if (mid == 1) {
      steps = new String[]{"Rastrear", "Contener"};
      currentStep = mission.missionPhase;   // 1 or 2
    } else if (mid == 2) {
      steps = new String[]{"Elegir aliado", "Ruta calculada"};
      currentStep = (mission.dijkstraPath != null) ? 2 : 1;
    } else if (mid == 3) {
      steps = new String[]{"Analizar red", "Reconstruir"};
      currentStep = (mission.mstCost > 0) ? 2 : 1;
    } else if (mid == 4) {
      steps = new String[]{"Analizar flujo", "Control aplicado"};
      currentStep = (mission.calculatedMaxFlow > 0) ? 2 : 1;
    } else { // Mission 5
      steps = new String[]{"Rastreo", "Ruta", "Reconstruir", "Control"};
      currentStep = mission.missionStage;
    }

    int numSteps = steps.length;
    float cardH = largeTextMode ? 62 : 56;
    float iy = beginCard(x, y, w, cardH);
    float ix = x + CARD_PAD;
    float innerW = w - CARD_PAD * 2;

    textAlign(LEFT, TOP);
    textSize(largeTextMode ? 12 : 10);
    fill(COL_DIM);
    text("PROGRESO", ix, iy);

    float stepY = iy + (largeTextMode ? 22 : 18);

    float totalW = innerW;
    float dotR = 7;
    float segmentW = (numSteps > 1) ? totalW / (numSteps - 1) : 0;

    for (int i = 0; i < numSteps; i++) {
      float sx = ix + i * segmentW;

      if (i < numSteps - 1) {
        float nx = ix + (i + 1) * segmentW;
        stroke(i + 1 < currentStep ? COL_GREEN : color(50, 65, 80));
        strokeWeight(2);
        line(sx + dotR, stepY, nx - dotR, stepY);
        noStroke();
      }

      boolean completed = (i + 1) < currentStep;
      boolean current   = (i + 1) == currentStep;

      noStroke();
      if (completed) {
        fill(COL_GREEN);
        ellipse(sx, stepY, dotR * 2, dotR * 2);
        fill(8, 14, 28);
        textAlign(CENTER, CENTER);
        textSize(largeTextMode ? 12 : 10);
        text("✓", sx, stepY - 1);
      } else if (current) {
        float pulse = sin(frameCount * 0.08) * 0.3 + 0.7;
        fill(COL_CYAN & 0x00FFFFFF | (int(60 * pulse) << 24));
        ellipse(sx, stepY, dotR * 3.4, dotR * 3.4);
        fill(COL_CYAN);
        ellipse(sx, stepY, dotR * 2, dotR * 2);
        fill(8, 14, 28);
        textAlign(CENTER, CENTER);
        textSize(largeTextMode ? 11 : 9);
        text("→", sx + 1, stepY - 1);
      } else {
        stroke(color(60, 75, 90));
        strokeWeight(1.5);
        fill(COL_CARD_BG);
        ellipse(sx, stepY, dotR * 2, dotR * 2);
        noStroke();
      }

      textAlign(CENTER, TOP);
      textSize(largeTextMode ? 11 : 9);
      fill(current ? COL_CYAN : (completed ? COL_GREEN : COL_DIM));
      float labelX = sx;
      if (i == 0) labelX = max(sx, ix + 18);
      if (i == numSteps - 1) labelX = min(sx, ix + innerW - 18);
      text(steps[i], labelX, stepY + 11);
    }

    return y + cardH + CARD_GAP;
  }

  // ─────────────────────────────────────────────
  // 4. "¿QUÉ HACER?" CARD
  // ─────────────────────────────────────────────

  float drawWhatToDo(float x, float y, float w) {
    String instruction = getInstruction();

    textSize(largeTextMode ? 15 : 13);
    float textW = w - CARD_PAD * 2 - 4;
    int approxLines = max(2, ceil(instruction.length() * (largeTextMode ? 8.5 : 7.5) / textW));
    float textH = approxLines * (largeTextMode ? 20 : 17);
    float cardH = 30 + textH + 8;

    float iy = beginCard(x, y, w, cardH);
    float ix = x + CARD_PAD;

    textAlign(LEFT, TOP);
    textSize(largeTextMode ? 13 : 11);
    fill(COL_GOLD);
    text("¿QUÉ HACER?", ix, iy);

    textSize(largeTextMode ? 15 : 13);
    fill(COL_WHITE);
    textLeading(largeTextMode ? 20 : 17);
    text(instruction, ix, iy + 18, textW, textH + 10);

    return y + cardH + CARD_GAP;
  }

  String getInstruction() {
    int mid = mission.missionID;
    int stage = (mid == 5) ? mission.missionStage : 0;

    if (mid == 1 || stage == 1) {
      if (mission.missionPhase == 1) {
        return "Haz clic en Alicia para iniciar el rastreo. EVA te guiará. Observa cómo BFS explora nivel a nivel, y DFS explora en profundidad.";
      } else {
        return "¡Contención! Haz clic derecho en los enlaces rojos para bloquearlos e impedir que la toxicidad infecte la red social.";
      }
    }
    if (mid == 2 || stage == 2) {
      return "Selecciona a Bruno, Valeria o Sara como apoyo. Ejecuta Dijkstra para encontrar la ruta con menor riesgo hacia la víctima.";
    }
    if (mid == 3 || stage == 3) {
      return "Analiza el costo de conexión de la red. Ejecuta Kruskal para reconstruir la red completa con el costo mínimo social posible.";
    }
    if (mid == 4 || stage == 4) {
      if (mission.selectedStartNode == null) {
        return "Haz clic sobre cualquier nodo para establecer la FUENTE del flujo (ej. Ghost).";
      } else if (mission.selectedEndNode == null) {
        return "Haz clic sobre otro nodo para establecer el DESTINO (ej. Alicia).";
      } else {
        return "Fuente y Destino listos. Haz clic en AUTO o PASO en el visualizador para iniciar el algoritmo Ford-Fulkerson.";
      }
    }
    return "";
  }

  // ─────────────────────────────────────────────
  // 5. NETWORK HEALTH CARD
  // ─────────────────────────────────────────────

  float drawNetworkHealth(float x, float y, float w) {
    int infected = 0;
    for (Node n : mission.nodes) {
      if (n.infected) infected++;
    }
    float toxicity  = map(infected, 0, mission.nodes.size(), 0, 100);
    float stability = 100 - toxicity;

    float cardH = largeTextMode ? 116 : 106;
    float iy = beginCard(x, y, w, cardH);
    float ix = x + CARD_PAD;
    float barW = w - CARD_PAD * 2;

    textAlign(LEFT, TOP);
    textSize(largeTextMode ? 12 : 10);
    fill(COL_DIM);
    text("SALUD DE LA RED", ix, iy);

    float barY = iy + (largeTextMode ? 20 : 18);
    drawHealthBar(ix, barY, barW, "Toxicidad", toxicity, COL_RED);

    barY += largeTextMode ? 42 : 38;
    drawHealthBar(ix, barY, barW, "Estabilidad", stability, COL_GREEN);

    return y + cardH + CARD_GAP;
  }

  void drawHealthBar(float x, float y, float w, String label, float pct, color barCol) {
    float barH = 10;

    textAlign(LEFT, TOP);
    textSize(largeTextMode ? 13 : 11);
    fill(COL_WHITE);
    text(label, x, y);

    textAlign(RIGHT, TOP);
    fill(barCol);
    text(nf(pct, 0, 1) + "%", x + w, y);

    float barY = y + 16;
    noStroke();
    fill(COL_BAR_TRACK);
    rect(x, barY, w, barH, 5);

    float fillW = map(pct, 0, 100, 0, w);
    fill(barCol);
    rect(x, barY, fillW, barH, 5);

    if (fillW > 4) {
      fill(255, 30);
      rect(x, barY, fillW, barH / 2, 5, 5, 0, 0);
    }
  }

  // ─────────────────────────────────────────────
  // 6. CONTROLS CARD
  // ─────────────────────────────────────────────

  float drawControls(float x, float y, float w) {
    int mid = mission.missionID;

    String[][] ctrls;
    if (mid == 1 || (mid == 5 && mission.missionStage == 1)) {
      ctrls = new String[][]{
        {"🖱 Clic",   "Acción Principal"},
        {"🖱 DERECHO", "Bloquear enlace"},
        {"T",         "Cambiar BFS/DFS"},
        {"WASD",      "Mover cámara"},
        {"R",         "Reiniciar misión"},
        {"ESC",       "Regresar al menú"}
      };
    } else {
      ctrls = new String[][]{
        {"🖱 Clic",   "Acción Principal"},
        {"WASD",      "Mover cámara"},
        {"R",         "Reiniciar misión"},
        {"ESC",       "Regresar al menú"}
      };
    }

    int rows = ctrls.length;
    float lineH = largeTextMode ? 21 : 19;
    float cardH = 24 + rows * lineH + 4;
    float iy = beginCard(x, y, w, cardH);
    float ix = x + CARD_PAD;

    textAlign(LEFT, TOP);
    textSize(largeTextMode ? 12 : 10);
    fill(COL_DIM);
    text("CONTROLES DE TECLADO", ix, iy);

    float rowY = iy + 16;
    for (int i = 0; i < rows; i++) {
      textSize(largeTextMode ? 13 : 11);
      fill(COL_CYAN);
      textAlign(LEFT, TOP);
      text(ctrls[i][0], ix, rowY);

      fill(COL_DIM);
      textAlign(LEFT, TOP);
      text("— " + ctrls[i][1], ix + 82, rowY);

      rowY += lineH;
    }

    return y + cardH + CARD_GAP;
  }

  // ─────────────────────────────────────────────
  // INTERACTION / CLICKS IN HUD
  // ─────────────────────────────────────────────
  boolean mousePressed(float mx, float my) {
    float px = width - PANEL_W;
    
    // Check Help Button [?]
    float helpX = px + PAD + (PANEL_W - PAD * 2) - 40;
    float helpY = PAD + 10;
    float helpSize = 30;
    
    if (mx > helpX && mx < helpX + helpSize && my > helpY && my < helpY + helpSize) {
      mission.showingHelpOverlay = !mission.showingHelpOverlay;
      return true;
    }

    // Check Algorithm Control buttons (AUTO / STEP)
    int mid = mission.missionID;
    int stage = (mid == 5) ? mission.missionStage : 0;
    int algType = 0;
    if (mid == 1 || stage == 1) algType = mission.traversalName.equals("BFS") ? 1 : 2;
    else if (mid == 2 || stage == 2) algType = 3;
    else if (mid == 3 || stage == 3) algType = 4;
    else if (mid == 4 || stage == 4) algType = 5;

    if (algType > 0) {
      float visualizerCardY = PAD + (largeTextMode ? 100 : 86) + CARD_GAP;
      float cardH = largeTextMode ? 210 : 180;
      float ctrlY = visualizerCardY + cardH - 42;
      float ix = px + PAD + CARD_PAD;
      float innerW = (PANEL_W - PAD * 2) - CARD_PAD * 2;
      float btnW = (innerW - 10) / 2;

      if (algType == 4 && mission.kruskalMST.running && mission.kruskalMST.waitingForDecision) {
        if (mx > ix && mx < ix + btnW && my > ctrlY && my < ctrlY + 26) {
          mission.kruskalMST.makeDecision(true);
          return true;
        }
        if (mx > ix + btnW + 10 && mx < ix + btnW + 10 + btnW && my > ctrlY && my < ctrlY + 26) {
          mission.kruskalMST.makeDecision(false);
          return true;
        }
      } else if (algType == 5 && mission.maxFlowCalculator.running && mission.maxFlowCalculator.manualMode) {
        if (mx > ix && mx < ix + innerW && my > ctrlY && my < ctrlY + 26) {
          mission.maxFlowCalculator.resetPlayerPath();
          soundManager.playClick();
          return true;
        }
      } else {
        if (mx > ix && mx < ix + btnW && my > ctrlY && my < ctrlY + 26) {
          toggleAlgAuto(algType);
          soundManager.playClick();
          return true;
        }
        if (mx > ix + btnW + 10 && mx < ix + btnW + 10 + btnW && my > ctrlY && my < ctrlY + 26) {
          triggerAlgStep(algType);
          soundManager.playClick();
          return true;
        }
      }
    }

    return false;
  }

  void toggleAlgAuto(int type) {
    if (type == 1) mission.bfsTraversal.autoPlay = !mission.bfsTraversal.autoPlay;
    else if (type == 2) mission.dfsTraversal.autoPlay = !mission.dfsTraversal.autoPlay;
    else mission.algorithmAutoPlay = !mission.algorithmAutoPlay;
  }

  void triggerAlgStep(int type) {
    if (type == 1) {
      mission.bfsTraversal.autoPlay = false;
      mission.bfsTraversal.stepRequested = true;
    } else if (type == 2) {
      mission.dfsTraversal.autoPlay = false;
      mission.dfsTraversal.stepRequested = true;
    } else {
      mission.algorithmAutoPlay = false;
      mission.algorithmStepRequested = true;
    }
  }
}
