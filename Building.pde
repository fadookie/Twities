class Building implements Comparable<Building> {
  Avatar avatar;
  User user;
  PVector position = new PVector();
  float scale = 1;
  float scaleYFactor = 1000;
  float minXScale = 20;
  float maxXScale = 100;
  float windowScale = 4; //The higher this goes, the less the texture repeats on the bottom and side (i.e. the 'windows' get bigger and fewer)
  PVector scaleWorkVector = new PVector();

  Building(User user) {
    init(user, null);
  }

  Building(Avatar avatar) {
    init(avatar.user, avatar);
  }

  void setAvatar(Avatar avatar) {
    this.avatar = avatar; //might be null
  }

  void init(User user, Avatar avatar) {
    this.user = user;
    setAvatar(avatar);
    scale = user.getFollowersCount();
  }

  void draw() {
    //Cache scale so we don't need to do the calculations multiple times in a single draw call
    scaleWorkVector.x = getXScale();
    scaleWorkVector.y = -getYScale(); //-Y is the height from ground axis to simplify the drawing in OpenGL
    scaleWorkVector.z = getZScale();

    PVector windowTextureScale = PVector.div(scaleWorkVector, windowScale);
    windowTextureScale.y *= -1; //Invert Y axis since we want the V coordinate to be positive so the texture is right-side-up

    pushStyle();
    pushMatrix();
      translate(position.x, -position.y, position.z);

      beginShape(QUADS);

      if ((avatar != null) && (avatar.image != null)) {
          ((PGraphicsOpenGL)g).textureWrap(Texture.REPEAT); //Set texture wrap mode to GL_REPEAT. See http://code.google.com/p/processing/issues/detail?id=94
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
      vertex(scaleWorkVector.x, 0, 0, windowTextureScale.x, 0);
      vertex(scaleWorkVector.x, 0, scaleWorkVector.z, windowTextureScale.x, windowTextureScale.z);
      vertex(0, 0, scaleWorkVector.z, 0, windowTextureScale.z);

      //BACK
      vertex(0, 0, 0, 0, windowTextureScale.y);
      vertex(scaleWorkVector.x, 0, 0, windowTextureScale.x, windowTextureScale.y);
      vertex(scaleWorkVector.x, scaleWorkVector.y, 0, windowTextureScale.x, 0);
      vertex(0, scaleWorkVector.y, 0, 0, 0);

      //FRONT
      vertex(0, 0, scaleWorkVector.z, 0, windowTextureScale.y);
      vertex(scaleWorkVector.x, 0, scaleWorkVector.z, windowTextureScale.x, windowTextureScale.y);
      vertex(scaleWorkVector.x, scaleWorkVector.y, scaleWorkVector.z, windowTextureScale.x, 0);
      vertex(0, scaleWorkVector.y, scaleWorkVector.z, 0, 0);

      //LEFT
      vertex(0, 0, 0, 0, windowTextureScale.y);
      vertex(0, 0, scaleWorkVector.z, windowTextureScale.x, windowTextureScale.y);
      vertex(0, scaleWorkVector.y, scaleWorkVector.z, windowTextureScale.x, 0);
      vertex(0, scaleWorkVector.y, 0, 0, 0);

      //RIGHT
      vertex(scaleWorkVector.x, 0, 0, 0, windowTextureScale.y);
      vertex(scaleWorkVector.x, 0, scaleWorkVector.z, windowTextureScale.x, windowTextureScale.y);
      vertex(scaleWorkVector.x, scaleWorkVector.y, scaleWorkVector.z, windowTextureScale.x, 0);
      vertex(scaleWorkVector.x, scaleWorkVector.y, 0, 0, 0);

      endShape();

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

  PVector getCenterPosition() {
    return new PVector(
        position.x + (getXScale() / 2),
        position.y + (getYScale() / 2),
        position.z + (getZScale() / 2)
    );
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
