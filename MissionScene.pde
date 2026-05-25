class MissionScene extends Scene {

  ArrayList<Node> nodes;
  ArrayList<Edge> edges;
  ArrayList<Particle> particles;
  ArrayList<Signal> signals;

  TraversalStrategy traversal;
  BFSTraversal bfsTraversal;
  DFSTraversal dfsTraversal;
  String traversalName = "BFS";

  InfectionSystem infectionSystem;
  DialogueSystem dialogueSystem;

  HUDView hudView;
  MissionController controller;

  NarrativeSystem narrative;
  EmotionSystem emotionSystem;

  MessageLog messageLog;

  Node selectedNode;

  int missionID = 1;
  int missionPhase = 1;
  int missionStage = 1; // Used in Mission 5 (Final)

  // Rework variables
  int score = 10000;
  boolean showingHelpOverlay = false;
  boolean algorithmAutoPlay = true;
  boolean algorithmStepRequested = false;
  String playerInitials = "";
  boolean initialsSaved = false;
  LeaderboardManager leaderboardManager;
  Node selectedStartNode = null;
  Node selectedEndNode = null;

  boolean sourceFound = false;

  int containmentTimer = 0;
  int containmentGoal = 30 * 60; // 30 seconds at 60 FPS

  boolean missionComplete = false;
  boolean missionFailed = false;

  boolean successAnnounced = false;
  boolean failureAnnounced = false;

  float camX = 0;
  float camY = 0;

  String alertMessage = "";
  float alertAlpha = 0;
  boolean showAlert = false;

  float redPulse = 0;

  boolean transitioningPhase = false;
  int transitionTimer = 0;
  float cinematicFade = 0;
  String cinematicText = "";

  // Algorithm instances
  DijkstraPathfinder dijkstraPathfinder;
  KruskalMST kruskalMST;
  FordFulkersonMaxFlow maxFlowCalculator;

  // Algorithm outputs
  ArrayList<Node> dijkstraPath = null;
  float mstCost = 0;
  float calculatedMaxFlow = 0;

  // Idle hint system — if the player does nothing for 6 seconds, EVA reminds them
  int idleFrameCounter = 0;
  int idleHintDelay = 360; // 6 seconds at 60fps
  boolean idleHintShown = false;
  boolean introDialogueShown = false;

  MissionScene() {
    this.missionID = 1;
  }

  MissionScene(int missionID) {
    this.missionID = missionID;
  }

  // =========================
  // ENTER
  // =========================

  void enter() {
    missionPhase = 1;
    missionStage = 1;
    sourceFound = false;
    containmentTimer = 0;
    missionComplete = false;
    missionFailed = false;
    successAnnounced = false;
    failureAnnounced = false;
    selectedNode = null;
    dijkstraPath = null;
    mstCost = 0;
    calculatedMaxFlow = 0;

    score = 10000;
    showingHelpOverlay = false;
    algorithmAutoPlay = true;
    algorithmStepRequested = false;
    playerInitials = "";
    initialsSaved = false;
    leaderboardManager = new LeaderboardManager(sketchPath("data/leaderboard.txt"));
    selectedStartNode = null;
    selectedEndNode = null;

    camX = 0;
    camY = 0;

    alertMessage = "";
    alertAlpha = 0;
    showAlert = false;

    nodes = new ArrayList<Node>();
    edges = new ArrayList<Edge>();
    particles = new ArrayList<Particle>();
    signals = new ArrayList<Signal>();

    dialogueSystem = new DialogueSystem();
    messageLog = new MessageLog();

    createNetwork();

    for (int i = 0; i < 180; i++) {
      particles.add(new Particle());
    }

    bfsTraversal = new BFSTraversal(nodes, edges, signals, dialogueSystem, messageLog);
    dfsTraversal = new DFSTraversal(nodes, edges, signals, dialogueSystem, messageLog);
    traversal = bfsTraversal;
    traversalName = "BFS";

    infectionSystem = new InfectionSystem(nodes, edges, signals, dialogueSystem, messageLog);
    infectionSystem.setActive(false);
    infectionSystem.setInterval(180);

    dijkstraPathfinder = new DijkstraPathfinder(nodes, edges);
    kruskalMST = new KruskalMST(nodes, edges);
    kruskalMST.manualMode = true;
    maxFlowCalculator = new FordFulkersonMaxFlow(nodes, edges);
    maxFlowCalculator.manualMode = true;

    hudView = new HUDView(this);
    controller = new MissionController(this);
    narrative = new NarrativeSystem(this);
    emotionSystem = new EmotionSystem(nodes, dialogueSystem);

    setupMissionNarrative();
    setupGlowHints();
  }

  // ============ GLOW HINT SETUP ============
  // Makes target nodes pulse so the player knows what to click

  void setupGlowHints() {
    clearGlowHints();
    int mid = missionID;
    int stage = (mid == 5) ? missionStage : 0;

    if (mid == 1 || stage == 1) {
      // Phase 1: highlight all clickable nodes, especially Alicia
      if (missionPhase == 1) {
        for (Node n : nodes) n.glowHint = true;
      }
    } else if (mid == 2 || stage == 2) {
      // Highlight support nodes
      for (Node n : nodes) {
        if (n.supportive || n.name.equals("Bruno") || n.name.equals("Sara") || n.name.equals("Valeria")) {
          n.glowHint = true;
        }
      }
    } else if (mid == 3 || stage == 3) {
      // No specific node to click — hint on all nodes
      for (Node n : nodes) n.glowHint = true;
    } else if (mid == 4 || stage == 4) {
      // No specific node to click — hint on all nodes
      for (Node n : nodes) n.glowHint = true;
    }
  }

  void clearGlowHints() {
    for (Node n : nodes) n.glowHint = false;
  }

  // ============ NARRATIVE SETUP ============
  // EVA guides the player step by step — conversational and clear

  void setupMissionNarrative() {
    if (missionID == 1) {
      dialogueSystem.eva("¡Hola! Soy EVA, tu asistente de análisis de redes sociales.");
      dialogueSystem.eva("Alicia ha recibido mensajes ofensivos y necesitamos tu ayuda.");
      dialogueSystem.eva("Haz clic en cualquier usuario de la red para empezar a rastrear cómo se propaga el acoso.");
      dialogueSystem.eva("Tu objetivo: encontrar quién es 'Ghost', la cuenta agresora. ¡Los nodos que brillan te indican dónde hacer clic!");
      triggerAlert("PROPAGACIÓN DETECTADA");
    } else if (missionID == 2) {
      dialogueSystem.eva("¡Buenas noticias! Ya identificamos al agresor.");
      dialogueSystem.eva("Ahora Alicia necesita apoyo urgente, pero debemos encontrar la ruta con menor riesgo.");
      dialogueSystem.eva("Haz clic en uno de los nodos que brillan — son los aliados de Alicia: Bruno, Valeria o Sara.");
      triggerAlert("BUSCANDO RUTA SEGURA");
    } else if (missionID == 3) {
      dialogueSystem.eva("El acoso destruyó las conexiones de confianza entre los usuarios.");
      dialogueSystem.eva("Necesitamos reconstruir la red con el menor costo posible.");
      dialogueSystem.eva("Haz clic en cualquier lugar de la red para iniciar la reconstrucción.");
      triggerAlert("RECONSTRUYENDO RED");
    } else if (missionID == 4) {
      dialogueSystem.eva("Ghost está inundando la red con mensajes tóxicos.");
      dialogueSystem.eva("Necesitamos calcular cuánto daño puede hacer para poder bloquearlo.");
      dialogueSystem.eva("Haz clic en cualquier lugar para analizar el flujo de mensajes.");
      triggerAlert("CALCULANDO FLUJO MÁXIMO");
    } else if (missionID == 5) {
      dialogueSystem.eva("¡Misión final! Vas a usar todo lo que aprendiste.");
      dialogueSystem.eva("Paso 1: Primero, rastrea la cuenta agresora usando BFS o DFS.");
      dialogueSystem.eva("Haz clic en cualquier usuario para empezar. ¡Tú puedes!");
      triggerAlert("MISIÓN FINAL: INTEGRACIÓN");
    }
  }

  // =========================
  // NETWORK
  // =========================

  void createNetwork() {
    Node a = new Node(300, 250, "Alicia", "víctima");
    Node b = new Node(550, 200, "Bruno", "apoyo");
    Node c = new Node(700, 400, "Carla", "observadora");
    Node d = new Node(450, 520, "Diego", "vulnerable");
    Node e = new Node(850, 250, "Ghost", "agresor");
    Node f = new Node(1000, 420, "Valeria", "apoyo");
    Node g = new Node(1200, 300, "Andrés", "observador");
    Node h = new Node(980, 580, "Sara", "apoyo");

    // =========================
    // STATES & VALUES
    // =========================
    e.infected = true;
    e.toxicity = 100;
    d.vulnerable = true;
    f.supportive = true;
    h.supportive = true;
    b.support = 90;
    f.support = 95;
    h.support = 95;
    a.stress = 20;
    d.stress = 60;
    c.stress = 35;

    nodes.add(a);
    nodes.add(b);
    nodes.add(c);
    nodes.add(d);
    nodes.add(e);
    nodes.add(f);
    nodes.add(g);
    nodes.add(h);

    // Build connections and set weights (Mission 2), costs (Mission 3), and capacities (Mission 4)
    // Alicia - Bruno
    Edge e_ab = connect(a, b);
    e_ab.weight = 2; e_ab.cost = 10; e_ab.capacity = 15;

    // Bruno - Carla
    Edge e_bc = connect(b, c);
    e_bc.weight = 3; e_bc.cost = 18; e_bc.capacity = 10;

    // Alicia - Diego
    Edge e_ad = connect(a, d);
    e_ad.weight = 8; e_ad.cost = 35; e_ad.capacity = 5;

    // Carla - Ghost
    Edge e_ce = connect(c, e);
    e_ce.weight = 9; e_ce.cost = 40; e_ce.capacity = 4;

    // Bruno - Ghost
    Edge e_be = connect(b, e);
    e_be.weight = 7; e_be.cost = 45; e_be.capacity = 12;

    // Ghost - Valeria
    Edge e_ef = connect(e, f);
    e_ef.weight = 5; e_ef.cost = 25; e_ef.capacity = 10;

    // Valeria - Andrés
    Edge e_fg = connect(f, g);
    e_fg.weight = 4; e_fg.cost = 15; e_fg.capacity = 8;

    // Diego - Sara
    Edge e_dh = connect(d, h);
    e_dh.weight = 2; e_dh.cost = 12; e_dh.capacity = 10;

    // Sara - Andrés
    Edge e_hg = connect(h, g);
    e_hg.weight = 6; e_hg.cost = 22; e_hg.capacity = 6;

    // Carla - Sara
    Edge e_ch = connect(c, h);
    e_ch.weight = 5; e_ch.cost = 20; e_ch.capacity = 8;
  }

  Edge connect(Node a, Node b) {
    a.connect(b);
    b.connect(a);
    Edge e = new Edge(a, b);
    edges.add(e);
    return e;
  }

  // =========================
  // UPDATE
  // =========================

  void update() {
    redPulse += 0.04;
    float worldMouseX = mouseX - camX;
    float worldMouseY = mouseY - camY;

    for (Node n : nodes) {
      n.update(worldMouseX, worldMouseY);
    }

    for (Particle p : particles) {
      p.update();
    }

    for (int i = signals.size() - 1; i >= 0; i--) {
      Signal s = signals.get(i);
      s.update();
      if (s.finished) {
        signals.remove(i);
      }
    }

    dialogueSystem.update();
    emotionSystem.update();
    updateCamera();
    updateAlerts();
    updateIdleHints();

    if (missionID == 1 || (missionID == 5 && missionStage == 1)) {
      if (!showingHelpOverlay && !dialogueSystem.isDialogueActive()) {
        traversal.update();
      }
    }
    
    controller.update();
    updatePhaseTransition();

    // Score decay over time (approx -5 points per second)
    if (!missionComplete && !missionFailed && !showingHelpOverlay && !dialogueSystem.isDialogueActive()) {
      if (frameCount % 12 == 0) {
        score = max(0, score - 5);
      }
    }

    // --- DIJKSTRA STEP BY STEP UPDATES ---
    if (missionID == 2 || (missionID == 5 && missionStage == 2)) {
      if (dijkstraPathfinder.running && !showingHelpOverlay && !dialogueSystem.isDialogueActive()) {
        if (algorithmAutoPlay) {
          if (frameCount % 24 == 0) {
            dijkstraPathfinder.step();
            if (dijkstraPathfinder.finished) {
              dijkstraPath = dijkstraPathfinder.getPath();
            }
          }
        } else if (algorithmStepRequested) {
          algorithmStepRequested = false;
          dijkstraPathfinder.step();
          if (dijkstraPathfinder.finished) {
            dijkstraPath = dijkstraPathfinder.getPath();
          }
        }
      }
    }

    // --- KRUSKAL STEP BY STEP UPDATES ---
    if (missionID == 3 || (missionID == 5 && missionStage == 3)) {
      if (kruskalMST.running && !showingHelpOverlay && !dialogueSystem.isDialogueActive()) {
        if (algorithmAutoPlay) {
          if (frameCount % 30 == 0) {
            kruskalMST.step();
            if (kruskalMST.finished) {
              mstCost = kruskalMST.totalCost;
            }
          }
        } else if (algorithmStepRequested) {
          algorithmStepRequested = false;
          kruskalMST.step();
          if (kruskalMST.finished) {
            mstCost = kruskalMST.totalCost;
          }
        }
      }
    }

    // --- FF MAX FLOW STEP BY STEP UPDATES ---
    if (missionID == 4 || (missionID == 5 && missionStage == 4)) {
      if (maxFlowCalculator.running && !showingHelpOverlay && !dialogueSystem.isDialogueActive()) {
        if (algorithmAutoPlay) {
          if (frameCount % 35 == 0) {
            maxFlowCalculator.step();
            if (maxFlowCalculator.finished) {
              calculatedMaxFlow = maxFlowCalculator.maxFlow;
            }
          }
        } else if (algorithmStepRequested) {
          algorithmStepRequested = false;
          maxFlowCalculator.step();
          if (maxFlowCalculator.finished) {
            calculatedMaxFlow = maxFlowCalculator.maxFlow;
          }
        }
      }
    }

    // ==========================================
    // MISSION SPECIFIC COMPLETION AND FLOW LOGIC
    // ==========================================

    // --- MISSION 1: Tracing & Containment ---
    if (missionID == 1) {
      if (!sourceFound && missionPhase == 1) {
        Node ghost = getNode("Ghost");
        if (ghost != null && ghost.visited) {
          sourceFound = true;
          startPhaseTransition();
        }
      }

      if (missionPhase == 2 && !missionComplete && !missionFailed) {
        if (!dialogueSystem.isDialogueActive()) {
          infectionSystem.setActive(true);
          infectionSystem.setInterval(120);
          infectionSystem.update();

          containmentTimer++;
          if (containmentTimer >= containmentGoal) {
            missionComplete = true;
          }
        } else {
          // Temporarily pause infection system ticks while reading dialogue
          infectionSystem.setActive(false);
        }
      }
      missionFailed = infectionSystem.hasFailed();
    }

    // --- MISSION 2: Safest path (Dijkstra) ---
    else if (missionID == 2) {
      if (dijkstraPath != null && !missionComplete) {
        missionComplete = true;
      }
    }

    // --- MISSION 3: Kruskal MST ---
    else if (missionID == 3) {
      if (mstCost > 0 && !missionComplete) {
        missionComplete = true;
      }
    }

    // --- MISSION 4: Ford-Fulkerson Max Flow ---
    else if (missionID == 4) {
      if (calculatedMaxFlow > 0 && !missionComplete) {
        missionComplete = true;
      }
    }

    // --- MISSION 5: Integration (Sequential Stages) ---
    else if (missionID == 5) {
      if (missionStage == 1) {
        if (!sourceFound) {
          Node ghost = getNode("Ghost");
          if (ghost != null && ghost.visited) {
            sourceFound = true;
            dialogueSystem.eva("Fase 1 completada: Ghost rastreado.");
            delayNarrative("Fase 2: Encuentra la ruta más segura desde Valeria hasta Alicia.", 120);
            delayNarrative("Haz clic izquierdo en Valeria para ejecutar Dijkstra.", 240);
            missionStage = 2;
          }
        }
      } else if (missionStage == 2) {
        if (dijkstraPath != null) {
          dialogueSystem.eva("¡Paso 2 completado! La ruta segura está trazada.");
          dialogueSystem.eva("Paso 3: Ahora reconstruiremos las conexiones de confianza de la red.");
          dialogueSystem.eva("Haz clic en cualquier lugar para reconstruir. ¡Ya casi terminamos!");
          missionStage = 3;
          setupGlowHints();
        }
      } else if (missionStage == 3) {
        if (mstCost > 0) {
          dialogueSystem.eva("¡Paso 3 completado! Red reconstruida con costo " + (int)mstCost + ".");
          dialogueSystem.eva("Último paso: Analiza el flujo de mensajes tóxicos de Ghost.");
          dialogueSystem.eva("Haz clic en cualquier lugar para el análisis final. ¡Tú puedes!");
          missionStage = 4;
          setupGlowHints();
        }
      } else if (missionStage == 4) {
        if (calculatedMaxFlow > 0 && !missionComplete) {
          missionComplete = true;
        }
      }
    }

    // --- Announcement of results ---
    if (missionFailed && !failureAnnounced) {
      failureAnnounced = true;
      narrative.missionFailed();
    }

    if (missionComplete && !successAnnounced) {
      successAnnounced = true;
      score += 2000; // completion bonus!
      narrative.missionSuccess();
      // Unlock subsequent mission in Game progress
      if (game != null && missionID < 5) {
        game.unlockedMissions[missionID] = true;
      }
    }
  }

  // =========================
  // RENDER
  // =========================

  void render() {
    background(5, 10, 20);

    drawDangerOverlay();

    pushMatrix();
    translate(camX, camY);

    drawGrid();

    if (missionID == 1 || (missionID == 5 && missionStage == 1)) {
      traversal.render();
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

    // Highlight Dijkstra Path visually if calculated
    if (dijkstraPath != null && dijkstraPath.size() > 1) {
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

    // Highlight manual path tracing in Max Flow
    if (maxFlowCalculator.running && maxFlowCalculator.manualMode && maxFlowCalculator.playerPath != null && maxFlowCalculator.playerPath.size() > 1) {
      pushStyle();
      stroke(colorblindMode ? color(253, 184, 99) : color(255, 200, 0), 220);
      strokeWeight(6);
      for (int i = 0; i < maxFlowCalculator.playerPath.size() - 1; i++) {
        Node n1 = maxFlowCalculator.playerPath.get(i);
        Node n2 = maxFlowCalculator.playerPath.get(i + 1);
        line(n1.x, n1.y, n2.x, n2.y);
      }
      popStyle();
    }

    // Render dialogue bubbles in world space
    dialogueSystem.renderWorld();

    popMatrix();

    hudView.render();
    messageLog.render();

    drawPhaseBanner();
    drawMissionResult();
    drawCinematicOverlay();

    // Render EVA dialogue box in screen space (on top of everything)
    dialogueSystem.renderUI();

    if (showingHelpOverlay) {
      drawHelpOverlay();
    }
  }

  void drawHelpOverlay() {
    pushStyle();
    // Translucent backing
    fill(5, 10, 20, 230);
    rect(0, 0, width - 340, height); // only cover the gameplay viewport, not the HUD!

    float cx = (width - 340) / 2;
    float cy = height / 2;
    float w = 680;
    float h = 480;

    stroke(0, 255, 255, 120);
    strokeWeight(2);
    fill(14, 22, 40, 250);
    rect(cx - w/2, cy - h/2, w, h, 18);

    // Title
    textAlign(CENTER, TOP);
    fill(255);
    textSize(24);
    text("MANUAL DE ALGORITMOS — MISIÓN " + missionID, cx, cy - h/2 + 25);

    textSize(13);
    fill(160);
    text("Comprende la teoría detrás de la seguridad informática", cx, cy - h/2 + 55);

    // Description text based on active mission
    String concept = "";
    String gamePlay = "";
    String realWorld = "";

    if (missionID == 1) {
      concept = "BFS y DFS (Búsqueda en Grafos)\nBFS (Búsqueda en Anchura) explora una red por niveles, expandiéndose uniformemente en círculos concéntricos desde el origen. DFS (Búsqueda en Profundidad) avanza por un camino hasta el extremo final antes de retroceder.";
      realWorld = "En redes sociales, BFS sirve para analizar el alcance viral instantáneo por contactos directos, mientras que DFS permite rastrear cadenas profundas de reenvíos o hilos específicos.";
      gamePlay = "1. Haz clic izquierdo en Alicia para comenzar a rastrear desde ella.\n2. EVA ejecutará el recorrido para rastrear el origen 'Ghost'.\n3. Bloquea enlaces haciendo Clic Derecho sobre los cables rojos para detener la toxicidad.";
    } else if (missionID == 2) {
      concept = "Camino Corto (Dijkstra)\nEncuentra la ruta de menor costo acumulado entre un nodo inicial y los demás. Funciona seleccionando progresivamente el nodo no visitado con la distancia más corta y relajando sus vecinos.";
      realWorld = "Se usa en GPS y enrutamiento web para encontrar el camino más rápido o con menos tráfico entre dos servidores.";
      gamePlay = "1. Selecciona a un aliado (nodo de apoyo brillante: Bruno, Valeria o Sara).\n2. El algoritmo Dijkstra calculará la ruta con menor stress acumulado hacia Alicia.\n3. La ruta se iluminará en color verde en la pantalla.";
    } else if (missionID == 3) {
      concept = "Árbol de Expansión Mínima (MST - Kruskal)\nConecta todos los nodos de un grafo sin crear ciclos, minimizando la suma total del costo de los enlaces seleccionados.";
      realWorld = "Ideal para diseñar redes eléctricas, fibra óptica o acueductos, conectando ciudades completas con el mínimo gasto en infraestructura.";
      gamePlay = "1. Haz clic en la pantalla para iniciar la reconstrucción.\n2. Kruskal ordenará las conexiones por costo social y las irá evaluando.\n3. Las conexiones que creen bucles (ciclos) serán rechazadas automáticamente.";
    } else if (missionID == 4) {
      concept = "Flujo Máximo (Ford-Fulkerson)\nCalcula el flujo máximo de información o material que puede enviarse a través de una red desde una fuente hasta un sumidero, respetando las capacidades de cada canal.";
      realWorld = "Usado para dimensionar tuberías de petróleo, tráfico en autopistas o ancho de banda de internet.";
      gamePlay = "1. Haz clic en la pantalla para analizar el flujo máximo.\n2. El algoritmo encontrará caminos de aumento desde Ghost (origen) hasta Alicia (destino).\n3. Esto nos dirá el ancho de banda del acoso para poder bloquearlo efectivamente.";
    } else if (missionID == 5) {
      concept = "Fase de Integración Total\nCombina todos los conceptos anteriores. Deberás completar secuencialmente las 4 misiones para sanar la red por completo.";
      realWorld = "En el mundo profesional, la seguridad de una red involucra múltiples fases: rastrear la intrusión, encontrar rutas seguras, reconstruir y limitar el daño.";
      gamePlay = "Sigue las instrucciones del HUD y de EVA. Cada etapa activa un algoritmo distinto. ¡Salva la red y obtén el puntaje más alto!";
    }

    // Draw manual content cards
    float boxY = cy - 140;
    drawManualSection(cx - 300, boxY, 600, 100, "1. ¿CÓMO FUNCIONA EL ALGORITMO?", concept);
    drawManualSection(cx - 300, boxY + 110, 600, 90, "2. APLICACIÓN EN LA VIDA REAL", realWorld);
    drawManualSection(cx - 300, boxY + 210, 600, 110, "3. ¿CÓMO JUGAR ESTE NIVEL?", gamePlay);

    // Close button
    float closeX = cx - 80;
    float closeY = cy + 185;
    float closeW = 160;
    float closeH = 34;
    
    if (mouseX > closeX && mouseX < closeX + closeW && mouseY > closeY && mouseY < closeY + closeH) {
      fill(0, 255, 255);
      rect(closeX, closeY, closeW, closeH, 8);
      fill(0);
    } else {
      fill(20, 32, 54);
      stroke(0, 255, 255, 80);
      strokeWeight(1);
      rect(closeX, closeY, closeW, closeH, 8);
      fill(255);
    }
    textAlign(CENTER, CENTER);
    textSize(13);
    text("ENTENDIDO", cx, closeY + closeH/2 - 1);

    popStyle();
  }

  void drawManualSection(float x, float y, float w, float h, String header, String body) {
    pushStyle();
    fill(20, 30, 48, 150);
    noStroke();
    rect(x, y, w, h, 8);
    
    fill(0, 255, 255);
    textAlign(LEFT, TOP);
    textSize(largeTextMode ? 13 : 11);
    text(header, x + 12, y + 8);

    fill(240);
    textSize(largeTextMode ? 14 : 11);
    textLeading(largeTextMode ? 18 : 14);
    text(body, x + 12, y + 24, w - 24, h - 30);
    popStyle();
  }

  // =========================
  // INPUT
  // =========================

  void mousePressed() {
    if (transitioningPhase) return;
    resetIdleTimer();

    // Check HUD clicks first
    if (hudView.mousePressed(mouseX, mouseY)) {
      return;
    }

    if (showingHelpOverlay) {
      float cx = (width - 340) / 2;
      float cy = height / 2;
      float closeX = cx - 80;
      float closeY = cy + 185;
      float closeW = 160;
      float closeH = 34;
      if (mouseX > closeX && mouseX < closeX + closeW && mouseY > closeY && mouseY < closeY + closeH) {
        showingHelpOverlay = false;
      }
      return;
    }

    float worldMouseX = mouseX - camX;
    float worldMouseY = mouseY - camY;

    controller.mousePressed(worldMouseX, worldMouseY, mouseButton);
  }

  void keyPressed() {
    resetIdleTimer();

    // SPACE key: advance EVA dialogue
    if (key == ' ') {
      if (dialogueSystem.isDialogueActive()) {
        dialogueSystem.skipOrAdvance();
        return;
      }
    }

    controller.keyPressed(key, keyCode);
  }

  void switchTraversalMode() {
    if (traversal == bfsTraversal) {
      traversal = dfsTraversal;
      traversalName = "DFS";
    } else {
      traversal = bfsTraversal;
      traversalName = "BFS";
    }

    if (selectedNode != null) {
      traversal.reset();
      traversal.start(selectedNode);
    }

    dialogueSystem.eva("Algoritmo actual: " + traversalName);
  }

  // =========================
  // CAMERA
  // =========================

  void updateCamera() {
    float speed = 5;
    if (keyPressed) {
      if (key == 'a') camX += speed;
      if (key == 'd') camX -= speed;
      if (key == 'w') camY += speed;
      if (key == 's') camY -= speed;
    }
  }

  // =========================
  // ALERTS
  // =========================

  void triggerAlert(String message) {
    alertMessage = message;
    alertAlpha = 255;
    showAlert = true;
  }

  void updateAlerts() {
    if (!showAlert) return;
    alertAlpha -= 2;
    if (alertAlpha <= 0) {
      showAlert = false;
    }
  }

  // =========================
  // PHASE TRANSITION (Mission 1)
  // =========================

  void startPhaseTransition() {
    transitioningPhase = true;
    transitionTimer = 0;
    cinematicText = "ORIGEN DEL ACOSO IDENTIFICADO";
    dialogueSystem.alert("La cuenta agresora fue encontrada.");
  }

  void updatePhaseTransition() {
    if (!transitioningPhase) return;
    transitionTimer++;
    cinematicFade = min(cinematicFade + 3, 180);

    if (transitionTimer == 120) {
      missionPhase = 2;
      containmentTimer = 0;
      infectionSystem.setActive(true);

      dialogueSystem.eva("¡Bien hecho! Ahora viene la parte difícil.");
      dialogueSystem.eva("Ghost está propagando el acoso por la red. ¡Debemos detenerlo!");
      dialogueSystem.eva("Haz CLIC DERECHO sobre las líneas rojas para bloquear las conexiones dañinas. ¡Protege a los usuarios!");
      triggerAlert("FASE 2 — CONTENCIÓN");

      // Clear node hints since now the action is on edges
      clearGlowHints();
    }

    if (transitionTimer > 240) {
      transitioningPhase = false;
      cinematicFade = 0;
    }
  }

  // =========================
  // OVERLAYS & UI
  // =========================

  void drawCinematicOverlay() {
    if (!transitioningPhase) return;

    noStroke();
    fill(0, cinematicFade);
    rect(0, 0, width, height);

    fill(255);
    textAlign(CENTER, CENTER);
    textSize(42);
    text(cinematicText, width/2, height/2);
  }

  void drawDangerOverlay() {
    int infected = 0;
    for (Node n : nodes) {
      if (n.infected) infected++;
    }

    float intensity = map(infected, 0, nodes.size(), 0, 80);
    noStroke();
    fill(255, 0, 60, intensity + sin(redPulse) * 8);
    rect(0, 0, width, height);
  }

  void drawPhaseBanner() {
    fill(255);
    textAlign(CENTER, TOP);
    textSize(24);

    if (missionID == 5) {
      text("MISIÓN FINAL — FASE DE INTEGRACIÓN (ETAPA " + missionStage + "/4)", width/2, 100);
    } else {
      if (missionID == 1) {
        if (missionPhase == 1) {
          text("FASE 1 — RASTREO DEL ACOSO", width/2, 100);
        } else {
          text("FASE 2 — CONTENCIÓN", width/2, 100);
        }
      } else if (missionID == 2) {
        text("MISIÓN 2 — DETECCIÓN DE LA RUTA SEGURA", width/2, 100);
      } else if (missionID == 3) {
        text("MISIÓN 3 — RECONSTRUIR VÍNCULOS (MST)", width/2, 100);
      } else if (missionID == 4) {
        text("MISIÓN 4 — CONTROL DE CAPACIDAD DE ACOSO", width/2, 100);
      }
    }
  }

  void drawMissionResult() {
    if (!missionComplete && !missionFailed) return;

    fill(0, 220);
    rect(0, 0, width, height);
    textAlign(CENTER, CENTER);

    if (missionComplete) {
      fill(0, 255, 120);
      textSize(56);
      text("RED ESTABILIZADA", width/2, height/2 - 90);

      fill(255);
      textSize(22);
      text("Puntaje Final: " + int(score) + " pts", width/2, height/2 - 35);

      textSize(16);
      fill(200);
      if (missionID == 1) {
        text("La propagación principal fue detenida temporalmente.", width/2, height/2 - 5);
      } else if (missionID == 2) {
        text("Ruta más segura identificada y asegurada hacia la víctima.", width/2, height/2 - 5);
      } else if (missionID == 3) {
        text("La red fue reconstruida con éxito al menor costo social possible.", width/2, height/2 - 5);
      } else if (missionID == 4) {
        text("El flujo tóxico máximo ha sido acotado e interceptado.", width/2, height/2 - 5);
      } else if (missionID == 5) {
        text("¡Felicidades! Has integrado todos los algoritmos y saneado la red por completo.", width/2, height/2 - 5);
      }

      // Initials input
      if (!initialsSaved) {
        fill(0, 255, 255);
        textSize(18);
        text("🏆 ¡NUEVO RÉCORD DE LA FERIA!", width/2, height/2 + 40);
        fill(255);
        text("Ingresa tus iniciales (3 letras): " + playerInitials + ((frameCount / 20) % 2 == 0 ? "_" : ""), width/2, height/2 + 70);
        textSize(13);
        fill(150);
        text("Presiona ENTER para guardar tu puntaje", width/2, height/2 + 100);
      } else {
        fill(0, 255, 120);
        textSize(18);
        text("¡Puntaje guardado con éxito en el Leaderboard!", width/2, height/2 + 45);
      }
    } else {
      fill(255, 60, 80);
      textSize(56);
      text("RED COLAPSADA", width/2, height/2 - 40);

      fill(255);
      textSize(22);
      text("Demasiados usuarios fueron afectados por la toxicidad.", width/2, height/2 + 30);
    }

    fill(180);
    textSize(18);
    text("Presiona R para reiniciar", width/2, height/2 + 150);
    text("Presiona ESC para regresar a Selección de Misión", width/2, height/2 + 180);
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

  Node getNode(String name) {
    for (Node n : nodes) {
      if (n.name.equals(name)) {
        return n;
      }
    }
    return null;
  }

  void delayNarrative(String msg, int delayFrames) {
    Thread t = new Thread(new Runnable() {
      public void run() {
        try {
          Thread.sleep(delayFrames * 16);
        } catch(Exception e) {}
        dialogueSystem.eva(msg);
      }
    });
    t.start();
  }

  // =========================
  // IDLE HINT SYSTEM
  // =========================
  // If the player doesn't interact for 6 seconds, EVA reminds them what to do

  void resetIdleTimer() {
    idleFrameCounter = 0;
    idleHintShown = false;
  }

  void updateIdleHints() {
    if (missionComplete || missionFailed) return;
    if (dialogueSystem.isDialogueActive()) return;

    idleFrameCounter++;
    if (idleFrameCounter >= idleHintDelay && !idleHintShown) {
      idleHintShown = true;
      String hint = getIdleHint();
      if (hint != null && hint.length() > 0) {
        dialogueSystem.eva(hint);
      }
    }
  }

  String getIdleHint() {
    int mid = missionID;
    int stage = (mid == 5) ? missionStage : 0;

    if (mid == 1 || stage == 1) {
      if (missionPhase == 1) {
        return "¿No estás seguro? Haz clic en cualquiera de los nodos que brillan para empezar a rastrear la red. ¡Prueba con Alicia!";
      } else {
        return "¡Rápido! Haz clic derecho en las líneas rojas para bloquear la propagación del acoso antes de que sea tarde.";
      }
    } else if (mid == 2 || stage == 2) {
      return "Busca los nodos que brillan — son Bruno, Valeria y Sara. Haz clic en uno de ellos para encontrar la ruta más segura hacia Alicia.";
    } else if (mid == 3 || stage == 3) {
      return "Haz clic en cualquier lugar de la red para reconstruir las conexiones. El sistema encontrará la mejor forma de reconectar a todos.";
    } else if (mid == 4 || stage == 4) {
      return "Haz clic en cualquier lugar para analizar el flujo de mensajes tóxicos. Descubriremos cuánto daño puede hacer Ghost.";
    }
    return null;
  }
}
