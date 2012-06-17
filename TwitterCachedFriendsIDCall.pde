class TwitterCachedFriendsIDCall implements TwitterCachedCall {
  String cacheFileName;
  String getCacheFileName() {
    return cacheFileName;
  }

  private Twitter twitter;
  private long userId;
  private boolean saveOnCacheMiss;
  
  TwitterCachedFriendsIDCall(Twitter t, long id, String cacheFileName, boolean saveOnCacheMiss) {
    userId = id;
    this.cacheFileName = cacheFileName;
    this.saveOnCacheMiss = saveOnCacheMiss;
    setTwitter(t);
  }

  void setTwitter(Twitter t) {
    twitter = t;
  }

  boolean saveOnCacheMiss() {
    return saveOnCacheMiss;
  }

  Serializable executeCall() {
    long cursor = -1; //If we get a paginated API response, keep track of our position
    IDs responseObject = null;
    try {
      do {
        responseObject = twitter.getFriendsIDs(userId, cursor);
      } while ((cursor = responseObject.getNextCursor()) != 0);
    } catch (TwitterException te) {
      logLine("Couldn't connect: " + te);
    }
    return responseObject;
  }
}
