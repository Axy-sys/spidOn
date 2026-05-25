abstract class Scene {

  Game game;

  void setGame(Game game) {
    this.game = game;
  }

  void enter() {}
  void exit() {}

  abstract void update();
  abstract void render();

  void mousePressed() {}
  void keyPressed() {}
}
