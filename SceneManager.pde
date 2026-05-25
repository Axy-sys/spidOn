class SceneManager {

  Game game;
  Scene currentScene;

  SceneManager(Game game) {
    this.game = game;
  }

  void changeScene(Scene nextScene) {

    if (currentScene != null) {
      currentScene.exit();
    }

    currentScene = nextScene;

    if (currentScene != null) {
      currentScene.setGame(game);
      currentScene.enter();
    }
  }

  void update() {
    if (currentScene != null) currentScene.update();
  }

  void render() {
    if (currentScene != null) currentScene.render();
  }

  void mousePressed() {
    if (currentScene != null) currentScene.mousePressed();
  }

  void keyPressed() {
    if (currentScene != null) currentScene.keyPressed();
  }
}
