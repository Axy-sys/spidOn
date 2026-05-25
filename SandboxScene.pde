import java.util.ArrayList;

class SandboxScene extends Scene {

  ArrayList<Node> nodes;
  ArrayList<Edge> edges;
  ArrayList<Particle> particles;
  ArrayList<Signal> signals;

  DialogueSystem dialogueSystem;
  MessageLog messageLog;

  BFSTraversal bfsTraversal;
  DFSTraversal dfsTraversal;
  DijkstraPathfinder dijkstraPathfinder;
  KruskalMST kruskalMST;
  FordFulkersonMaxFlow maxFlowCalculator;

  // Active settings
  int sandboxMode = 0;      // 0=BFS/DFS, 1=Dijkstra, 2=Kruskal, 3=MaxFlow
  int activePlacementRole = 0; // 0=Neutral, 1=Víctima, 2=Apoyo, 3=Agresor
  String traversalName = "BFS";

  // Step-by-step controls
  boolean runningAlg = false;
  boolean algorithmAutoPlay = true;
  boolean algorithmStepRequested = false;

  // Selection & dragging state
  Node draggingNode = null;
  Node connectingNode = null;
  Edge selectedEdge = null;
  Node selectedStartNode = null;
  Node selectedEndNode = null;

  // Traversal outputs
  ArrayList<Node> dijkstraPath = null;
  float mstCost = 0;
  float calculatedMaxFlow = 0;

  // Alert
  String alertMessage = "";
  float alertAlpha = 0;

  void enter() {
    nodes = new ArrayList<Node>();
    edges = new ArrayList<Edge>();
    particles = new ArrayList<Particle>();
    signals = new ArrayList<Signal>();

    dialogueSystem = new DialogueSystem();
    messageLog = new MessageLog();

    for (int i = 0; i < 100; i++) {
      particles.add(new Particle());
    }

    bfsTraversal = new BFSTraversal(nodes, edges, signals, dialogueSystem, messageLog);
    dfsTraversal = new DFSTraversal(nodes, edges, signals, dialogueSystem, messageLog);
    dijkstraPathfinder = new DijkstraPathfinder(nodes, edges);
    kruskalMST = new KruskalMST(nodes, edges);
    maxFlowCalculator = new FordFulkersonMaxFlow(nodes, edges);

    loadSampleGraph();

    dialogueSystem.eva("¡Bienvenido al Modo Sandbox!");
    dialogueSystem.eva("Aquí puedes diseñar tu propio grafo y ejecutar cualquiera de los 5 algoritmos.");
    dialogueSystem.eva("Clic izquierdo para crear nodos. Mantén Clic Derecho sobre un nodo para conectarlo a otro.");
  }

  void loadSampleGraph() {
    nodes.clear();
    edges.clear();
    dijkstraPath = null;
    mstCost = 0;
    calculatedMaxFlow = 0;
    runningAlg = false;

    Node u0 = new Node(200, 250, "User0", "víctima");
    Node u1 = new Node(400, 180, "User1", "apoyo");
    Node u2 = new Node(400, 360, "User2", "apoyo");
    Node u3 = new Node(650, 270, "User3", "agresor");

    u0.vulnerable = true;
    u1.supportive = true;
    u2.supportive = true;
    u3.infected = true;

    nodes.add(u0);
    nodes.add(u1);
    nodes.add(u2);
    nodes.add(u3);

    Edge e1 = connect(u0, u1); e1.weight = 2; e1.cost = 10; e1.capacity = 15;
    Edge e2 = connect(u0, u2); e2.weight = 5; e2.cost = 20; e2.capacity = 8;
    Edge e3 = connect(u1, u3); e3.weight = 4; e3.cost = 15; e3.capacity = 10;
    Edge e4 = connect(u2, u3); e4.weight = 1; e4.cost = 5;  e4.capacity = 12;

    selectedStartNode = u3; // Harasser
    selectedEndNode = u0;   // Victim
  }

  Edge connect(Node a, Node b) {
    if (a == b) return null;
    for (Edge e : edges) {
      if ((e.a == a && e.b == b) || (e.a == b && e.b == a)) return e; // connection already exists
    }
    a.connect(b);
    b.connect(a);
    Edge e = new Edge(a, b);
    edges.add(e);
    return e;
  }

  void update() {
    for (Node n : nodes) {
      n.update(mouseX, mouseY);
    }
    for (Particle p : particles) {
      p.update();
    }
    for (int i = signals.size() - 1; i >= 0; i--) {
      Signal s = signals.get(i);
      s.update();
      if (s.finished) signals.remove(i);
    }
    dialogueSystem.update();

    if (alertAlpha > 0) alertAlpha -= 2;

    // Execute step-by-step algorithms (only when EVA isn't talking)
    if (runningAlg && !dialogueSystem.isDialogueActive()) {
      if (sandboxMode == 0) {
        // BFS / DFS Traversal
        if (traversalName.equals("BFS")) {
          if (bfsTraversal.running) {
            if (algorithmAutoPlay) {
              if (frameCount % 24 == 0) bfsTraversal.update();
            } else if (algorithmStepRequested) {
              algorithmStepRequested = false;
              bfsTraversal.update();
            }
          } else {
            runningAlg = false;
          }
        } else {
          if (dfsTraversal.running) {
            if (algorithmAutoPlay) {
              if (frameCount % 24 == 0) dfsTraversal.update();
            } else if (algorithmStepRequested) {
              algorithmStepRequested = false;
              dfsTraversal.update();
            }
          } else {
            runningAlg = false;
          }
        }
      } else if (sandboxMode == 1) {
        // Dijkstra
        if (dijkstraPathfinder.running) {
          if (algorithmAutoPlay) {
            if (frameCount % 30 == 0) {
              dijkstraPathfinder.step();
              if (dijkstraPathfinder.finished) dijkstraPath = dijkstraPathfinder.getPath();
            }
          } else if (algorithmStepRequested) {
            algorithmStepRequested = false;
            dijkstraPathfinder.step();
            if (dijkstraPathfinder.finished) dijkstraPath = dijkstraPathfinder.getPath();
          }
        } else {
          runningAlg = false;
        }
      } else if (sandboxMode == 2) {
        // Kruskal
        if (kruskalMST.running) {
          if (algorithmAutoPlay) {
            if (frameCount % 30 == 0) {
              kruskalMST.step();
              if (kruskalMST.finished) mstCost = kruskalMST.totalCost;
            }
          } else if (algorithmStepRequested) {
            algorithmStepRequested = false;
            kruskalMST.step();
            if (kruskalMST.finished) mstCost = kruskalMST.totalCost;
          }
        } else {
          runningAlg = false;
        }
      } else if (sandboxMode == 3) {
        // Max Flow
        if (maxFlowCalculator.running) {
          if (algorithmAutoPlay) {
            if (frameCount % 35 == 0) {
              maxFlowCalculator.step();
              if (maxFlowCalculator.finished) calculatedMaxFlow = maxFlowCalculator.maxFlow;
            }
          } else if (algorithmStepRequested) {
            algorithmStepRequested = false;
            maxFlowCalculator.step();
            if (maxFlowCalculator.finished) calculatedMaxFlow = maxFlowCalculator.maxFlow;
          }
        } else {
          runningAlg = false;
        }
      }
    }

    if (draggingNode != null) {
      draggingNode.x = constrain(mouseX, 30, width - 370);
      draggingNode.y = constrain(mouseY, 30, height - 160);
    }
  }

  void render() {
    background(5, 10, 20);

    // Draw Grid
    stroke(0, 80, 120, 25);
    for (int i = 0; i < width - 340; i += 50) line(i, 0, i, height);
    for (int j = 0; j < height; j += 50) line(0, j, width - 340, j);

    // Render Connections and Dijkstra Path
    if (sandboxMode == 0) {
      if (traversalName.equals("BFS")) bfsTraversal.render();
      else dfsTraversal.render();
    }

    for (Particle p : particles) {
      p.render();
    }
    for (Edge e : edges) {
      e.render();
    }
    for (Signal s : signals) {
      s.render();
    }
    for (Node n : nodes) {
      n.render();
    }

    if (dijkstraPath != null && dijkstraPath.size() > 1 && sandboxMode == 1) {
      pushStyle();
      stroke(0, 255, 120, 200);
      strokeWeight(6);
      for (int i = 0; i < dijkstraPath.size() - 1; i++) {
        Node n1 = dijkstraPath.get(i);
        Node n2 = dijkstraPath.get(i + 1);
        line(n1.x, n1.y, n2.x, n2.y);
      }
      popStyle();
    }

    // Render connection line if dragging to connect
    if (connectingNode != null) {
      stroke(255, 200, 0, 180);
      strokeWeight(2);
      line(connectingNode.x, connectingNode.y, mouseX, mouseY);
    }

    dialogueSystem.renderWorld();

    // RENDER SIDE PANEL (HUD)
    drawSidePanel();

    // Render alerts
    if (alertAlpha > 0 && alertMessage.length() > 0) {
      fill(0, 255, 255, alertAlpha);
      textAlign(CENTER, CENTER);
      textSize(24);
      text(alertMessage, (width - 340)/2, 60);
    }

    // Render EVA dialogue box in screen space
    dialogueSystem.renderUI();
  }

  void drawSidePanel() {
    float px = width - 340;
    noStroke();
    fill(8, 14, 28, 230);
    rect(px, 0, 340, height);

    stroke(0, 255, 255, 70);
    strokeWeight(1.5);
    line(px, 0, px, height);
    noStroke();

    float cx = px + 16;
    float cy = 16;
    float cardW = 340 - 32;

    // 1. Title
    cy = drawPanelHeader(cx, cy, cardW);

    // 2. Sample/Clear options
    cy = drawGraphControls(cx, cy, cardW);

    // 3. Placing Node Role selection
    cy = drawRoleSelector(cx, cy, cardW);

    // 4. Algorithm Selector
    cy = drawAlgorithmSelector(cx, cy, cardW);

    // 5. Algorithm Visualizer & Step controls
    cy = drawAlgorithmVisualizerCard(cx, cy, cardW);

    // 6. Selected Edge editor
    cy = drawEdgeEditorCard(cx, cy, cardW);
  }

  float beginCard(float x, float y, float w, float h) {
    noStroke();
    fill(0, 30);
    rect(x + 2, y + 2, w, h, 10);
    stroke(0, 255, 255, 60);
    strokeWeight(1);
    fill(14, 22, 40, 200);
    rect(x, y, w, h, 10);
    noStroke();
    return y + 12;
  }

  float drawPanelHeader(float x, float y, float w) {
    float h = 64;
    float iy = beginCard(x, y, w, h);
    fill(255);
    textAlign(LEFT, TOP);
    textSize(18);
    text("SANDBOX: EDITOR", x + 12, iy);
    textSize(11);
    fill(0, 255, 255);
    text("Diseña un grafo y simula algoritmos", x + 12, iy + 22);
    return y + h + 8;
  }

  float drawGraphControls(float x, float y, float w) {
    float h = 50;
    float iy = beginCard(x, y, w, h);
    
    // Clear Graph button
    drawButton(x + 12, iy, 130, 26, "[ 🗑️ LIMPIAR ]", false);
    // Sample Graph button
    drawButton(x + 150, iy, 130, 26, "[ 🌀 EJEMPLO ]", false);
    
    return y + h + 8;
  }

  float drawRoleSelector(float x, float y, float w) {
    float h = 95;
    float iy = beginCard(x, y, w, h);
    
    fill(255, 200, 0);
    textAlign(LEFT, TOP);
    textSize(11);
    text("ROL AL CREAR NODO:", x + 12, iy);

    String[] roles = {"Neutral", "Víctima", "Apoyo (Aliado)", "Agresor (Ghost)"};
    float btnY = iy + 16;
    for (int i = 0; i < roles.length; i++) {
      float bx = x + 12 + (i % 2) * 140;
      float by = btnY + (i / 2) * 28;
      drawButton(bx, by, 130, 24, roles[i], activePlacementRole == i);
    }

    return y + h + 8;
  }

  float drawAlgorithmSelector(float x, float y, float w) {
    float h = 95;
    float iy = beginCard(x, y, w, h);
    
    fill(255, 200, 0);
    textAlign(LEFT, TOP);
    textSize(11);
    text("ALGORITMO ACTIVO:", x + 12, iy);

    String[] algs = {"BFS / DFS", "Dijkstra (Ruta)", "Kruskal (MST)", "Max Flow"};
    float btnY = iy + 16;
    for (int i = 0; i < algs.length; i++) {
      float bx = x + 12 + (i % 2) * 140;
      float by = btnY + (i / 2) * 28;
      drawButton(bx, by, 130, 24, algs[i], sandboxMode == i);
    }

    return y + h + 8;
  }

  float drawAlgorithmVisualizerCard(float x, float y, float w) {
    float h = 175;
    float iy = beginCard(x, y, w, h);
    
    fill(0, 255, 255);
    textAlign(LEFT, TOP);
    textSize(11);
    text("EJECUCIÓN DE ALGORITMO", x + 12, iy);

    float contentY = iy + 16;
    textSize(12);
    fill(255);
    
    // Status text
    if (sandboxMode == 0) {
      String status = runningAlg ? ("Modo: " + traversalName + " | Procesando: " + (traversalName.equals("BFS") ? (bfsTraversal.current != null ? bfsTraversal.current.name : "...") : (dfsTraversal.current != null ? dfsTraversal.current.name : "..."))) : "Algoritmo BFS/DFS inactivo.";
      text(status, x + 12, contentY);
      text("Inicio: " + (selectedStartNode != null ? selectedStartNode.name : "(Selecciona clic izquierdo)"), x + 12, contentY + 18);
      
      // BFS / DFS toggle
      drawButton(x + 12, contentY + 38, 120, 24, "[ " + traversalName + " ] T", false);
    } else if (sandboxMode == 1) {
      text(dijkstraPathfinder.currentStatus, x + 12, contentY);
      text("Origen: " + (selectedStartNode != null ? selectedStartNode.name : "nulo") + " → Destino: " + (selectedEndNode != null ? selectedEndNode.name : "nulo"), x + 12, contentY + 18);
      text("(Para elegir, clic izquierdo sobre nodos)", x + 12, contentY + 36);
    } else if (sandboxMode == 2) {
      text(kruskalMST.currentStatus, x + 12, contentY);
      text("Costo del MST: " + (int)mstCost, x + 12, contentY + 18);
    } else if (sandboxMode == 3) {
      text(maxFlowCalculator.currentStatus, x + 12, contentY);
      text("Origen: " + (selectedStartNode != null ? selectedStartNode.name : "nulo") + " → Destino: " + (selectedEndNode != null ? selectedEndNode.name : "nulo"), x + 12, contentY + 18);
      text("Flujo Máximo: " + (int)calculatedMaxFlow, x + 12, contentY + 36);
    }

    // Play / Step / Reset controls
    float btnY = y + h - 38;
    drawButton(x + 12, btnY, 80, 26, algorithmAutoPlay ? "[ ⏸ PAUS ]" : "[ ▶ AUTO ]", algorithmAutoPlay);
    drawButton(x + 100, btnY, 80, 26, "[ ⏭ PASO ]", false);
    drawButton(x + 188, btnY, 90, 26, "[ 🔄 INICIAR ]", false);

    return y + h + 8;
  }

  float drawEdgeEditorCard(float x, float y, float w) {
    float h = 90;
    float iy = beginCard(x, y, w, h);
    
    fill(255, 200, 0);
    textAlign(LEFT, TOP);
    textSize(11);
    text("EDITOR DE CONEXIÓN SELECCIONADA", x + 12, iy);

    float cy = iy + 16;
    fill(255);
    textSize(12);

    if (selectedEdge != null) {
      text("Conexión: " + selectedEdge.a.name + " - " + selectedEdge.b.name, x + 12, cy);
      text("Peso: " + (int)selectedEdge.weight + " | Costo: " + (int)selectedEdge.cost + " | Cap: " + (int)selectedEdge.capacity, x + 12, cy + 16);
      
      // Plus / minus adjust buttons
      float btnY = cy + 34;
      drawButton(x + 12, btnY, 80, 22, "PESO +/-", false);
      drawButton(x + 100, btnY, 80, 22, "COSTO +/-", false);
      drawButton(x + 188, btnY, 80, 22, "CAP +/-", false);
    } else {
      fill(140);
      text("(Haz clic sobre una arista para editarla)", x + 12, cy);
    }

    return y + h + 8;
  }

  void drawButton(float x, float y, float w, float h, String label, boolean active) {
    pushStyle();
    if (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h) {
      fill(0, 255, 255);
      rect(x, y, w, h, 6);
      fill(0);
    } else if (active) {
      fill(0, 255, 255, 80);
      stroke(0, 255, 255, 200);
      rect(x, y, w, h, 6);
      fill(255);
    } else {
      fill(20, 32, 54);
      stroke(0, 255, 255, 50);
      rect(x, y, w, h, 6);
      fill(255);
    }
    textAlign(CENTER, CENTER);
    textSize(largeTextMode ? 13 : 11);
    text(label, x + w/2, y + h/2 - 1);
    popStyle();
  }

  // ==========================================
  // INPUT HANDLING
  // ==========================================

  void mousePressed() {
    // Check Dialogue System clicks first
    if (dialogueSystem.isDialogueActive()) {
      dialogueSystem.skipOrAdvance();
      return;
    }

    // Check if clicked the HUD/Panel
    if (mouseX >= width - 340) {
      handlePanelClicks();
      return;
    }

    if (runningAlg) {
      triggerAlert("¡DESACTIVA LA SIMULACIÓN PARA EDITAR!");
      soundManager.playError();
      return;
    }

    // ─── GAMEPLAY VIEW CLICKS ───
    
    // Check if clicked on a node
    Node clickedNode = null;
    for (Node n : nodes) {
      if (dist(mouseX, mouseY, n.x, n.y) < n.radius) {
        clickedNode = n;
        break;
      }
    }

    if (mouseButton == LEFT) {
      if (clickedNode != null) {
        // Left click node:
        // Set selected node based on sandbox mode
        if (sandboxMode == 0 || sandboxMode == 1 || sandboxMode == 3) {
          if (selectedStartNode == null) {
            selectedStartNode = clickedNode;
            triggerAlert("NODO ORIGEN: " + clickedNode.name);
          } else if (selectedStartNode == clickedNode) {
            selectedStartNode = null;
            triggerAlert("ORIGEN LIMPIADO");
          } else {
            selectedEndNode = clickedNode;
            triggerAlert("NODO DESTINO: " + clickedNode.name);
          }
        }
        draggingNode = clickedNode;
        selectedEdge = null;
      } else {
        // Left click empty space: Create Node!
        // First check if clicked on an edge
        Edge clickedEdge = null;
        for (Edge e : edges) {
          if (e.isMouseNear(mouseX, mouseY)) {
            clickedEdge = e;
            break;
          }
        }

        if (clickedEdge != null) {
          selectedEdge = clickedEdge;
          triggerAlert("ARISTA SELECCIONADA");
        } else {
          // Add Node
          String name = "User" + nodes.size();
          String role = "";
          Node n = new Node(mouseX, mouseY, name);
          
          if (activePlacementRole == 0) {
            role = "neutral";
          } else if (activePlacementRole == 1) {
            n.vulnerable = true;
            role = "víctima";
          } else if (activePlacementRole == 2) {
            n.supportive = true;
            role = "apoyo";
          } else if (activePlacementRole == 3) {
            n.infected = true;
            n.toxicity = 100;
            role = "agresor";
          }
          
          n.role = role;
          nodes.add(n);
          triggerAlert("CREADO NODO: " + name);
          selectedEdge = null;
        }
      }
    }

    if (mouseButton == RIGHT) {
      if (clickedNode != null) {
        // Start connection
        connectingNode = clickedNode;
      } else {
        // Right click empty space: toggle block on clicked edge
        for (Edge e : edges) {
          if (e.isMouseNear(mouseX, mouseY)) {
            e.blocked = !e.blocked;
            triggerAlert(e.blocked ? "ENLACE BLOQUEADO" : "ENLACE ACTIVO");
            break;
          }
        }
      }
    }
  }

  void mouseReleased() {
    draggingNode = null;

    if (connectingNode != null) {
      // Connect to target node if released over it
      for (Node n : nodes) {
        if (n != connectingNode && dist(mouseX, mouseY, n.x, n.y) < n.radius) {
          Edge e = connect(connectingNode, n);
          if (e != null) {
            triggerAlert("CONECTADOS: " + connectingNode.name + " - " + n.name);
          }
          break;
        }
      }
      connectingNode = null;
    }
  }

  void handlePanelClicks() {
    float px = width - 340;
    float cx = px + 16;

    // --- 2. Sample/Clear Graph Controls ---
    float visualizerCardY = 16 + 64 + 8; // Y starts after header
    float iy = visualizerCardY + 12;
    // Clear: x+12, size 130
    if (mouseX > cx + 12 && mouseX < cx + 142 && mouseY > iy && mouseY < iy + 26) {
      if (runningAlg) { triggerAlert("¡DESACTIVA LA SIMULACIÓN PARA BORRAR!"); soundManager.playError(); return; }
      nodes.clear();
      edges.clear();
      selectedStartNode = null;
      selectedEndNode = null;
      selectedEdge = null;
      dijkstraPath = null;
      mstCost = 0;
      calculatedMaxFlow = 0;
      runningAlg = false;
      triggerAlert("GRAFO BORRADO");
    }
    // Sample: x+150, size 130
    if (mouseX > cx + 150 && mouseX < cx + 280 && mouseY > iy && mouseY < iy + 26) {
      if (runningAlg) { triggerAlert("¡DESACTIVA LA SIMULACIÓN PARA CAMBIAR!"); soundManager.playError(); return; }
      loadSampleGraph();
      triggerAlert("GRAFO DE EJEMPLO CARGADO");
    }

    // --- 3. Role Placement Selector ---
    float roleSelectorY = visualizerCardY + 50 + 8;
    float ry = roleSelectorY + 28;
    for (int i = 0; i < 4; i++) {
      float bx = cx + 12 + (i % 2) * 140;
      float by = ry + (i / 2) * 28;
      if (mouseX > bx && mouseX < bx + 130 && mouseY > by && mouseY < by + 24) {
        if (runningAlg) { triggerAlert("¡DESACTIVA LA SIMULACIÓN PARA EDITAR ROL!"); soundManager.playError(); return; }
        activePlacementRole = i;
        return;
      }
    }

    // --- 4. Algorithm Selector ---
    float algSelectorY = roleSelectorY + 95 + 8;
    float ay = algSelectorY + 28;
    for (int i = 0; i < 4; i++) {
      float bx = cx + 12 + (i % 2) * 140;
      float by = ay + (i / 2) * 28;
      if (mouseX > bx && mouseX < bx + 130 && mouseY > by && mouseY < by + 24) {
        sandboxMode = i;
        runningAlg = false;
        dijkstraPath = null;
        mstCost = 0;
        calculatedMaxFlow = 0;
        triggerAlert("MODO ALGORITMO: M0" + (i + 1));
        return;
      }
    }

    // --- 5. Algorithm Execution Controls ---
    float visualizerCardY2 = algSelectorY + 95 + 8;
    float contentY = visualizerCardY2 + 12 + 16;
    
    // Toggle BFS / DFS button
    if (sandboxMode == 0 && mouseX > cx + 12 && mouseX < cx + 132 && mouseY > contentY + 38 && mouseY < contentY + 62) {
      if (traversalName.equals("BFS")) {
        traversalName = "DFS";
      } else {
        traversalName = "BFS";
      }
      runningAlg = false;
      triggerAlert("MODO: " + traversalName);
    }

    // Play / Step / Reset controls
    float btnY = visualizerCardY2 + 175 - 38;
    // Play/Pause
    if (mouseX > cx + 12 && mouseX < cx + 92 && mouseY > btnY && mouseY < btnY + 26) {
      algorithmAutoPlay = !algorithmAutoPlay;
    }
    // Step
    if (mouseX > cx + 100 && mouseX < cx + 180 && mouseY > btnY && mouseY < btnY + 26) {
      algorithmAutoPlay = false;
      algorithmStepRequested = true;
    }
    // Start Alg
    if (mouseX > cx + 188 && mouseX < cx + 278 && mouseY > btnY && mouseY < btnY + 26) {
      startSelectedAlgorithm();
    }

    // --- 6. Edge Editor Adjust buttons ---
    float edgeEditorY = visualizerCardY2 + 175 + 8;
    float ey = edgeEditorY + 12 + 16 + 34;
    if (selectedEdge != null) {
      // Weight +/-: cx+12, size 80
      if (mouseX > cx + 12 && mouseX < cx + 92 && mouseY > ey && mouseY < ey + 22) {
        if (runningAlg) { triggerAlert("¡DESACTIVA LA SIMULACIÓN PARA EDITAR ENLACE!"); soundManager.playError(); return; }
        selectedEdge.weight = (selectedEdge.weight % 9) + 1; // cycles 1..9
        triggerAlert("PESO ACTUALIZADO: " + (int)selectedEdge.weight);
      }
      // Cost +/-: cx+100, size 80
      if (mouseX > cx + 100 && mouseX < cx + 180 && mouseY > ey && mouseY < ey + 22) {
        if (runningAlg) { triggerAlert("¡DESACTIVA LA SIMULACIÓN PARA EDITAR ENLACE!"); soundManager.playError(); return; }
        selectedEdge.cost = (selectedEdge.cost + 5 > 50) ? 5 : (selectedEdge.cost + 5);
        triggerAlert("COSTO ACTUALIZADO: " + (int)selectedEdge.cost);
      }
      // Cap +/-: cx+188, size 80
      if (mouseX > cx + 188 && mouseX < cx + 268 && mouseY > ey && mouseY < ey + 22) {
        if (runningAlg) { triggerAlert("¡DESACTIVA LA SIMULACIÓN PARA EDITAR ENLACE!"); soundManager.playError(); return; }
        selectedEdge.capacity = (selectedEdge.capacity + 2 > 20) ? 2 : (selectedEdge.capacity + 2);
        triggerAlert("CAPACIDAD ACTUALIZADA: " + (int)selectedEdge.capacity);
      }
    }
  }

  void startSelectedAlgorithm() {
    runningAlg = true;
    dijkstraPath = null;
    mstCost = 0;
    calculatedMaxFlow = 0;

    if (sandboxMode == 0) {
      if (selectedStartNode == null) {
        runningAlg = false;
        triggerAlert("¡ELIJE UN NODO ORIGEN!");
        return;
      }
      if (traversalName.equals("BFS")) {
        bfsTraversal.start(selectedStartNode);
      } else {
        dfsTraversal.start(selectedStartNode);
      }
      triggerAlert("INICIANDO RECORRIDO " + traversalName);
    } else if (sandboxMode == 1) {
      if (selectedStartNode == null || selectedEndNode == null) {
        runningAlg = false;
        triggerAlert("¡SELECCIONA ORIGEN Y DESTINO!");
        return;
      }
      dijkstraPathfinder.startStepByStep(selectedStartNode, selectedEndNode);
      triggerAlert("INICIANDO DIJKSTRA");
    } else if (sandboxMode == 2) {
      kruskalMST.startStepByStep();
      triggerAlert("INICIANDO KRUSKAL (MST)");
    } else if (sandboxMode == 3) {
      if (selectedStartNode == null || selectedEndNode == null) {
        runningAlg = false;
        triggerAlert("¡SELECCIONA ORIGEN Y DESTINO!");
        return;
      }
      maxFlowCalculator.startStepByStep(selectedStartNode, selectedEndNode);
      triggerAlert("INICIANDO MAX FLOW");
    }
  }

  void triggerAlert(String msg) {
    alertMessage = msg;
    alertAlpha = 255;
  }

  void keyPressed() {
    if (key == ESC) {
      key = 0;
      game.sceneManager.changeScene(new MenuScene());
    }
    
    // Space bar inside traversal skips Eva text
    if (key == ' ') {
      if (dialogueSystem.isDialogueActive()) {
        dialogueSystem.skipOrAdvance();
      }
    }

    if (key == BACKSPACE || key == DELETE || (key == CODED && keyCode == DELETE)) {
      if (runningAlg) {
        triggerAlert("¡DESACTIVA LA SIMULACIÓN PARA EDITAR!");
        soundManager.playError();
        return;
      }
      
      Node hoveredNode = null;
      for (Node n : nodes) {
        if (dist(mouseX, mouseY, n.x, n.y) < n.radius) {
          hoveredNode = n;
          break;
        }
      }

      if (hoveredNode != null) {
        deleteNodeSafely(hoveredNode);
        soundManager.playClick();
        triggerAlert("NODO " + hoveredNode.name + " ELIMINADO");
        return;
      }

      Edge hoveredEdge = null;
      for (Edge e : edges) {
        if (e.isMouseNear(mouseX, mouseY)) {
          hoveredEdge = e;
          break;
        }
      }

      if (hoveredEdge != null) {
        deleteEdgeSafely(hoveredEdge);
        soundManager.playClick();
        triggerAlert("ENLACE ELIMINADO");
        return;
      }

      if (selectedEdge != null) {
        deleteEdgeSafely(selectedEdge);
        soundManager.playClick();
        triggerAlert("ENLACE SELECCIONADO ELIMINADO");
        return;
      }
    }

    if (key == 'c' || key == 'C') {
      if (runningAlg) { triggerAlert("¡DESACTIVA LA SIMULACIÓN PARA BORRAR!"); soundManager.playError(); return; }
      nodes.clear();
      edges.clear();
      selectedStartNode = null;
      selectedEndNode = null;
      selectedEdge = null;
      dijkstraPath = null;
      mstCost = 0;
      calculatedMaxFlow = 0;
      runningAlg = false;
      triggerAlert("GRAFO BORRADO");
    }

    if (key == 'r' || key == 'R') {
      if (runningAlg) { triggerAlert("¡DESACTIVA LA SIMULACIÓN PARA REINICIAR!"); soundManager.playError(); return; }
      loadSampleGraph();
      triggerAlert("REINICIADO");
    }
  }

  void deleteNodeSafely(Node target) {
    nodes.remove(target);
    for (int i = edges.size() - 1; i >= 0; i--) {
      Edge e = edges.get(i);
      if (e.a == target || e.b == target) {
        edges.remove(i);
      }
    }
    for (Node n : nodes) {
      n.neighbors.remove(target);
    }
    if (selectedStartNode == target) selectedStartNode = null;
    if (selectedEndNode == target) selectedEndNode = null;
    if (draggingNode == target) draggingNode = null;
    if (connectingNode == target) connectingNode = null;
    selectedEdge = null;
  }

  void deleteEdgeSafely(Edge target) {
    edges.remove(target);
    target.a.neighbors.remove(target.b);
    target.b.neighbors.remove(target.a);
    if (selectedEdge == target) selectedEdge = null;
  }
}
