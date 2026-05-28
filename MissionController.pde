class MissionController {

  MissionScene mission;

  MissionController(MissionScene mission) {
    this.mission = mission;
  }

  void update() {
    updateMissionFlow();
  }

  void updateMissionFlow() {
    // Misión 1 termina al descubrir a GHOST — no hay Fase 2 de contención.
    // La lógica de finalización está completamente en MissionScene.update()
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
        Node clickedNode = null;
        for (Node n : mission.nodes) {
          if (dist(mx, my, n.x, n.y) < 30) {
            clickedNode = n;
            break;
          }
        }

        if (clickedNode != null) {
          if (!mission.traversal.isRunning()) {
            if (clickedNode.name.equals("Ana")) {
              mission.selectedNode = clickedNode;
              mission.traversal.reset();
              mission.traversal.start(clickedNode);
              mission.clearGlowHints();
              mission.dialogueSystem.eva("Rastreo iniciado desde Ana. Sigue el orden del algoritmo (mira la Cola/Pila a la derecha).");
              soundManager.playSelect();
            } else {
              mission.score = max(0, mission.score - 100);
              mission.loseShield();
              mission.dialogueSystem.eva("Debes iniciar la investigación desde ANA, la Directora IT afectada (-100 pts).");
            }
          } else {
            Node expectedNode = null;
            if (mission.traversalName.equals("BFS")) {
              if (mission.bfsTraversal.queue.size() > 0) {
                expectedNode = mission.bfsTraversal.queue.get(0);
              }
            } else {
              if (mission.dfsTraversal.stack.size() > 0) {
                expectedNode = mission.dfsTraversal.stack.get(mission.dfsTraversal.stack.size() - 1);
              }
            }

            if (expectedNode != null) {
              if (clickedNode == expectedNode) {
                soundManager.playSuccess();
                mission.dialogueSystem.say(clickedNode.x, clickedNode.y - 60, "Revelando: " + clickedNode.name);
                mission.messageLog.add("EVA", clickedNode.name, "Escaneando nodo " + clickedNode.name, 2);

                if (mission.traversalName.equals("BFS")) {
                  mission.bfsTraversal.stepRequested = true;
                  mission.bfsTraversal.update();
                } else {
                  mission.dfsTraversal.stepRequested = true;
                  mission.dfsTraversal.update();
                }

                if (clickedNode.name.equals("GHOST")) {
                  soundManager.playSuccess();
                  mission.dialogueSystem.eva("\u00a1ALERTA! Has encontrado a 'GHOST', el hacker que infiltr\u00f3 NexaCorp.");
                  mission.messageLog.add("ALERTA", "GHOST", "Intruso localizado", 0);
                  if (mid == 1) {
                    mission.sourceFound = true;
                  }
                } else {
                  mission.dialogueSystem.eva("Nodo " + clickedNode.name + " escaneado. Sigue con el siguiente de la estructura " + mission.traversalName + ".");
                }
              } else {
                mission.score = max(0, mission.score - 150);
                mission.loseShield();
                mission.dialogueSystem.eva("\u00a1Error de orden! " + clickedNode.name + " no es el siguiente en la estructura de " + mission.traversalName + " (-150 pts).");
              }
            } else {
              mission.dialogueSystem.eva("El recorrido ya ha finalizado.");
            }
          }
          return;
        }

        mission.dialogueSystem.eva("Haz clic sobre un nodo para expandir la red según el algoritmo activo.");
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
        Node clickedNode = null;
        for (Node n : mission.nodes) {
          if (dist(mx, my, n.x, n.y) < 30) {
            clickedNode = n;
            break;
          }
        }

        if (clickedNode != null) {
          if (mission.dijkstraPathfinder.running) {
            mission.dijkstraPathfinder.handleNodeClick(clickedNode);
            return;
          }

          if (clickedNode.supportive || clickedNode.name.equals("Bruno") || clickedNode.name.equals("Sara") || clickedNode.name.equals("Valeria")) {
            mission.dialogueSystem.say(clickedNode.x, clickedNode.y - 60, "Dijkstra desde " + clickedNode.name + "...");
            mission.clearGlowHints();

            Node ana = mission.getNode("Ana");
            if (ana != null) {
              mission.dijkstraPath = null;
              mission.dijkstraPathfinder.startStepByStep(clickedNode, ana);
              mission.dialogueSystem.eva("¡Dijkstra iniciado desde " + clickedNode.name + "! Busca el nodo con menor distancia tentativa en la tabla del panel derecho.");
              mission.messageLog.add("DIJKSTRA", "Ana", "Buscando canal seguro desde " + clickedNode.name, 1);
              soundManager.playSelect();
            }
          } else {
            mission.score = max(0, mission.score - 200);
            mission.loseShield();
            mission.dialogueSystem.eva(clickedNode.name + " no es un aliado de apoyo disponible (-200 pts). Haz clic en Bruno, Valeria o Sara.");
          }
          return;
        } else {
          mission.dialogueSystem.eva("Haz clic en uno de los nodos que brillan (Bruno, Valeria o Sara) para trazar la ruta segura.");
        }
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

      if (button == RIGHT && mission.calculatedMaxFlow > 0) {
        for (Edge e : mission.edges) {
          if (e.isMouseNear(mx, my)) {
            boolean isSaturated = (e.capacity > 0 && abs(e.flow - e.capacity) < 0.01);
            if (isSaturated) {
              e.blocked = !e.blocked;
              String msg = e.blocked ? "¡Enlace saturado bloqueado! El ataque ha sido mitigado en esta ruta." : "Enlace restaurado.";
              mission.dialogueSystem.say((e.a.x + e.b.x) / 2, (e.a.y + e.b.y) / 2 - 20, e.blocked ? "Bloqueado" : "Restaurado");
              mission.dialogueSystem.eva(msg);
              mission.messageLog.add("EVA", "CONVERGENCIA", e.blocked ? "Corte aplicado" : "Corte removido", e.blocked ? 0 : 1);
              soundManager.playSuccess();
            } else {
              mission.dialogueSystem.eva("Este enlace no está saturado. Para bloquear el flujo de ataque, debes cortar los enlaces del 'Corte Mínimo' (saturados).");
              e.bounceTimer = 1.0f;
              mission.loseShield();
            }
            return;
          }
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
