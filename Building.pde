class Building {
  Avatar avatar;
  User user;
  PVector position = new PVector();
  float scale = 1;

  Building(Avatar avatar) {
    this.avatar = avatar;
    user = avatar.user;
    scale = user.getFollowersCount();
  }

  void draw() {
    if (avatar.image != null) {
      pushMatrix();
      translate(position.x, position.y);
      image(avatar.image, 0, 0, scale, scale);
      popMatrix();
    }
  }
}
