class MissionController {

  MissionScene mission;

  MissionController(MissionScene mission) {
    this.mission = mission;
  }

  void update() {
    updateMissionFlow();
  }

  void updateMissionFlow() {
    // Mission 1 Phase Transition
    if (mission.missionID == 1) {
      if (mission.sourceFound && mission.missionPhase == 1 && !mission.transitioningPhase) {
        mission.startPhaseTransition();
      }
    }
  }

  void mousePressed(float mx, float my, int button) {
    if (mission.missionComplete || mission.missionFailed) return;

    // If EVA dialogue is active, skip/advance instead of doing game actions
    if (mission.dialogueSystem.isDialogueActive()) {
      mission.dialogueSystem.skipOrAdvance();
      return;
    }

    int mid = mission.missionID;
    int stage = (mid == 5) ? mission.missionStage : 0;

    // --- MISSION 1 OR MISSION 5 STAGE 1 ---
    if (mid == 1 || stage == 1) {
      if (button == LEFT) {
        for (Node n : mission.nodes) {
          if (dist(mx, my, n.x, n.y) < 30) {
            mission.selectedNode = n;
            mission.dialogueSystem.say(n.x, n.y - 60, "Analizando " + n.name);
            mission.messageLog.add("EVA", n.name, "Analizando " + n.name, 2);

            mission.traversal.reset();
            mission.traversal.start(n);

            // Disable glow hints after first click
            mission.clearGlowHints();

            if (mid == 1 && n.name.equals("Ghost") && !mission.sourceFound) {
              mission.sourceFound = true;
              mission.dialogueSystem.eva("¡Excelente! Encontraste a Ghost, la cuenta agresora.");
              mission.dialogueSystem.alert("¡Origen del acoso detectado!");
            } else if (!n.name.equals("Ghost")) {
              mission.dialogueSystem.eva("Rastreando desde " + n.name + "... Sigue explorando para encontrar al agresor.");
            }
            return;
          }
        }
        // Clicked on empty space
        mission.dialogueSystem.eva("Haz clic directamente sobre un usuario (los círculos brillantes) para rastrear la red.");
      }

      if (button == RIGHT) {
        for (Edge e : mission.edges) {
          if (e.isMouseNear(mx, my)) {
            e.blocked = !e.blocked;
            String msg = e.blocked ? "¡Conexión bloqueada! El acoso no puede pasar por aquí." : "Conexión restaurada.";
            mission.dialogueSystem.say((e.a.x + e.b.x) / 2, (e.a.y + e.b.y) / 2 - 20, e.blocked ? "Bloqueada" : "Restaurada");
            mission.dialogueSystem.eva(msg);
            mission.messageLog.add("EVA", "RED", e.blocked ? "Ruta bloqueada" : "Ruta restaurada", e.blocked ? 0 : 1);
            return;
          }
        }
      }
    }

    // --- MISSION 2 OR MISSION 5 STAGE 2 ---
    else if (mid == 2 || stage == 2) {
      if (button == LEFT) {
        for (Node n : mission.nodes) {
          if (dist(mx, my, n.x, n.y) < 30) {
            if (n.supportive || n.name.equals("Bruno") || n.name.equals("Sara") || n.name.equals("Valeria")) {
              mission.dialogueSystem.say(n.x, n.y - 60, "Iniciando Dijkstra...");

              // Disable glow hints
              mission.clearGlowHints();

              Node alicia = mission.getNode("Alicia");
              if (alicia != null) {
                mission.dijkstraPath = null;
                mission.dijkstraPathfinder.startStepByStep(n, alicia);
                mission.dialogueSystem.eva("¡Dijkstra iniciado! El algoritmo relajará conexiones para hallar el camino óptimo.");
                mission.messageLog.add("DIJKSTRA", "Alicia", "Búsqueda de ruta segura desde " + n.name, 1);
              }
            } else {
              mission.score = max(0, mission.score - 200); // Penalty
              mission.dialogueSystem.eva(n.name + " no es un aliado. Busca los nodos que brillan (penalización -200 pts).");
            }
            return;
          }
        }
        mission.dialogueSystem.eva("Haz clic en uno de los nodos que brillan (Bruno, Valeria o Sara) para trazar la ruta segura.");
      }
    }

    // --- MISSION 3 OR MISSION 5 STAGE 3 ---
    else if (mid == 3 || stage == 3) {
      if (button == LEFT) {
        mission.clearGlowHints();
        mission.dialogueSystem.say(mx, my - 20, "Reconstruyendo...");
        mission.mstCost = 0;
        mission.kruskalMST.startStepByStep();
        mission.dialogueSystem.eva("¡Kruskal iniciado! Analizando aristas en orden ascendente de costo.");
        mission.messageLog.add("KRUSKAL", "RED", "Iniciando reconstrucción de la red", 1);
      }
    }

    // --- MISSION 4 OR MISSION 5 STAGE 4 ---
    else if (mid == 4 || stage == 4) {
      if (button == LEFT) {
        Node clickedNode = null;
        for (Node n : mission.nodes) {
          if (dist(mx, my, n.x, n.y) < 30) {
            clickedNode = n;
            break;
          }
        }

        if (clickedNode != null) {
          if (mission.maxFlowCalculator.running && mission.maxFlowCalculator.manualMode) {
            mission.maxFlowCalculator.handleNodeClick(clickedNode);
            return;
          }

          mission.clearGlowHints();
          if (mission.selectedStartNode == null) {
            mission.selectedStartNode = clickedNode;
            mission.dialogueSystem.say(clickedNode.x, clickedNode.y - 60, "Fuente");
            mission.dialogueSystem.eva("Fuente establecida: " + clickedNode.name + ". Ahora selecciona el destino (Sumidero) haciendo clic en otro nodo.");
            mission.messageLog.add("FF_MAXFLOW", clickedNode.name, "Fuente establecida", 2);
          } else if (mission.selectedStartNode == clickedNode) {
            mission.selectedStartNode = null;
            mission.dialogueSystem.eva("Fuente deseleccionada. Haz clic en un nodo para establecer la Fuente.");
          } else if (mission.selectedEndNode == null) {
            mission.selectedEndNode = clickedNode;
            mission.dialogueSystem.say(clickedNode.x, clickedNode.y - 60, "Destino");
            mission.dialogueSystem.eva("Destino establecido: " + clickedNode.name + ". Iniciando análisis de flujo máximo...");
            mission.messageLog.add("FF_MAXFLOW", clickedNode.name, "Destino establecido", 2);
            
            mission.calculatedMaxFlow = 0;
            mission.maxFlowCalculator.startStepByStep(mission.selectedStartNode, mission.selectedEndNode);
          } else if (mission.selectedEndNode == clickedNode) {
            mission.selectedEndNode = null;
            mission.dialogueSystem.eva("Destino deseleccionado. Haz clic en un nodo para establecer el Destino.");
          } else {
            // Both are set, if they click a third one, reset and make it the start
            mission.selectedStartNode = clickedNode;
            mission.selectedEndNode = null;
            mission.dialogueSystem.say(clickedNode.x, clickedNode.y - 60, "Fuente");
            mission.dialogueSystem.eva("Nueva Fuente establecida: " + clickedNode.name + ". Selecciona el destino.");
            mission.messageLog.add("FF_MAXFLOW", clickedNode.name, "Fuente establecida", 2);
          }
        } else {
          mission.dialogueSystem.eva("Haz clic sobre un nodo para definir Fuente o Destino para el análisis de flujo.");
        }
      }
    }
  }

  void keyPressed(char k, int codeValue) {
    // Check if initials input is active
    if (mission.missionComplete && !mission.initialsSaved) {
      if (k == ENTER || k == RETURN) {
        if (mission.playerInitials.length() > 0) {
          mission.leaderboardManager.addEntry(mission.playerInitials, mission.missionID, mission.score);
          mission.initialsSaved = true;
        }
      } else if (k == BACKSPACE) {
        if (mission.playerInitials.length() > 0) {
          mission.playerInitials = mission.playerInitials.substring(0, mission.playerInitials.length() - 1);
        }
      } else if (Character.isLetter(k) && mission.playerInitials.length() < 3) {
        mission.playerInitials += Character.toUpperCase(k);
      }
      return; // consume input
    }

    if (k == 'r' || k == 'R') {
      game.sceneManager.changeScene(new MissionScene(mission.missionID));
    }

    if (k == ESC) {
      key = 0;
      game.sceneManager.changeScene(new MissionSelectScene());
    }

    if (k == 't' || k == 'T') {
      if (mission.missionID == 1 || (mission.missionID == 5 && mission.missionStage == 1)) {
        mission.switchTraversalMode();
        mission.dialogueSystem.eva("Cambiaste a modo " + mission.traversalName + ". ¡Prueba cómo explora diferente la red!");
      }
    }

    if (codeValue == UP) {
      mission.messageLog.scrollUp();
    }

    if (codeValue == DOWN) {
      mission.messageLog.scrollDown();
    }
  }

  String getPathString(ArrayList<Node> path) {
    String s = "";
    for (int i = 0; i < path.size(); i++) {
      s += path.get(i).name;
      if (i < path.size() - 1) s += " → ";
    }
    return s;
  }
}
