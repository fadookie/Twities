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
        translate(position.x, position.y);

        pushMatrix();
          //Stupid box() is centered and there's no boxMode() I know of...
          translate(getScale() / 2, getScale() / 2, getScale() / 2);
          box(getScale(), getScale(), getScale());
        popMatrix();

        pushMatrix();
          //Draw the avatar on top of the box, for now.
          translate(0, 0, getScale() + 0.01);

          beginShape();
          textureMode(NORMAL);
          texture(avatar.image);
          vertex(0, 0, 0, 0);
          vertex(constrainedScale, 0, 1, 0);
          vertex(constrainedScale, constrainedScale, 1, 1);
          vertex(0, constrainedScale, 0, 1);
          endShape();

        popMatrix();
        
        //image(avatar.image, 0, 0, constrainedScale, constrainedScale);
      popMatrix();
    }
  }

  float getScale() {
    return (scale / maxFollowers) * scaleFactor;//map(scale, 0, maxFollowers, minScale, maxScale);
  }

  PVector getMaxBounds() {
    return new PVector(position.x + getScale(), position.y + getScale());
  }

  int compareTo(Building b) {
    return (b.user.getFollowersCount() - this.user.getFollowersCount());
  }

  String toString() {
    return "Building{user:"+user.getScreenName()+", followersCount:"+user.getFollowersCount()+" scale:"+scale+", position:"+position+"}";
  }
}
