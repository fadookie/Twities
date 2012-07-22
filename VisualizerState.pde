/**
 * VisualizerState is the main state of the application.
 * It renders a 3D representation of the Twitter data that responds to user input.
 */
class VisualizerState implements GameState {
  ControlP5 cp5;
  boolean searchMode = true;
  String searchUsername = "";
  Group searchGroup;
  Textfield searchUsernameTextfield;
  Bang searchUsernameButton;
  //Bang searchHideButton;

  void setup() {
    //Default processing camera perspective, but move the near clip plane in and far clip plane out
    float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
    perspective(PI/3.0, width/height, cameraZ/200.0, cameraZ*20.0);

    //Set up GUI

    //Set up ControlP5
    cp5 = new ControlP5(getMainInstance());
    searchGroup = cp5.addGroup("g1");

    searchUsernameTextfield = cp5.addTextfield("searchUsername");
    searchUsernameTextfield.setPosition(20, height - 50)
       .setSize(200,40)
       .setGroup(searchGroup)
       //.setFont(font)
       .setCaptionLabel("")
       //.setFocus(true)
       .setAutoClear(false)
       ;

    searchUsernameButton = cp5.addBang("search");
    searchUsernameButton.setPosition(240, height - 50)
       .setSize(80,40)
       .setGroup(searchGroup)
       .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
       ;    

    //slider for ground texture scale
    cp5.addSlider("groundTextureScale")
       .setSize(width, 10)
       .setPosition(0,50)
       .setRange(1,90000)
       .setValue(90000)
       ;

    /*
    searchHideButton = cp5.addBang("x");
    searchHideButton.setPosition(340, height - 50)
       .setSize(40,40)
       .setGroup(searchGroup)
       .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
       ;    
   */
   
    //Set up camera/HUD stuff
    cityCenter = PVector.add(minCityBounds, maxCityBounds); 
    cityCenter.div(2);

    citySize = PVector.mult(minCityBounds, -1); //Treat minCityBounds as the origin, not sure if this math here is correct
    citySize.add(maxCityBounds);

    //println("citySize="+citySize+" cityCenter="+cityCenter);

    //Start looking at the center of the city
    camera = new PeasyCam(getMainInstance(), cityCenter.x, -40, cityCenter.z, 500/*distance*/);
    //camera.setMinimumDistance(-10);
    camera.setMaximumDistance(6500);
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
    PGraphicsOpenGL pgl = (PGraphicsOpenGL)g;

    background(color(112, 252, 255));

    //Draw ground detail stuff
    hint(DISABLE_DEPTH_TEST); //Was getting some weird interlacing stuff, so i'm now drawing the ground in it's own depth buffer underneath the buildings at all times
    pushStyle();
    noStroke();
    fill(0);

    //Draw ground
    pushMatrix();

    //Just make the ground plane really large
    scale(1000, 0, 1000);

    beginShape(QUADS);
    pgl.textureSampling(Texture.LINEAR);
    pgl.textureWrap(Texture.REPEAT); //Set texture wrap mode to GL_REPEAT. See http://code.google.com/p/processing/issues/detail?id=94
    textureMode(NORMAL);
    texture(grassImages[currentGrassImage]);
    vertex(minCityBounds.x, 0, minCityBounds.z, 0, 0);
    vertex(maxCityBounds.x, 0, minCityBounds.z, groundTextureScale, 0);
    vertex(maxCityBounds.x, 0, maxCityBounds.z, groundTextureScale, groundTextureScale);
    vertex(minCityBounds.x, 0, maxCityBounds.z, 0, groundTextureScale);
    endShape();

    popMatrix();

    //Draw roads
    roads.draw();

    popStyle();
    hint(ENABLE_DEPTH_TEST);

    pgl.textureSampling(Texture.BILINEAR);

    //Draw buildings
    for (Building building : buildings) {
      building.draw();
    }

    if (DEBUG) {
      calculateAxis(50); //For debug drawing
    }

    //HUD
    camera.beginHUD();
    //Clear depth buffer so the HUD is guaranteed to be on top
    hint(DISABLE_DEPTH_TEST); 
    if (messageString != null) {
      text(messageString, 0, height - 50);
    }
    if (DEBUG) {
      drawAxis(2);
    }

    //ControlP5 GUI
    cp5.draw();

    hint(ENABLE_DEPTH_TEST);
    camera.endHUD();

    //float[] position = camera.getPosition();
    //float[] rotations = camera.getRotations();
    //println(position);
    //println("rotX: " + degrees(rotations[0]) + ", rotY: " +degrees(rotations[1])+ ", rotZ: " +degrees(rotations[2]) + ", dist: " + camera.getDistance());
    //

    if (saveNextFrame) {
      saveNextFrame = false;
      //Note, this doesn't seem to work with Processing 0206
      saveFrame("screenshot-###.png"); 
    }
  }

  void mouseDragged() {
  }

  void mousePressed() {
  }

  void mouseReleased() {
  }

  void keyPressed() {
    if (!searchUsernameTextfield.isActive()) {
      if (CODED == key) {
      } else {
        switch(key) {
          case '/':
            toggleSearchMode();
            break;
          case 'd':
            DEBUG = !DEBUG;
            break;
          case 's':
            saveNextFrame = true;
            break;
          case '1':
          case '2':
          case '3':
          case '4':
            //Switch grass texture to texture 1-4 (stored in array items 0-3)
            currentGrassImage = Integer.parseInt(Character.toString(key)) - 1;
            break;
        }
      }
    }
  }

  void keyReleased() {
  }

  //---------- ControlP5 GUI Event Handlers ---------------//

  void controlEvent(ControlEvent theEvent) {
    //Manually invoke the appropriate event
    if (searchUsernameTextfield == theEvent.getController()) {
      searchUsername(theEvent.getController().getStringValue());
    } else if (searchUsernameButton == theEvent.getController()) {
      search();
    } else {
      println("unrecognized event: " + theEvent);
    }
  }

  void search() {
    //Event handler for Search button being pressed
    searchUsernameTextfield.submit();
  }

  /*
  public void x() {
    toggleSearchMode();
  }
  */

  void clear() {
    searchUsernameTextfield.setColor(color(255));
    searchUsernameTextfield.clear();
  }

  void searchUsername(String screenName) {
    // event handler for searchUsername being submitted
    tryHighlightUser(screenName.trim());
  }

  void tryHighlightUser(String screenName) {
    Building resultBuilding = buildingsByName.get(screenName.toLowerCase());
    if (null != resultBuilding) {
      PVector center = resultBuilding.getCenterPosition();
      //The center is the actual center of the building, we want to center our camera on the top of the building so we use the Y scale. Remember to flip the sign since "up" in this city is the -Y axis
      camera.lookAt(center.x, -resultBuilding.getYScale(), center.z, msCameraTweenTime);
      camera.setRotations(radians(90), 0, 0);
      camera.setDistance(170, msCameraTweenTime);
      this.clear();
    } else {
      searchUsernameTextfield.setText(screenName);
      searchUsernameTextfield.setColor(color(255, 0, 0));
    }
  }

  void toggleSearchMode() {
    searchMode = !searchMode;
    if (searchMode) {
      searchGroup.hide();
      this.clear();
    } else {
      searchGroup.show();
      searchUsernameTextfield.setFocus(true);
    }
  }

}
