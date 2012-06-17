class Building implements Comparable<Building> {
  Avatar avatar;
  User user;
  PVector position = new PVector();
  float scale = 1;
  float minScale = 20;
  float maxScale = 120;
  float followerCountForMaxScale = 13899;

  Building(Avatar avatar) {
    this.avatar = avatar;
    user = avatar.user;
    scale = user.getFollowersCount();
  }

  void draw() {
    if (avatar.image != null) {
      float constrainedScale = map(scale, 0, followerCountForMaxScale, minScale, maxScale);
      pushMatrix();
      translate(position.x, position.y);
      image(avatar.image, 0, 0, constrainedScale, constrainedScale);
      popMatrix();
    }
  }

  int compareTo(Building b) {
    return (b.user.getFollowersCount() - this.user.getFollowersCount());
  }

  String toString() {
    return "Building{user:"+user.getScreenName()+", followersCount:"+user.getFollowersCount()+" scale:"+scale+", position:"+position+"}";
  }
}
