class Building implements Comparable<Building> {
  Avatar avatar;
  User user;
  PVector position = new PVector();
  float scale = 1;
  float scaleFactor = 300;
  float minScale = 20;
  float maxScale = 50;

  Building(Avatar avatar) {
    this.avatar = avatar;
    user = avatar.user;
    scale = user.getFollowersCount();
  }

  void draw() {
    if (avatar.image != null) {
      float constrainedScale = getScale();
      pushMatrix();
        translate(position.x, position.y, position.z);

        pushMatrix();
          //Stupid box() is centered and there's no boxMode() I know of...
          translate(getXScale() / 2, getYScale() / 2, getZScale() / 2);
          box(getXScale(), getYScale(), getZScale());
        popMatrix();

        pushMatrix();
          //Draw the avatar on top of the box, for now.
          translate(0, getYScale() + 0.01, 0);

          beginShape();
          textureMode(NORMAL);
          texture(avatar.image);
          vertex(0, 0, 0, 0, 0);
          vertex(constrainedScale, 0, 0, 1, 0);
          vertex(constrainedScale, 0, constrainedScale, 1, 1);
          vertex(0, 0, constrainedScale, 0, 1);
          endShape();

        popMatrix();
        
        //image(avatar.image, 0, 0, constrainedScale, constrainedScale);
      popMatrix();
    }
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
