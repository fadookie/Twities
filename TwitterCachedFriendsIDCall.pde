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
