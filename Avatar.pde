class Avatar {
  String url;
  float scale;
  User user;
  PImage image;

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
      println("Got image from " + user.getProfileImageURL());
      image.save(cacheLocation);
      println("Saved image to " + cacheLocation);
    } else {
      println("Got image from cache at " + cacheLocation);
    }
  }

  String getCacheLocation() {
    String[] components = url.split("\\.");
    //println("url: " +url+ " components: " + components + " length : " + components.length);
    String extension = (components.length > 0) ? components[components.length - 1] : "";
    return "data/avatars/" + user.getId() + "." + extension;
  }
}
