class Avatar {
  String url;
  float scale;
  User user;
  PImage image;
  PVector position = new PVector();

  Avatar(User user) throws IOException {
    this.user = user;
    this.url = user.getProfileImageURL().toString();
    scale = user.getFollowersCount();

    String cacheLocation = getCacheLocation();
    image = loadImage(cacheLocation);
    if (image == null) {
      //Cache miss
      image = loadImage(url);
      if (image == null) {
        throw new IOException();
      }
      logLine("Got image from " + user.getProfileImageURL());
      image.save(cacheLocation);
      logLine("Saved image to " + cacheLocation);
    } else {
      logLine("Got image from cache at " + cacheLocation);
    }
  }

  String getCacheLocation() {
    String[] components = url.split("\\.");
    //logLine("url: " +url+ " components: " + components + " length : " + components.length);
    String extension = (components.length > 0) ? components[components.length - 1] : "";
    return cachePrefix + "avatars/" + user.getId() + "." + extension;
  }

  void draw() {
    if (image != null) {
      pushMatrix();
      translate(position.x, position.y);
      image(image, 0, 0, scale, scale);
      popMatrix();
    }
  }
}
