class Node {

  float x;
  float y;
  float radius = 42;

  String name;
  String role;

  ArrayList<Node> neighbors;

  boolean visited = false;
  boolean infected = false;
  boolean supportive = false;
  boolean vulnerable = false;
  boolean shielded = false;
  boolean corrupted = false;

  boolean hovered = false;
  boolean selected = false;

  float stress = 0;
  float support = 100;
  float toxicity = 0;

  int level = -1;

  // Algorithm auxiliary fields
  float dijkstraDist = Float.MAX_VALUE;
  Node dijkstraParent = null;
  Node bfsParent = null;

  float pulseOffset;
  float shakeX = 0;
  float shakeY = 0;
  float reactionTimer = 0;

  // Glow hint: when true, shows a pulsing cyan ring and "▼ CLIC" label
  boolean glowHint = false;

  Node(float x, float y, String name) {
    this(x, y, name, "");
  }

  Node(float x, float y, String name, String role) {
    this.x = x;
    this.y = y;
    this.name = name;
    this.role = role;
    neighbors = new ArrayList<Node>();
    pulseOffset = random(TWO_PI);
  }

  void connect(Node other) {
    if (!neighbors.contains(other)) neighbors.add(other);
  }

  void update(float mx, float my) {

    reactionTimer += 0.06;
    hovered = dist(mx, my, x, y) < 28;

    if (infected) {
      stress = constrain(stress + 0.02, 0, 100);
      toxicity = constrain(toxicity + 0.03, 0, 100);
    }

    float stressPower = map(stress, 0, 100, 0, 6);

    if (infected) {
      shakeX = random(-stressPower, stressPower);
      shakeY = random(-stressPower, stressPower);
    } else if (vulnerable) {
      shakeX = sin(reactionTimer * 2.2) * 1.4;
      shakeY = cos(reactionTimer * 1.9) * 1.4;
    } else if (supportive) {
      shakeX = sin(reactionTimer * 1.2) * 0.6;
      shakeY = cos(reactionTimer * 1.1) * 0.6;
    } else {
      shakeX *= 0.85;
      shakeY *= 0.85;
    }
  }

  void render() {
    float r = radius;

    pushMatrix();
    translate(x + shakeX, y + shakeY);

    // Add node-specific shake for reactions
    if (reactionTimer < PI) {
      float shakeAmt = sin(reactionTimer) * 12;
      translate(random(-shakeAmt, shakeAmt), random(-shakeAmt, shakeAmt));
    }

    boolean isHidden = false;
    boolean revealRoleColors = true;

    // Check fog of war
    if (game != null && game.sceneManager.currentScene != null && game.sceneManager.currentScene instanceof MissionScene) {
      MissionScene ms = (MissionScene) game.sceneManager.currentScene;
      if (ms.missionID == 1 || (ms.missionID == 5 && ms.missionStage == 1)) {
        // Fog of war rules: show if visited, or if in Queue/Stack
        boolean inQueueOrStack = false;
        if (ms.traversalName.equals("BFS")) {
          inQueueOrStack = ms.bfsTraversal.queue.contains(this);
        } else {
          inQueueOrStack = ms.dfsTraversal.stack.contains(this);
        }

        if (name.equals("Ana")) {
          isHidden = false;
          revealRoleColors = visited;
        } else if (visited) {
          isHidden = false;
          revealRoleColors = true;
        } else if (inQueueOrStack) {
          isHidden = false;
          revealRoleColors = false; // Discovered but neutral style
        } else if (corrupted) {
          isHidden = false;
          revealRoleColors = false;
        } else {
          isHidden = true;
          revealRoleColors = false;
        }

        if (ms.selectedNode == this) {
          isHidden = false;
          revealRoleColors = visited;
        }
      }
    }

    // ─── Glow hint ring + label ───────────────────────────
    if (glowHint) {
      pushStyle();
      float glowPulse  = sin(frameCount * 0.07 + pulseOffset);   // -1..1
      float glowSize   = map(glowPulse, -1, 1, 85, 95);
      float glowAlpha  = map(glowPulse, -1, 1, 80, 160);

      noFill();
      strokeWeight(3.5);
      stroke(0, 240, 220, glowAlpha);          // cyan ring
      ellipse(0, 0, glowSize, glowSize);

      // secondary softer outer ring
      stroke(0, 255, 180, glowAlpha * 0.4);
      strokeWeight(2);
      ellipse(0, 0, glowSize + 12, glowSize + 12);

      // "▼ CLIC" label – blinks via alpha
      boolean labelVisible = (frameCount % 50) < 35;   // visible ~70 % of the time
      if (labelVisible) {
        noStroke();
        textAlign(CENTER, CENTER);
        textSize(largeTextMode ? 15 : 12);
        float lblAlpha = map(sin(frameCount * 0.12), -1, 1, 140, 255);

        // dark pill behind the label
        float tw = textWidth("\u25BC CLIC") + 12;
        float th = largeTextMode ? 22 : 18;
        fill(0, 0, 0, 150);
        rect(-tw / 2, -radius - 55 - th / 2, tw, th, 6);

        fill(0, 240, 220, lblAlpha);
        text("\u25BC CLIC", 0, -radius - 55);
      }
      popStyle();
    }

    // ─── Outer ambient glow ───────────────────────────────
    noStroke();

    if (isHidden) {
      fill(80, 80, 80, 15);
      ellipse(0, 0, 78, 78);
    } else if (corrupted) {
      float glowPulse = sin(frameCount * 0.1) * 0.5 + 0.5;
      fill(255, 120, 0, 40 + 35 * glowPulse); // Pulsing orange glow
      ellipse(0, 0, 88 + 10 * glowPulse, 88 + 10 * glowPulse);
    } else if (colorblindMode) {
      if (revealRoleColors && infected) {
        fill(230, 97, 1, 45); // high-contrast orange
        ellipse(0, 0, 88, 88);
      } else if (revealRoleColors && supportive) {
        fill(94, 60, 153, 35); // high-contrast purple
        ellipse(0, 0, 82, 82);
      } else if (revealRoleColors && vulnerable) {
        fill(253, 184, 99, 35); // high-contrast light yellow
        ellipse(0, 0, 82, 82);
      } else {
        fill(247, 247, 247, 22); // high-contrast white/gray
        ellipse(0, 0, 78, 78);
      }
    } else {
      if (revealRoleColors && infected) {
        fill(255, 60, 90, 35);
        ellipse(0, 0, 88, 88);
      } else if (revealRoleColors && supportive) {
        fill(0, 255, 120, 28);
        ellipse(0, 0, 82, 82);
      } else if (revealRoleColors && vulnerable) {
        fill(255, 220, 0, 28);
        ellipse(0, 0, 82, 82);
      } else {
        fill(0, 255, 255, 22);
        ellipse(0, 0, 78, 78);
      }
    }

    // ─── Main body circle ─────────────────────────────────
    strokeWeight(3);

    if (isHidden) {
      stroke(100, 100, 100);
      fill(20, 20, 25);
    } else if (corrupted) {
      float pulse = sin(frameCount * 0.1) * 0.5 + 0.5;
      stroke(255, 120, 0); // Pulse border
      strokeWeight(3 + 2 * pulse);
      fill(60, 25, 0); // dark orange fill
    } else if (colorblindMode) {
      if (revealRoleColors && infected) {
        stroke(230, 97, 1);
        fill(60, 25, 0);
      } else if (revealRoleColors && supportive) {
        stroke(94, 60, 153);
        fill(25, 10, 45);
      } else if (revealRoleColors && vulnerable) {
        stroke(253, 184, 99);
        fill(45, 30, 10);
      } else {
        stroke(200, 200, 200);
        fill(30, 30, 30);
      }
    } else {
      if (revealRoleColors && infected) {
        stroke(255, 0, 80);
        fill(60, 0, 20);
      } else if (revealRoleColors && supportive) {
        stroke(0, 255, 120);
        fill(10, 40, 25);
      } else if (revealRoleColors && vulnerable) {
        stroke(255, 220, 0);
        fill(40, 35, 0);
      } else {
        stroke(0, 220, 255);
        fill(10, 30, 50);
      }
    }

    ellipse(0, 0, r * 2, r * 2);

    // Inner highlight disc
    if (!isHidden) {
      noStroke();
      if (corrupted) {
        fill(255, 120, 0); // Orange
      } else if (colorblindMode) {
        fill((revealRoleColors && infected) ? color(230, 97, 1) : color(247, 247, 247));
      } else {
        fill((revealRoleColors && infected) ? color(255, 60, 120) : color(0, 255, 255));
      }
      ellipse(0, 0, radius * 0.8, radius * 0.8);
    }

    // ─── Visited ring ─────────────────────────────────────
    if (visited) {
      noFill();
      stroke(255, 255, 255, 180);
      strokeWeight(2);
      ellipse(0, 0, r * 2.8, r * 2.8);
    }

    // ─── Shield ring ──────────────────────────────────────
    if (shielded) {
      pushStyle();
      noFill();
      stroke(colorblindMode ? color(94, 60, 153) : color(0, 150, 255));
      strokeWeight(4);
      ellipse(0, 0, r * 2.4, r * 2.4);
      stroke(colorblindMode ? color(247, 247, 247) : color(0, 255, 255));
      strokeWeight(1.5);
      float shieldPulse = sin(frameCount * 0.1) * 0.3 + 1.0;
      ellipse(0, 0, r * 2.4 + 4 * shieldPulse, r * 2.4 + 4 * shieldPulse);
      popStyle();
    }

    // ─── Hover / selected ring ────────────────────────────
    if (hovered || selected) {
      noFill();
      stroke(255);
      strokeWeight(2);
      ellipse(0, 0, r * 3.3, r * 3.3);
    }

    // ─── Name label with dark background pill ─────────────
    pushStyle();
    textAlign(CENTER, CENTER);
    float nameTextSize = largeTextMode ? 20 : 15;
    textSize(nameTextSize);
    String displayName = isHidden ? "???" : name;
    float nameTw = textWidth(displayName) + 14;
    float nameTh = largeTextMode ? 26 : 20;
    noStroke();
    fill(0, 0, 0, 140);
    rect(-nameTw / 2, -42 - nameTh / 2, nameTw, nameTh, 8);
    fill(255);
    text(displayName, 0, -42);
    popStyle();

    // ─── Role label with dark background pill ─────────────
    if (!isHidden && role != null && role.length() > 0 && revealRoleColors) {
      pushStyle();
      textAlign(CENTER, CENTER);
      float roleTextSize = largeTextMode ? 15 : 11;
      textSize(roleTextSize);
      float roleTw = textWidth(role) + 12;
      float roleTh = largeTextMode ? 22 : 17;
      noStroke();
      fill(0, 0, 0, 120);
      rect(-roleTw / 2, 42 - roleTh / 2, roleTw, roleTh, 6);
      fill(180);
      text(role, 0, 42);
      popStyle();
    }

    // ─── BFS level label ──────────────────────────────────
    if (level >= 0) {
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(largeTextMode ? 18 : 14);
      text(level, 0, -radius - 14);
    }

    // ─── Infection / Accessibility Badge ──────────────────
    if (!isHidden && revealRoleColors) {
      pushStyle();
      textAlign(CENTER, CENTER);
      if (colorblindMode) {
        fill(255);
        textSize(largeTextMode ? 16 : 12);
        String badge = "[N]";
        if (infected) badge = "[X]";
        else if (shielded) badge = "[S]";
        else if (supportive) badge = "[A]";
        else if (vulnerable) badge = "[V]";
        text(badge, 0, 2);
      } else if (shielded) {
        fill(0, 255, 255);
        textSize(largeTextMode ? 16 : 12);
        text("🛡️", 0, 2);
      } else if (infected) {
        fill(255);
        textSize(largeTextMode ? 22 : 18);
        text("!", 0, 2);
      }
      popStyle();
    }

    // ─── Hover tooltip ────────────────────────────────────
    if (hovered && role != null && role.length() > 0) {
      pushStyle();
      textAlign(CENTER, CENTER);
      textSize(largeTextMode ? 16 : 12);
      String tip = name + "  ·  " + role;
      float tipW = textWidth(tip) + 20;
      float tipH = largeTextMode ? 30 : 24;
      float tipY = radius + 28;

      noStroke();
      fill(0, 0, 0, 200);
      rect(-tipW / 2, tipY - tipH / 2, tipW, tipH, 8);

      fill(255, 255, 255, 230);
      text(tip, 0, tipY);
      popStyle();
    }

    drawStressBar();
    popMatrix();
  }

  void drawStressBar() {
    boolean isHidden = false;
    if (game != null && game.sceneManager.currentScene != null && game.sceneManager.currentScene instanceof MissionScene) {
      MissionScene ms = (MissionScene) game.sceneManager.currentScene;
      if ((ms.missionID == 1 || (ms.missionID == 5 && ms.missionStage == 1)) && !visited) {
        isHidden = true;
      }
    }
    if (isHidden) return;

    float w = 42;
    float h = 6;

    noStroke();
    fill(40);
    rect(-w / 2, -radius - 30, w, h, 4);

    fill(255, 0, 80);
    rect(-w / 2, -radius - 30, map(stress, 0, 100, 0, w), h, 4);
  }
}
