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
    algorithmAutoPlay = false;
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
    dijkstraPathfinder.manualMode = true;
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
      // Highlight Ana (starting node) and all others
      for (Node n : nodes) n.glowHint = true;
    } else if (mid == 2 || stage == 2) {
      // Highlight support allies: Bruno, Valeria, Sara
      for (Node n : nodes) {
        if (n.supportive || n.name.equals("Bruno") || n.name.equals("Sara") || n.name.equals("Valeria")) {
          n.glowHint = true;
        }
      }
    } else if (mid == 3 || stage == 3) {
      for (Node n : nodes) n.glowHint = true;
    } else if (mid == 4 || stage == 4) {
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
      // ── MISIÓN 1: Rastros del Hacker (BFS / DFS) ─────────────────────
      dialogueSystem.eva("¡Alerta roja! Soy EVA, IA de seguridad de NexaCorp.");
      dialogueSystem.eva("El hacker 'GHOST' ha penetrado nuestra red interna y acosa a los empleados con mensajes cifrados.");
      dialogueSystem.eva("Tu misión: rastrear la red para descubrir por dónde entró GHOST.");
      dialogueSystem.eva("Paso 1 — Haz clic izquierdo en ANA (Directora IT), la primera empleada afectada, para iniciar el rastreo.");
      dialogueSystem.eva("Paso 2 — Observa la Cola/Pila en el panel derecho y haz clic en el siguiente nodo de la estructura para ir revelando la red.");
      dialogueSystem.eva("Usa T para cambiar entre BFS (por niveles) y DFS (en profundidad). ¡Encuentra a GHOST!");
      triggerAlert("OPERACIÓN: RASTREO DE HACKER");
    } else if (missionID == 2) {
      // ── MISIÓN 2: Canal Seguro (Dijkstra) ────────────────────────────
      dialogueSystem.eva("¡Evidencia recolectada! Ya sabemos quién es GHOST.");
      dialogueSystem.eva("Pero Ana sigue expuesta. Necesitamos enviarle instrucciones de seguridad por el canal de menor riesgo de interceptación.");
      dialogueSystem.eva("Tu misión: usar Dijkstra para encontrar la ruta con menor peso acumulado hasta Ana.");
      dialogueSystem.eva("Paso 1 — Haz clic izquierdo en uno de los aliados que brillan: Bruno, Valeria o Sara.");
      dialogueSystem.eva("Paso 2 — Cuando Dijkstra te indique, haz clic en el nodo no visitado con la MENOR distancia tentativa.");
      dialogueSystem.eva("Paso 3 — Luego haz clic en cada vecino del nodo actual para relajar sus distancias. ¡La ruta verde es el canal seguro!");
      triggerAlert("OPERACIÓN: CANAL SEGURO");
    } else if (missionID == 3) {
      // ── MISIÓN 3: Reconstrucción de Red (Kruskal MST) ────────────────
      dialogueSystem.eva("GHOST destruyó varios enlaces de comunicación al infiltrarse en NexaCorp.");
      dialogueSystem.eva("La oficina está desconectada. ¡Debemos reconectar todos los equipos con el menor costo de infraestructura!");
      dialogueSystem.eva("Tu misión: usar Kruskal para construir el Árbol de Expansión Mínima de la red.");
      dialogueSystem.eva("Paso 1 — Haz clic en cualquier parte del grafo para que Kruskal proponga la primera arista candidata.");
      dialogueSystem.eva("Paso 2 — Por cada arista propuesta (en amarillo), decide: ¿ACEPTAR o RECHAZAR?");
      dialogueSystem.eva("Regla clave: ACEPTA si conecta equipos distintos. RECHAZA si ya están conectados (crearía un ciclo).");
      triggerAlert("OPERACIÓN: RECONSTRUCCIÓN");
    } else if (missionID == 4) {
      // ── MISIÓN 4: Interceptar el Ataque (Ford-Fulkerson) ─────────────
      dialogueSystem.eva("GHOST está exfiltrando datos confidenciales de NexaCorp por la red.");
      dialogueSystem.eva("Necesitamos calcular cuántos datos puede robar para bloquear exactamente los canales correctos.");
      dialogueSystem.eva("Tu misión: usar Ford-Fulkerson para hallar el flujo máximo de datos de GHOST.");
      dialogueSystem.eva("Paso 1 — Haz clic izquierdo en el nodo GHOST para establecerlo como FUENTE del ataque.");
      dialogueSystem.eva("Paso 2 — Haz clic izquierdo en ANA para establecerla como DESTINO (donde llegan los datos robados).");
      dialogueSystem.eva("Paso 3 — Traza caminos de GHOST a ANA haciendo clic en nodos vecinos (solo si la capacidad residual > 0).");
      dialogueSystem.eva("Cuando no haya más caminos, aplica el Corte Mínimo: haz CLIC DERECHO sobre las aristas saturadas (rojo intenso) para bloquearlas.");
      triggerAlert("OPERACIÓN: INTERCEPTAR EXFILTRACIÓN");
    } else if (missionID == 5) {
      // ── MISIÓN 5: Caso Completo (Integración) ────────────────────────
      dialogueSystem.eva("¡Operación Final — Neutralización de GHOST!");
      // Read evidence collected from previous missions
      if (game != null) {
        String src = (game.evidence_m1_source.length() > 0) ? game.evidence_m1_source : "ruta desconocida";
        String cost2 = (game.evidence_m2_routeCost > 0) ? str((int)game.evidence_m2_routeCost) : "N/A";
        String cost3 = (game.evidence_m3_mstCost > 0)   ? str((int)game.evidence_m3_mstCost)   : "N/A";
        String flow4 = (game.evidence_m4_maxFlow > 0)   ? str((int)game.evidence_m4_maxFlow)   : "N/A";
        dialogueSystem.eva("[EVIDENCIA 1 - LOG DE TRÁFICO] GHOST entró por: " + src);
        dialogueSystem.eva("[EVIDENCIA 2 - CANAL SEGURO] Costo de ruta segura hacia Ana: " + cost2 + " unidades de riesgo.");
        dialogueSystem.eva("[EVIDENCIA 3 - MAPA DE RED] Costo mínimo de reconstrucción: " + cost3 + " unidades.");
        dialogueSystem.eva("[EVIDENCIA 4 - VOLUMEN DEL ATAQUE] GHOST puede exfiltrar hasta " + flow4 + " unidades de datos.");
      }
      dialogueSystem.eva("Ahora ejecuta los 4 pasos en orden para neutralizarlo de una vez por todas.");
      dialogueSystem.eva("Etapa 1 — Rastrea a GHOST con BFS o DFS. Haz clic en ANA para iniciar.");
      triggerAlert("OPERACIÓN FINAL: GHOST NEUTRALIZADO");
    }
  }

  // =========================
  // NETWORK
  // =========================

  void createNetwork() {
    // ── Nodos: empleados de NexaCorp + el hacker externo ─────────────────
    Node a = new Node(300, 250, "Ana",    "dir_it");       // Directora IT — primera afectada
    Node b = new Node(550, 200, "Bruno",  "analista");     // Analista Senior — aliado
    Node c = new Node(700, 400, "Carla",  "contab");       // Contabilidad — observadora con logs
    Node d = new Node(450, 520, "Diego",  "pasante");      // Pasante — credenciales débiles
    Node e = new Node(850, 250, "GHOST",  "hacker");       // Hacker externo — nodo atacante
    Node f = new Node(1000, 420, "Valeria", "rrhh");       // RRHH — aliada con datos de personal
    Node g = new Node(1200, 300, "Andres", "servidor");    // Servidor Gateway — nodo de tráfico
    Node h = new Node(980, 580, "Sara",   "legal");        // Legal — puede escalar el caso

    // ── Estados y valores ────────────────────────────────────────────────
    e.infected   = true;
    e.toxicity   = 100;
    d.vulnerable = true;
    f.supportive = true;
    h.supportive = true;
    b.support    = 90;
    f.support    = 95;
    h.support    = 95;
    a.stress     = 20;
    d.stress     = 60;
    c.stress     = 35;

    nodes.add(a);
    nodes.add(b);
    nodes.add(c);
    nodes.add(d);
    nodes.add(e);
    nodes.add(f);
    nodes.add(g);
    nodes.add(h);

    // ── Conexiones: peso (M2 riesgo), costo (M3 infra), capacidad (M4 datos) ──
    // Ana — Bruno
    Edge e_ab = connect(a, b);
    e_ab.weight = 2; e_ab.cost = 10; e_ab.capacity = 15;

    // Bruno — Carla
    Edge e_bc = connect(b, c);
    e_bc.weight = 3; e_bc.cost = 18; e_bc.capacity = 10;

    // Ana — Diego
    Edge e_ad = connect(a, d);
    e_ad.weight = 8; e_ad.cost = 35; e_ad.capacity = 5;

    // Carla — GHOST
    Edge e_ce = connect(c, e);
    e_ce.weight = 9; e_ce.cost = 40; e_ce.capacity = 4;

    // Bruno — GHOST
    Edge e_be = connect(b, e);
    e_be.weight = 7; e_be.cost = 45; e_be.capacity = 12;

    // GHOST — Valeria
    Edge e_ef = connect(e, f);
    e_ef.weight = 5; e_ef.cost = 25; e_ef.capacity = 10;

    // Valeria — Andres
    Edge e_fg = connect(f, g);
    e_fg.weight = 4; e_fg.cost = 15; e_fg.capacity = 8;

    // Diego — Sara
    Edge e_dh = connect(d, h);
    e_dh.weight = 2; e_dh.cost = 12; e_dh.capacity = 10;

    // Sara — Andres
    Edge e_hg = connect(h, g);
    e_hg.weight = 6; e_hg.cost = 22; e_hg.capacity = 6;

    // Carla — Sara
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
        boolean justFinished = false;
        if (algorithmAutoPlay) {
          if (frameCount % 35 == 0) {
            maxFlowCalculator.step();
            if (maxFlowCalculator.finished) {
              calculatedMaxFlow = maxFlowCalculator.maxFlow;
              justFinished = true;
            }
          }
        } else if (algorithmStepRequested) {
          algorithmStepRequested = false;
          maxFlowCalculator.step();
          if (maxFlowCalculator.finished) {
            calculatedMaxFlow = maxFlowCalculator.maxFlow;
            justFinished = true;
          }
        }

        if (justFinished) {
          if (missionID == 5 && missionStage == 4) {
            dialogueSystem.eva("\u00a1Flujo m\u00e1ximo calculado! GHOST puede exfiltrar " + (int)calculatedMaxFlow + " unidades de datos.");
            dialogueSystem.eva("Los enlaces saturados forman el 'Corte M\u00ednimo' — los cuellos de botella del ataque.");
            dialogueSystem.eva("\u00a1Haz CLIC DERECHO sobre cada enlace saturado para bloquearlo y neutralizar a GHOST!");
          }
        }
      }
    }

    // ==========================================
    // MISSION SPECIFIC COMPLETION AND FLOW LOGIC
    // ==========================================

    // --- MISSION 1: Rastreo del Hacker (solo descubrir GHOST) ---
    if (missionID == 1) {
      if (!sourceFound) {
        Node ghost = getNode("GHOST");
        if (ghost != null && ghost.visited) {
          sourceFound = true;
          missionComplete = true;
          // Guardar evidencia M1: qué nodo reveló a GHOST directamente
          if (game != null) {
            // Buscar el predecesor de GHOST en el recorrido
            String entry = "acceso directo";
            if (traversalName.equals("BFS") && bfsTraversal.visitedNodes != null) {
              int idx = bfsTraversal.visitedNodes.indexOf(ghost);
              if (idx > 0) entry = bfsTraversal.visitedNodes.get(idx - 1).name;
            } else if (traversalName.equals("DFS") && dfsTraversal.visitedNodes != null) {
              int idx = dfsTraversal.visitedNodes.indexOf(ghost);
              if (idx > 0) entry = dfsTraversal.visitedNodes.get(idx - 1).name;
            }
            game.evidence_m1_source = entry + " → GHOST";
          }
          dialogueSystem.eva("¡INTRUSIÓN LOCALIZADA! GHOST fue rastreado en la red de NexaCorp.");
          dialogueSystem.eva("Evidencia 1 guardada: Log de tráfico de entrada del hacker.");
          dialogueSystem.eva("¡Misión 1 completada! Regresa al menú para continuar con la Misión 2.");
        }
      }
    }

    // --- MISSION 2: Canal Seguro (Dijkstra) ---
    else if (missionID == 2) {
      if (dijkstraPath != null && !missionComplete) {
        missionComplete = true;
        // Guardar evidencia M2: costo total de la ruta más segura
        if (game != null && dijkstraPath.size() > 0) {
          Node dest = dijkstraPath.get(dijkstraPath.size() - 1);
          if (dest != null && dest.dijkstraDist < Float.MAX_VALUE) {
            game.evidence_m2_routeCost = dest.dijkstraDist;
          }
        }
        dialogueSystem.eva("¡Canal seguro establecido hacia Ana!");
        dialogueSystem.eva("Evidencia 2 guardada: Ruta de comunicación protegida.");
      }
    }

    // --- MISSION 3: Reconstrucción de Red (Kruskal MST) ---
    else if (missionID == 3) {
      if (mstCost > 0 && !missionComplete) {
        missionComplete = true;
        // Guardar evidencia M3: costo total del MST
        if (game != null) {
          game.evidence_m3_mstCost = mstCost;
        }
        dialogueSystem.eva("¡Red de NexaCorp reconstruida con costo mínimo!");
        dialogueSystem.eva("Evidencia 3 guardada: Mapa de infraestructura segura.");
      }
    }

    // --- MISSION 4: Interceptar Exfiltración (Ford-Fulkerson) ---
    else if (missionID == 4) {
      if (calculatedMaxFlow > 0 && !missionComplete) {
        // Check if all saturated edges are blocked (Min-Cut applied)
        boolean allSaturatedBlocked = true;
        int satCount = 0;
        for (Edge e : edges) {
          if (e.capacity > 0 && abs(e.flow - e.capacity) < 0.01) {
            satCount++;
            if (!e.blocked) allSaturatedBlocked = false;
          }
        }
        if (satCount == 0 || allSaturatedBlocked) {
          missionComplete = true;
          // Guardar evidencia M4: flujo máximo calculado
          if (game != null) {
            game.evidence_m4_maxFlow = calculatedMaxFlow;
          }
          dialogueSystem.eva("¡Corte Mínimo aplicado! Los canales de exfiltración de GHOST están bloqueados.");
          dialogueSystem.eva("Evidencia 4 guardada: Volumen máximo del ataque interceptado.");
        }
      }
    }

    // --- MISSION 5: Integración Completa (Secuencial) ---
    else if (missionID == 5) {
      if (missionStage == 1) {
        if (!sourceFound) {
          Node ghost = getNode("GHOST");
          if (ghost != null && ghost.visited) {
            sourceFound = true;
            dialogueSystem.eva("✅ Etapa 1 completada: GHOST rastreado en la red de NexaCorp.");
            delayNarrative("Etapa 2 — Canal Seguro: Haz clic en Bruno, Valeria o Sara para enviar asistencia a Ana con Dijkstra.", 120);
            missionStage = 2;
            setupGlowHints();
          }
        }
      } else if (missionStage == 2) {
        if (dijkstraPath != null) {
          dialogueSystem.eva("✅ Etapa 2 completada: Canal seguro hacia Ana trazado.");
          dialogueSystem.eva("Etapa 3 — Reconstrucción: Haz clic en cualquier parte del grafo para iniciar Kruskal.");
          missionStage = 3;
          setupGlowHints();
        }
      } else if (missionStage == 3) {
        if (mstCost > 0) {
          dialogueSystem.eva("✅ Etapa 3 completada: Red reconstruida con costo " + (int)mstCost + " unidades.");
          dialogueSystem.eva("Etapa 4 — Interceptar Exfiltración: Haz clic en GHOST (fuente) y luego en ANA (destino) para analizar el flujo.");
          missionStage = 4;
          setupGlowHints();
        }
      } else if (missionStage == 4) {
        if (calculatedMaxFlow > 0 && !missionComplete) {
          boolean allSaturatedBlocked = true;
          int satCount = 0;
          for (Edge e : edges) {
            if (e.capacity > 0 && abs(e.flow - e.capacity) < 0.01) {
              satCount++;
              if (!e.blocked) allSaturatedBlocked = false;
            }
          }
          if (satCount > 0 && allSaturatedBlocked) {
            missionComplete = true;
            dialogueSystem.eva("✅ Etapa 4 completada: Exfiltración de GHOST bloqueada.");
            dialogueSystem.eva("¡MISIÓN FINAL COMPLETADA! NexaCorp ha sido asegurada. GHOST neutralizado.");
          }
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
      concept = "BFS y DFS (Búsqueda en Grafos)\nBFS (Búsqueda en Anchura) explora la red por niveles desde el nodo inicial. DFS (Búsqueda en Profundidad) sigue una ruta hasta el fondo antes de retroceder.";
      realWorld = "Los analistas de ciberseguridad usan BFS para mapear la propagación de un malware por niveles, y DFS para rastrear cadenas de comunicación profundas en una red corporativa.";
      gamePlay = "1. Haz clic izquierdo en ANA (Directora IT) para iniciar el rastreo.\n2. Sigue el orden de la Cola (BFS) o Pila (DFS) — haz clic en el siguiente nodo de la estructura.\n3. Cuando descubras a GHOST, la misión se completará.";
    } else if (missionID == 2) {
      concept = "Camino Mínimo (Dijkstra)\nEncuentra la ruta de menor costo acumulado entre dos nodos de la red. Funciona eligiendo progresivamente el nodo no visitado con la distancia tentativa más baja y relajando a sus vecinos.";
      realWorld = "Se usa en ciberseguridad para enrutar tráfico de forma segura, y en redes corporativas para seleccionar el canal de menor riesgo de intercepción.";
      gamePlay = "1. Haz clic en Bruno, Valeria o Sara (aliados de Ana).\n2. En Fase de Selección: elige el nodo no visitado con menor distancia tentativa.\n3. En Fase de Relajación: haz clic en cada vecino del nodo actual para actualizar sus distancias.";
    } else if (missionID == 3) {
      concept = "Árbol de Expansión Mínima (Kruskal MST)\nConecta todos los nodos sin crear ciclos, usando el menor costo total de infraestructura. Evalua aristas en orden ascendente de costo.";
      realWorld = "Ideal para diseñar redes de fibra óptica corporativas, garantizando conectividad completa con el mínimo gasto en cables e infraestructura.";
      gamePlay = "1. Haz clic en el grafo para iniciar Kruskal.\n2. Por cada arista propuesta (amarilla), decide: ACEPTAR si conecta equipos distintos, RECHAZAR si ya están conectados (ciclo).\n3. Al finalizar, todos los equipos de NexaCorp estarán reconectados.";
    } else if (missionID == 4) {
      concept = "Flujo Máximo (Ford-Fulkerson)\nCalcula la cantidad máxima de datos que puede enviarse de una fuente a un destino, respetando las capacidades de cada canal. El Corte Mínimo son los cuellos de botella que limitan el flujo total.";
      realWorld = "Se usa para dimensionar el ancho de banda de una red empresarial y para identificar los enlaces críticos que, si se cortan, aislarían la fuente del destino.";
      gamePlay = "1. Haz clic en GHOST (fuente) y luego en ANA (destino).\n2. Traza caminos de aumento haciendo clic nodo a nodo.\n3. Cuando no haya más caminos, usa CLIC DERECHO en las aristas saturadas para aplicar el Corte Mínimo.";
    } else if (missionID == 5) {
      concept = "Integración de Ciberseguridad\nCombina rastreo (BFS/DFS), canal seguro (Dijkstra), reconstrucción de red (Kruskal) y control de flujo (Ford-Fulkerson) en una operación completa de respuesta a incidentes.";
      realWorld = "Un equipo SOC (Security Operations Center) sigue exactamente estos pasos para responder a una intrusión real: rastrear, proteger, reconstruir y cortar el acceso al atacante.";
      gamePlay = "Sigue las 4 etapas en orden guiado por EVA. Cada etapa activa un algoritmo distinto. Usa las evidencias de las misiones anteriores para reforzar el caso contra GHOST.";
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

  // Fase 2 de Misión 1 (infección/contención) eliminada por diseño pedagógico.
  // La Misión 1 termina al descubrir a GHOST — sin segunda fase.
  // startPhaseTransition() ya no tiene uso; se mantiene para compatibilidad
  // con MissionController que puede llamarla, pero no activa la infección.
  void startPhaseTransition() {
    // No-op: Misión 1 ya no tiene Fase 2
  }

  void updatePhaseTransition() {
    // No-op: eliminada la mecánica de propagación en Misión 1
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
      text("OPERACIÓN FINAL — NEXACORP BAJO ATAQUE (ETAPA " + missionStage + "/4)", width/2, 100);
    } else if (missionID == 1) {
      text("MISIÓN 1 — RASTREO DEL HACKER (BFS / DFS)", width/2, 100);
    } else if (missionID == 2) {
      text("MISIÓN 2 — CANAL SEGURO (DIJKSTRA)", width/2, 100);
    } else if (missionID == 3) {
      text("MISIÓN 3 — RECONSTRUCCIÓN DE RED (KRUSKAL)", width/2, 100);
    } else if (missionID == 4) {
      text("MISIÓN 4 — INTERCEPTAR EXFILTRACIÓN (FORD-FULKERSON)", width/2, 100);
    }
  }

  void drawMissionResult() {
    if (!missionComplete && !missionFailed) return;

    fill(0, 220);
    rect(0, 0, width, height);
    textAlign(CENTER, CENTER);

    if (missionComplete) {
      fill(0, 255, 120);
      textSize(48);

      String headline = "MISIÓN COMPLETADA";
      String subtitle = "";
      if (missionID == 1) {
        headline = "HACKER RASTREADO";
        subtitle = "Evidencia 1 recolectada: Log de tráfico de GHOST guardado.";
      } else if (missionID == 2) {
        headline = "CANAL SEGURO ESTABLECIDO";
        subtitle = "Evidencia 2 recolectada: Ruta de menor riesgo hacia Ana asegurada.";
      } else if (missionID == 3) {
        headline = "RED RECONSTRUIDA";
        subtitle = "Evidencia 3 recolectada: Infraestructura mínima de NexaCorp restaurada.";
      } else if (missionID == 4) {
        headline = "EXFILTRACIÓN BLOQUEADA";
        subtitle = "Evidencia 4 recolectada: Canales de robo de datos de GHOST cerrados.";
      } else if (missionID == 5) {
        headline = "¡GHOST NEUTRALIZADO!";
        subtitle = "¡Operación completa! NexaCorp ha sido asegurada. ¡Eres el héroe de la empresa!";
      }

      text(headline, width/2, height/2 - 90);

      fill(255);
      textSize(22);
      text("Puntaje Final: " + int(score) + " pts", width/2, height/2 - 40);

      textSize(16);
      fill(200);
      text(subtitle, width/2, height/2 - 5);

      // Initials input
      if (!initialsSaved) {
        fill(0, 255, 255);
        textSize(18);
        text("🏆 ¡NUEVO RÉCORD — FERIA DE CIENCIAS NEXACORP!", width/2, height/2 + 40);
        fill(255);
        text("Ingresa tus iniciales (3 letras): " + playerInitials + ((frameCount / 20) % 2 == 0 ? "_" : ""), width/2, height/2 + 70);
        textSize(13);
        fill(150);
        text("Presiona ENTER para guardar tu puntaje", width/2, height/2 + 100);
      } else {
        fill(0, 255, 120);
        textSize(18);
        text("¡Puntaje guardado con éxito en el ranking!", width/2, height/2 + 45);
      }
    } else {
      fill(255, 60, 80);
      textSize(48);
      text("SISTEMA COMPROMETIDO", width/2, height/2 - 40);
      fill(255);
      textSize(20);
      text("GHOST logró comprometer la red de NexaCorp.", width/2, height/2 + 20);
      fill(180);
      textSize(16);
      text("Reinicia para volver a intentarlo.", width/2, height/2 + 50);
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
      return "Pista: Haz clic izquierdo en ANA (Directora IT) para iniciar el rastreo. Luego sigue el orden de la Cola/Pila en el panel derecho para revelar a GHOST.";
    } else if (mid == 2 || stage == 2) {
      if (!dijkstraPathfinder.running) {
        return "Pista: Haz clic en uno de los aliados que brillan — Bruno, Valeria o Sara — para trazar el canal seguro hacia Ana con Dijkstra.";
      } else if (dijkstraPathfinder.waitingForNodeSelection) {
        return "Pista: Selecciona el nodo no visitado con la MENOR distancia tentativa en la tabla Dijkstra del panel derecho.";
      } else {
        return "Pista: Haz clic en cada vecino del nodo actual (destacado) para relajar sus distancias y avanzar el algoritmo.";
      }
    } else if (mid == 3 || stage == 3) {
      if (!kruskalMST.running) {
        return "Pista: Haz clic en cualquier parte del grafo para iniciar Kruskal y comenzar a reconstruir la red de NexaCorp.";
      } else if (kruskalMST.waitingForDecision) {
        return "Pista: Mira la arista amarilla propuesta. Si conecta equipos distintos → ACEPTAR. Si crearía un bucle (ya conectados) → RECHAZAR.";
      }
    } else if (mid == 4 || stage == 4) {
      if (selectedStartNode == null) {
        return "Pista: Haz clic en el nodo GHOST para establecerlo como FUENTE del ataque de exfiltración.";
      } else if (selectedEndNode == null) {
        return "Pista: Ahora haz clic en ANA para establecerla como DESTINO de los datos robados.";
      } else if (calculatedMaxFlow > 0) {
        return "Pista: Los canales saturados (rojo intenso) forman el Corte Mínimo. Haz CLIC DERECHO sobre ellos para bloquear a GHOST.";
      } else {
        return "Pista: Traza un camino de GHOST a ANA haciendo clic nodo por nodo (solo por canales con capacidad > 0).";
      }
    }
    return null;
  }
}
