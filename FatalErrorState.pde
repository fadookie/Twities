class FatalErrorState implements GameState {
  ControlP5 cp5;
  String error;
  Button quitButton;

  FatalErrorState(String error) {
    if (null != error) {
      this.error = error;
    } else {
      this.error = "Unknown error.";
    }
    println("FATAL ERROR: " + this.error);

    //Set up ControlP5
    cp5 = new ControlP5(getMainInstance());

    Textlabel message = cp5.addTextlabel("label")
       .setText(this.error)
       ;
    message.setPosition(100, 100)
       ;

    quitButton = cp5.addButton("Quit")
      .setPosition(100, 120 + message.getHeight())
      ;
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
    background(66);
    cp5.draw();
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
    //Manually invoke the appropriate event
    if (quitButton == theEvent.getController()) {
      exit();
    } else {
      println("unrecognized event: " + theEvent);
    }
  }
}
