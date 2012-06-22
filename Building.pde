class Building implements Comparable<Building> {
  Avatar avatar;
  User user;
  PVector position = new PVector();
  float scale = 1;
  float scaleFactor = 300;
  float minScale = 20;
  float maxScale = 50;
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

    pushMatrix();
      translate(position.x, -position.y, position.z);

      pushMatrix();
        //Stupid box() is centered and there's no boxMode() I know of...
        translate(scaleWorkVector.x / 2, scaleWorkVector.y / 2, scaleWorkVector.z / 2);
        box(scaleWorkVector.x, scaleWorkVector.y, scaleWorkVector.z);
      popMatrix();

      if (avatar.image != null) {
        pushMatrix();
          //Draw the avatar on top of the box, for now.
          translate(0, scaleWorkVector.y - 0.01, 0);

          beginShape();
          textureMode(NORMAL);
          texture(avatar.image);
          vertex(0, 0, 0, 0, 0);
          vertex(scaleWorkVector.x, 0, 0, 1, 0);
          vertex(scaleWorkVector.x, 0, scaleWorkVector.z, 1, 1);
          vertex(0, 0, scaleWorkVector.z, 0, 1);
          endShape();

        popMatrix();
      }
      
      //image(avatar.image, 0, 0, constrainedScale, constrainedScale);
    popMatrix();
  }

  float getScale() {
    return getXScale(); //Default to X scale for now, this is for grid spacers and sorting
  }

  float getXScale() {
    return map(scale, 0, maxFollowers, minScale, maxScale);
  }

  float getYScale() {
    return (scale / maxFollowers) * scaleFactor;
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
