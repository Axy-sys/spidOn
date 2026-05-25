class MessageLog {

  ArrayList<LogEntry> logs;
  int scrollOffset = 0;

  MessageLog() {
    logs = new ArrayList<LogEntry>();
  }

  void add(String from, String to, String message, int type) {

    logs.add(
      0,
      new LogEntry(from, to, message, type)
    );

    if (logs.size() > 120) {
      logs.remove(logs.size() - 1);
    }
  }

  void render() {

    float x = 25;
    float y = height - 300;
    float w = 420;
    float h = 260;

    noStroke();
    fill(0, 190);
    rect(x, y, w, h, 14);

    fill(0, 255, 255);
    textAlign(LEFT, TOP);
    textSize(20);
    text("ACTIVIDAD DE LA RED", x + 18, y + 15);

    fill(180);
    textSize(11);
    text("Usa ↑ ↓ para desplazarte", x + 18, y + 42);

    int visible = 8;
    float entryY = y + 70;

    for (
      int i = scrollOffset;
      i < min(logs.size(), scrollOffset + visible);
      i++
    ) {

      LogEntry e = logs.get(i);
      drawEntry(e, x + 14, entryY, w - 28);
      entryY += 52;
    }

    if (logs.size() > visible) {

      float barH = map(visible, 0, logs.size(), 20, h - 80);
      float barY = map(
        scrollOffset,
        0,
        max(1, logs.size() - visible),
        y + 70,
        y + h - 30 - barH
      );

      fill(0, 255, 255, 180);
      rect(x + w - 10, barY, 4, barH, 4);
    }
  }

  void drawEntry(LogEntry e, float x, float y, float w) {

    int c = color(255);

    if (e.type == 0) c = color(255, 60, 80);
    if (e.type == 1) c = color(0, 255, 120);
    if (e.type == 2) c = color(0, 255, 255);

    noStroke();
    fill(15, 25, 40, 220);
    rect(x, y, w, 42, 10);

    fill(c);
    textSize(12);
    textAlign(LEFT, TOP);
    text(e.from + " → " + e.to, x + 12, y + 7);

    fill(255);
    textSize(13);
    text("\"" + e.message + "\"", x + 12, y + 22);
  }

  void scrollUp() {
    scrollOffset--;
    if (scrollOffset < 0) scrollOffset = 0;
  }

  void scrollDown() {
    scrollOffset++;
    if (scrollOffset > max(0, logs.size() - 8)) {
      scrollOffset = max(0, logs.size() - 8);
    }
  }
}

class LogEntry {

  String from;
  String to;
  String message;
  int type;

  LogEntry(String from, String to, String message, int type) {
    this.from = from;
    this.to = to;
    this.message = message;
    this.type = type;
  }
}
