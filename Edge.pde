class Edge {

  Node a;
  Node b;

  float weight = 1;
  float cost = 1;         // for MST
  float capacity = 1;     // for Max Flow
  float flow = 0;         // for Max Flow
  boolean partOfMST = false; // to highlight MST edges

  boolean blocked = false;
  boolean highlighted = false;

  Edge(Node a, Node b) {
    this.a = a;
    this.b = b;
  }

  void render() {
    int currentMission = 1;
    boolean isMSTMission = false;
    boolean isSandbox = false;
    int sandMode = 0; // 0=BFS/DFS, 1=Dijkstra, 2=Kruskal, 3=MaxFlow
    
    if (game != null && game.sceneManager.currentScene != null) {
      if (game.sceneManager.currentScene instanceof MissionScene) {
        MissionScene ms = (MissionScene) game.sceneManager.currentScene;
        currentMission = ms.missionID;
        if (currentMission == 3 || (currentMission == 5 && ms.missionStage == 3)) {
          isMSTMission = true;
        }
      } else if (game.sceneManager.currentScene.getClass().getSimpleName().equals("SandboxScene")) {
        isSandbox = true;
        // Use reflection or dynamic check in java if needed, or cast directly since it will exist
        SandboxScene ss = (SandboxScene) game.sceneManager.currentScene;
        sandMode = ss.sandboxMode;
        if (sandMode == 2) {
          isMSTMission = true;
        }
      }
    }

    if (colorblindMode) {
      if (blocked) {
        stroke(230, 97, 1, 230); // High-contrast orange
        strokeWeight(4);
      } else if (highlighted) {
        stroke(247, 247, 247, 230); // High-contrast white
        strokeWeight(4);
      } else if (isMSTMission) {
        if (partOfMST) {
          stroke(94, 60, 153, 240); // High-contrast purple
          strokeWeight(6);
        } else {
          boolean isCandidate = false;
          if (game != null && game.sceneManager.currentScene != null) {
            if (game.sceneManager.currentScene instanceof MissionScene) {
              MissionScene ms = (MissionScene) game.sceneManager.currentScene;
              if (ms.kruskalMST.currentEdge == this) isCandidate = true;
            } else if (game.sceneManager.currentScene.getClass().getSimpleName().equals("SandboxScene")) {
              SandboxScene ss = (SandboxScene) game.sceneManager.currentScene;
              if (ss.kruskalMST.currentEdge == this) isCandidate = true;
            }
          }

          if (isCandidate) {
            stroke(253, 184, 99, 255); // High-contrast gold/yellow for candidate
            strokeWeight(6);
          } else {
            stroke(180, 180, 180, 50); // Faded gray for non-MST
            strokeWeight(1.5);
          }
        }
      } else {
        stroke(140, 140, 140, 130);
        strokeWeight(2.5);
      }
    } else {
      if (blocked) {
        stroke(255, 0, 80, 220);
        strokeWeight(3);
      } else if (highlighted) {
        stroke(0, 255, 255, 220);
        strokeWeight(3);
      } else if (isMSTMission) {
        if (partOfMST) {
          stroke(255, 200, 0, 240); // Gold/Yellow for MST
          strokeWeight(5);
        } else {
          boolean isCandidate = false;
          if (game != null && game.sceneManager.currentScene != null) {
            if (game.sceneManager.currentScene instanceof MissionScene) {
              MissionScene ms = (MissionScene) game.sceneManager.currentScene;
              if (ms.kruskalMST.currentEdge == this) isCandidate = true;
            } else if (game.sceneManager.currentScene.getClass().getSimpleName().equals("SandboxScene")) {
              SandboxScene ss = (SandboxScene) game.sceneManager.currentScene;
              if (ss.kruskalMST.currentEdge == this) isCandidate = true;
            }
          }

          if (isCandidate) {
            float blink = sin(frameCount * 0.15) * 0.3 + 0.7;
            stroke(255, 255, 0, 255); // Flashing bright yellow for candidate
            strokeWeight(5 + 2 * blink);
          } else {
            stroke(0, 180, 255, 35);  // Very faded for non-MST
            strokeWeight(1.5);
          }
        }
      } else {
        stroke(0, 180, 255, 120);
        strokeWeight(3);
      }
    }

    line(a.x, a.y, b.x, b.y);

    // Draw flow animation
    if (flow > 0 && !blocked) {
      pushStyle();
      float t = (frameCount * 0.015) % 1.0;
      float px = lerp(a.x, b.x, t);
      float py = lerp(a.y, b.y, t);
      fill(colorblindMode ? color(230, 97, 1) : color(255, 80, 100));
      noStroke();
      ellipse(px, py, 8 + flow * 0.4, 8 + flow * 0.4);
      popStyle();
    }

    if (blocked) {
      float midX = (a.x + b.x) / 2;
      float midY = (a.y + b.y) / 2;

      stroke(colorblindMode ? color(230, 97, 1) : color(255, 0, 80));
      strokeWeight(3);

      line(midX - 10, midY - 10, midX + 10, midY + 10);
      line(midX + 10, midY - 10, midX - 10, midY + 10);
    }

    // Draw weights / costs / flows
    if (game != null && game.sceneManager.currentScene != null) {
      float midX = (a.x + b.x) / 2;
      float midY = (a.y + b.y) / 2;
      float angle = atan2(b.y - a.y, b.x - a.x);
      float offsetX = cos(angle + HALF_PI) * 16;
      float offsetY = sin(angle + HALF_PI) * 16;

      pushStyle();
      textAlign(CENTER, CENTER);
      textSize(largeTextMode ? 16 : 12);

      boolean showW = false;
      boolean showC = false;
      boolean showF = false;

      if (isSandbox) {
        if (sandMode == 1) showW = true;
        else if (sandMode == 2) showC = true;
        else if (sandMode == 3) showF = true;
      } else if (game.sceneManager.currentScene instanceof MissionScene) {
        MissionScene ms = (MissionScene) game.sceneManager.currentScene;
        if (currentMission == 2 || (currentMission == 5 && ms.missionStage == 2)) {
          showW = true;
        } else if (currentMission == 3 || (currentMission == 5 && ms.missionStage == 3)) {
          showC = true;
        } else if (currentMission == 4 || (currentMission == 5 && ms.missionStage == 4)) {
          showF = true;
        }
      }

      if (showW) {
        fill(colorblindMode ? color(253, 184, 99) : color(255, 180, 0));
        text(nf(weight, 0, 0), midX + offsetX, midY + offsetY);
      } else if (showC) {
        fill(colorblindMode ? color(94, 60, 153) : color(0, 255, 180));
        text(nf(cost, 0, 0), midX + offsetX, midY + offsetY);
      } else if (showF) {
        fill(colorblindMode ? color(230, 97, 1) : color(255, 100, 120));
        text(nf(flow, 0, 0) + "/" + nf(capacity, 0, 0), midX + offsetX, midY + offsetY);
      }
      popStyle();
    }
  }

  boolean isMouseNear(float mx, float my) {
    return distToSegment(mx, my, a.x, a.y, b.x, b.y) < 12;
  }

  float distToSegment(
    float px, float py,
    float x1, float y1,
    float x2, float y2
  ) {

    float A = px - x1;
    float B = py - y1;
    float C = x2 - x1;
    float D = y2 - y1;

    float dot = A * C + B * D;
    float lenSq = C * C + D * D;

    float param = -1;
    if (lenSq != 0) param = dot / lenSq;

    float xx, yy;

    if (param < 0) {
      xx = x1; yy = y1;
    } else if (param > 1) {
      xx = x2; yy = y2;
    } else {
      xx = x1 + param * C;
      yy = y1 + param * D;
    }

    float dx = px - xx;
    float dy = py - yy;
    return sqrt(dx * dx + dy * dy);
  }
}
