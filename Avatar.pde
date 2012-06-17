class Avatar {
  String url;
  User user;
  PImage image;

  Avatar(User user) throws IOException {
    this.user = user;
    this.url = user.getProfileImageURL().toString();

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
    return cacheManager.cachePrefix + "avatars/" + user.getId() + "." + extension;
  }
}
