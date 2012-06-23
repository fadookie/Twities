class Building implements Comparable<Building> {
  Avatar avatar;
  User user;
  PVector position = new PVector();
  float scale = 1;
  float scaleYFactor = 1000;
  float minXScale = 20;
  float maxXScale = 100;
  PVector scaleWorkVector = new PVector();

  Building(Avatar avatar) {
    this.avatar = avatar;
    user = avatar.user;
    scale = user.getFollowersCount();
  }

  void draw() {
    //Cache scale so we don't need to do the calculations multiple times in a single draw call
    scaleWorkVector.x = getXScale();
    scaleWorkVector.y = -getYScale();
    scaleWorkVector.z = getZScale();

    pushStyle();
    pushMatrix();
      translate(position.x, -position.y, position.z);

        pushMatrix();
          ((PGraphicsOpenGL)g).textureWrap(Texture.REPEAT); //Set texture wrap mode to GL_REPEAT. See http://code.google.com/p/processing/issues/detail?id=94
          beginShape(QUADS);

          if (avatar.image != null) {
              noStroke();
              textureMode(NORMAL);
              texture(avatar.image);
          } else {
              //Fallback drawing routine if we have no avatar image
              stroke(0);
          }

          //TOP
          vertex(0, scaleWorkVector.y, 0, 0, 0);
          vertex(scaleWorkVector.x, scaleWorkVector.y, 0, 1, 0);
          vertex(scaleWorkVector.x, scaleWorkVector.y, scaleWorkVector.z, 1, 1);
          vertex(0, scaleWorkVector.y, scaleWorkVector.z, 0, 1);

          //BOTTOM
          vertex(0, 0, 0, 0, 0);
          vertex(scaleWorkVector.x, 0, 0, 1, 0);
          vertex(scaleWorkVector.x, 0, scaleWorkVector.z, 1, 1);
          vertex(0, 0, scaleWorkVector.z, 0, 1);

          //BACK
          vertex(0, 0, 0, 0, 1);
          vertex(scaleWorkVector.x, 0, 0, 1, 1);
          vertex(scaleWorkVector.x, scaleWorkVector.y, 0, 1, 0);
          vertex(0, scaleWorkVector.y, 0, 0, 0);

          //FRONT
          vertex(0, 0, scaleWorkVector.z, 0, 1);
          vertex(scaleWorkVector.x, 0, scaleWorkVector.z, 1, 1);
          vertex(scaleWorkVector.x, scaleWorkVector.y, scaleWorkVector.z, 1, 0);
          vertex(0, scaleWorkVector.y, scaleWorkVector.z, 0, 0);

          //LEFT
          vertex(0, 0, 0, 0, 1);
          vertex(0, 0, scaleWorkVector.z, 1, 1);
          vertex(0, scaleWorkVector.y, scaleWorkVector.z, 1, 0);
          vertex(0, scaleWorkVector.y, 0, 0, 0);

          //RIGHT
          vertex(scaleWorkVector.x, 0, 0, 0, 1);
          vertex(scaleWorkVector.x, 0, scaleWorkVector.z, 1, 1);
          vertex(scaleWorkVector.x, scaleWorkVector.y, scaleWorkVector.z, 1, 0);
          vertex(scaleWorkVector.x, scaleWorkVector.y, 0, 0, 0);

          endShape();

        popMatrix();
    popMatrix();
    popStyle();
  }

  float getScale() {
    return getXScale(); //Default to X scale for now, this is for grid spacers and sorting
  }

  float getXScale() {
    return map(scale, 0, maxFollowers, minXScale, maxXScale);
  }

  float getYScale() {
    return (scale / maxFollowers) * scaleYFactor;
  }

  float getZScale() {
    return getXScale(); //x and z are currently equal
  }

  PVector getMaxBounds() {
    return new PVector(position.x + getXScale(), position.y + getYScale(), position.z + getZScale());
  }

  int compareTo(Building b) {
    return (b.user.getFollowersCount() - this.user.getFollowersCount());
  }

  String toString() {
    return "Building{user:"+user.getScreenName()+", followersCount:"+user.getFollowersCount()+" scale:"+scale+", position:"+position+"}";
  }
}
