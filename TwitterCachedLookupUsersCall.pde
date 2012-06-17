class TwitterCachedLookupUsersCall implements TwitterCachedCall {
  String cacheFileName;
  String getCacheFileName() {
    return cacheFileName;
  }

  private Twitter twitter;
  private long[] lookupIds;
  private boolean saveOnCacheMiss;
  
  TwitterCachedLookupUsersCall(Twitter t, long[] lookupIds, String cacheFileName, boolean saveOnCacheMiss) {
    this.lookupIds = lookupIds;
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
    ResponseList<User> users = null;

    long[][] lookupIdChunks = divideArray(lookupIds, 100);

    //Debugging - limit this to one API request.
    //long[][] lookupIdChunks = new long[1][];
    //lookupIdChunks[0] = Arrays.copyOfRange(lookupIds, 0, 100);

    for (long[] currentIdBatch : lookupIdChunks) {
      try {
        //Lookup users for following IDs
        ResponseList<User> userResponseBatch = twitter.lookupUsers(currentIdBatch);
        if (users == null) {
          users = userResponseBatch;
        } else {
          users.addAll(userResponseBatch);
        }
        for (User user : userResponseBatch) {
            if (user.getStatus() != null) {
                logLine("@" + user.getScreenName() + " - " + user.getStatus().getText());
            } else {
                // the user is protected
                logLine("@" + user.getScreenName());
            }
        }
        logLine("Successfully looked up users.");
      } catch (TwitterException te) {
        logLine("Couldn't connect: " + te);
      }
    }
    return users;
  }
}
