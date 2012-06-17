class TwitterCachedFriendsIDCall implements TwitterCachedCall {
  String cacheFileName;
  String getCacheFileName() {
    return cacheFileName;
  }

  private Twitter twitter;
  private int userId;
  
  TwitterCachedFriendsIDCall(Twitter t, int id, String cacheFileName) {
    userId = id;
    this.cacheFileName = cacheFileName;
    setTwitter(t);
  }

  void setTwitter(Twitter t) {
    twitter = t;
  }

  Serializable executeCall() {
    return executeCall(-1);
  }

  Serializable executeCall(long cursor) {
    IDs responseObject = null;
    try {
      do {
        responseObject = twitter.getFriendsIDs(userId, cursor);
      } while ((cursor = responseObject.getNextCursor()) != 0);
    } catch (TwitterException te) {
      println("Couldn't connect: " + te);
    }
    return responseObject;
  }
}
