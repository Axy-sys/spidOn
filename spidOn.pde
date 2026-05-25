Game game;
SoundManager soundManager;
PFont monoFont;
PFont arcadeFont;

// Global Accessibility Settings
boolean colorblindMode = false;
boolean largeTextMode = false;
int textSpeed = 2; // 1 = instant, 2 = fast, 3 = normal

void setup() {
  size(1400, 800);
  smooth(8);
  frameRate(60);
  soundManager = new SoundManager();
  
  // Load custom premium fonts
  monoFont = createFont("ShareTechMono.ttf", 32);
  arcadeFont = createFont("PressStart2P.ttf", 32);
  textFont(monoFont);
  
  game = new Game();
}

void draw() {
  background(5, 10, 20);
  game.update();
  game.render();
}

void mousePressed() {
  game.mousePressed();
}

void keyPressed() {
  game.keyPressed();
}
