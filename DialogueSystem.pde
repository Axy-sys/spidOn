class DialogueSystem {

  // ============ EVA DIALOGUE BOX ============
  ArrayList<String> messageQueue;
  String currentMessage = "";
  String displayedText = "";
  int charIndex = 0;
  int typingSpeed = 2; // frames per character
  int typingTimer = 0;
  boolean isTyping = false;
  boolean waitingForInput = false;

  // ============ EVA ALERT BAR ============
  String evaBarMessage = "";
  float evaBarAlpha = 0;

  // ============ NODE BUBBLES ============
  ArrayList<DialogueBubble> bubbles;

  DialogueSystem() {
    messageQueue = new ArrayList<String>();
    bubbles = new ArrayList<DialogueBubble>();
  }

  // ============ PUBLIC API ============

  // Queue an EVA message (typewriter style)
  void eva(String message) {
    messageQueue.add(message);
    if (!isTyping && !waitingForInput && currentMessage.length() == 0) {
      advanceMessage();
    }
  }

  // Quick alert banner at top
  void alert(String message) {
    evaBarMessage = message;
    evaBarAlpha = 255;
  }

  // Node-level dialogue bubble
  void say(float x, float y, String message) {
    int offset = bubbles.size() % 3;
    bubbles.add(new DialogueBubble(x, y, message, offset));
    while (bubbles.size() > 6) {
      bubbles.remove(0);
    }
  }

  // Clear all
  void clear() {
    bubbles.clear();
    messageQueue.clear();
    currentMessage = "";
    displayedText = "";
    isTyping = false;
    waitingForInput = false;
  }

  // Is EVA currently talking?
  boolean isDialogueActive() {
    return currentMessage.length() > 0;
  }

  // Called when player presses SPACE
  void skipOrAdvance() {
    if (isTyping) {
      // Complete text instantly
      displayedText = currentMessage;
      charIndex = currentMessage.length();
      isTyping = false;
      waitingForInput = true;
    } else if (waitingForInput) {
      advanceMessage();
    }
  }

  // ============ INTERNAL ============

  void advanceMessage() {
    if (messageQueue.size() > 0) {
      currentMessage = messageQueue.remove(0);
      displayedText = "";
      charIndex = 0;
      typingTimer = 0;
      isTyping = true;
      waitingForInput = false;
    } else {
      currentMessage = "";
      displayedText = "";
      isTyping = false;
      waitingForInput = false;
    }
  }

  void update() {
    // Update node bubbles
    for (int i = bubbles.size() - 1; i >= 0; i--) {
      DialogueBubble b = bubbles.get(i);
      b.update();
      if (b.finished) {
        bubbles.remove(i);
      }
    }

    // Fade alert bar
    if (evaBarAlpha > 0) {
      evaBarAlpha *= 0.985;
      if (evaBarAlpha < 2) evaBarAlpha = 0;
    }

    // Typewriter effect
    if (isTyping) {
      typingTimer++;
      int speedVal = 2;
      if (textSpeed == 1) speedVal = 0;      // instant
      else if (textSpeed == 2) speedVal = 2; // fast
      else if (textSpeed == 3) speedVal = 5; // normal

      if (speedVal == 0) {
        displayedText = currentMessage;
        charIndex = currentMessage.length();
        isTyping = false;
        waitingForInput = true;
      } else if (typingTimer >= speedVal) {
        typingTimer = 0;
        if (charIndex < currentMessage.length()) {
          charIndex++;
          displayedText = currentMessage.substring(0, charIndex);
        } else {
          isTyping = false;
          waitingForInput = true;
        }
      }
    }
  }

  // ============ RENDERING — WORLD SPACE (bubbles on nodes) ============

  void renderWorld() {
    for (DialogueBubble b : bubbles) {
      b.render();
    }
  }

  // ============ RENDERING — SCREEN SPACE (EVA UI) ============

  void renderUI() {
    renderAlertBar();
    renderDialogueBox();
  }

  // Legacy combined render (for backward compat)
  void render() {
    renderWorld();
    renderUI();
  }

  // ============ ALERT BAR ============

  void renderAlertBar() {
    if (evaBarMessage == null || evaBarMessage.length() == 0 || evaBarAlpha < 3) return;

    float w = 660;
    float h = 52;
    float x = (width - 340) / 2 - w / 2;
    float y = 14;

    pushStyle();
    noStroke();
    fill(10, 15, 30, evaBarAlpha * 0.92);
    rect(x, y, w, h, 16);

    stroke(255, 180, 0, evaBarAlpha);
    strokeWeight(2);
    noFill();
    rect(x, y, w, h, 16);

    fill(255, 200, 0, evaBarAlpha);
    textAlign(CENTER, CENTER);
    textSize(20);
    text("⚠  " + evaBarMessage, x + w / 2, y + h / 2);
    popStyle();
  }

  // ============ EVA DIALOGUE BOX ============

  void renderDialogueBox() {
    if (currentMessage.length() == 0) return;

    pushStyle();

    float panelW = width - 380;
    float panelH = 130;
    float panelX = 20;
    float panelY = height - panelH - 20;

    // Shadow
    noStroke();
    fill(0, 0, 0, 100);
    rect(panelX + 4, panelY + 4, panelW, panelH, 18);

    // Background
    fill(8, 16, 32, 245);
    rect(panelX, panelY, panelW, panelH, 18);

    // Border — subtle glow
    stroke(0, 200, 255, 140);
    strokeWeight(2);
    noFill();
    rect(panelX, panelY, panelW, panelH, 18);

    // Inner highlight line
    stroke(0, 255, 255, 40);
    strokeWeight(1);
    line(panelX + 90, panelY + 10, panelX + panelW - 20, panelY + 10);

    // ---- EVA AVATAR ----
    float avatarCX = panelX + 50;
    float avatarCY = panelY + panelH / 2;
    float avatarR = 54;

    // Outer glow ring
    noFill();
    float glowPulse = 0.6 + sin(frameCount * 0.06) * 0.4;
    stroke(0, 255, 255, 30 * glowPulse);
    strokeWeight(8);
    ellipse(avatarCX, avatarCY, avatarR * 1.5, avatarR * 1.5);

    // Avatar circle
    stroke(0, 220, 255, 200);
    strokeWeight(2.5);
    fill(12, 28, 50);
    ellipse(avatarCX, avatarCY, avatarR, avatarR);

    // "EVA" label
    noStroke();
    fill(0, 255, 255);
    textAlign(CENTER, CENTER);
    textSize(15);
    text("E V A", avatarCX, avatarCY);

    // ---- MESSAGE TEXT ----
    float textX = panelX + 95;
    float textY = panelY + 22;
    float textW = panelW - 130;
    float textH = panelH - 50;

    fill(255);
    textAlign(LEFT, TOP);
    textSize(largeTextMode ? 21 : 17);
    text(displayedText, textX, textY, textW, textH);

    // ---- "ESPACIO" PROMPT ----
    if (waitingForInput) {
      float promptAlpha = 140 + sin(frameCount * 0.12) * 115;
      fill(0, 255, 255, promptAlpha);
      textAlign(RIGHT, BOTTOM);
      textSize(13);
      text("▶ ESPACIO", panelX + panelW - 18, panelY + panelH - 10);
    }

    // ---- TYPING DOTS ----
    if (isTyping) {
      fill(0, 255, 255, 180);
      textAlign(RIGHT, BOTTOM);
      textSize(13);
      int dots = (frameCount / 10) % 4;
      String dotStr = "";
      for (int i = 0; i < dots; i++) dotStr += "●";
      text(dotStr, panelX + panelW - 18, panelY + panelH - 10);
    }

    popStyle();
  }
}
