interface TraversalStrategy {
  void start(Node start);
  void update();
  void render();
  ArrayList<Node> getVisitedNodes();
  boolean isRunning();
  void reset();
}
