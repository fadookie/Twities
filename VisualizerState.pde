class VisualizerState implements GameState {
  void setup() {
    //Default processing camera perspective, but move the near clip plane in and far clip plane out
    float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
    perspective(PI/3.0, width/height, cameraZ/200.0, cameraZ*20.0);

    //Set up GUI
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
    float textureScale = 90000;
    vertex(minCityBounds.x, 0, minCityBounds.z, 0, 0);
    vertex(maxCityBounds.x, 0, minCityBounds.z, textureScale, 0);
    vertex(maxCityBounds.x, 0, maxCityBounds.z, textureScale, textureScale);
    vertex(minCityBounds.x, 0, maxCityBounds.z, 0, textureScale);
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
}
