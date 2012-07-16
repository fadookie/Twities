/**
 * This state displays a message before transitioning to another game state.
 * @author Eliot Lash
 * @copyright Copyright (c) 2010-2012 Eliot Lash
 */
class LoadScreenState implements GameState {
  String message;
  GameState nextState;
  boolean finished = false;

  LoadScreenState(String _message, GameState _nextState) {
    message = _message;
    nextState = _nextState;
  }

  void setup() {
  }

  void cleanup() {
  }

  void pause() {
  }

  void resume(GameState previousState) {
  }

  void update(float deltaTime) {
  }

  void draw() {
    if (!finished) {
      finished = true;
      //smooth();
      background(66);
      textAlign(CENTER);
      //fill(255);
      text(message, width/2, height/2); 
    } else {
      goToNextState();
    }
  }

  void mouseDragged() {
  }

  void mousePressed() {
  }

  void mouseReleased() {
  }

  void keyPressed() {
  }

  void keyReleased() {
  }

  void controlEvent(ControlEvent theEvent) {
  }

  void goToNextState() {
    engineChangeState(nextState);
  }

}

