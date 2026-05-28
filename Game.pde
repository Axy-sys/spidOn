class Game {

  SceneManager sceneManager;
  boolean[] unlockedMissions = {true, false, false, false, false};

  // ── Evidencias recolectadas por misión ──────────────────────────────────
  // Se llenan al completar cada misión y se leen en la Misión 5 (final).
  String evidence_m1_source = "";      // "Ghost se infiltró a través de: CARLA"
  float  evidence_m2_routeCost = 0;    // Costo total de la ruta segura (Dijkstra)
  float  evidence_m3_mstCost   = 0;    // Costo total del MST (Kruskal)
  float  evidence_m4_maxFlow   = 0;    // Flujo máximo del ataque (Ford-Fulkerson)

  Game() {
    sceneManager = new SceneManager(this);
    sceneManager.changeScene(new MenuScene());
  }

  void update() {
    sceneManager.update();
  }

  void render() {
    sceneManager.render();
  }

  void mousePressed() {
    sceneManager.mousePressed();
  }

  void keyPressed() {
    sceneManager.keyPressed();
  }
}
