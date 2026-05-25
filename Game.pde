class Game {

  SceneManager sceneManager;
  boolean[] unlockedMissions = {true, false, false, false, false};

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
