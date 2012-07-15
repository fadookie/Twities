/**
 * Interface for all game states,
 * Implement to define custom game states
 *
 * @author Eliot Lash
 * @copyright Copyright (c) 2010-2012 Eliot Lash
 */
interface GameState {
  void setup();
  void cleanup();
  void pause();
  void resume(GameState previousState);
  void update(float deltaTime);
  void draw();
  void mouseDragged();
  void mousePressed();
  void mouseReleased();
  void keyPressed();
  void keyReleased();
  void controlEvent(ControlEvent theEvent);
}
