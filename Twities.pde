//Build an ArrayList to hold all of the words that we get from the imported tweets
ArrayList<String> words = new ArrayList();
IDs friendIds; 
ResponseList<User> users;
HashMap<User, Avatar> avatars = new HashMap();
String messageString = null;

//---------- Loading Functions ---------------//

void setup() {
  size(800,800, OPENGL);
  background(0);
 
  //Credentials
  ConfigurationBuilder cb = new ConfigurationBuilder();
  
  //We expect a config file containing newline-delimited consumer key, consumer secret, OAuth access token, and OAuth access token secret.
  String configFileName = "credentials.txt";
  String credentials[] = loadStrings(configFileName);
  if ((null == credentials) || (credentials.length < 4)) {
    logLine("Invalid config at " + configFileName);
    noLoop();
    exit();
  }
  logLine("READ CREDENTIALS file " + configFileName + ":\n\n" + java.util.Arrays.asList(credentials));
  cb.setOAuthConsumerKey(credentials[0]);
  cb.setOAuthConsumerSecret(credentials[1]);
  cb.setOAuthAccessToken(credentials[2]);
  cb.setOAuthAccessTokenSecret(credentials[3]);

  int eliotId = 156560059;
  int porpId = 70665746;
  int rootUserId = porpId;
  
    //Make the twitter object
    Twitter twitter = new TwitterFactory(cb.build()).getInstance();

    //Get follower IDs
    /*
    IDs followerIds;
    {
      long cursor = -1; //If we get a paginated API response, keep track of our position
      logLine("Listing followers's ids.");
      do {
          followerIds = twitter.getFollowersIDs(rootUserId, cursor);
          for (long id : followerIds.getIDs()) {
              //System.out.format("%d\n", id);
          }
          logLine("Got Follower IDs: " + followerIds.getIDs().length);
      } while ((cursor = followerIds.getNextCursor()) != 0);
    }
    */

    printDelimiter(1);

    //Get following IDs
    TwitterCachedFriendsIDCall friendsIdCall = new TwitterCachedFriendsIDCall(twitter, rootUserId, "followingIds.bin");
    friendIds = (IDs)loadFromCacheOrRequest(friendsIdCall);

    if (friendIds != null) {
      logLine("Got " + friendIds.getIDs().length + " Friend IDs.");
    } else {
      logLine("Failed to get Friend IDs. :(");
      noLoop();
      exit();
    }

    //Get user info for following
    long[] followingMaster = friendIds.getIDs();

    TwitterCachedLookupUsersCall lookupCall = new TwitterCachedLookupUsersCall(twitter, followingMaster, "lookupUsers.bin");
    users = (ResponseList<User>)loadFromCacheOrRequest(lookupCall);
    if (users != null) {
      logLine("Got " + users.size() + " users!");
    } else {
      logLine("No users were found.");
      noLoop();
      exit();
    }

    //Load avatars
    for (User user : users) {
      try {
        Avatar userAvatar = new Avatar(user);
        //for now, randomize placement
        userAvatar.position.x = random(width);
        userAvatar.position.y = random(height);
        avatars.put(user, userAvatar);
      } catch (IOException e) {
        logLine("IOException when trying to load Avatar at " + user.getProfileImageURL().toString());
      }
    }

    messageString = null;
}

/**
 * Attempts to load a TwitterCachedCall from a local file on disk, and if the local file doesn't exist, it attempts to perform the call and cache the results in the missing file.
 *
 * @return Object|null The object returned from the request. null if there was a failure.
 */
Object loadFromCacheOrRequest(TwitterCachedCall call) {
  Serializable responseObject = null;
  String cacheFileName = "data/" + call.getCacheFileName();

  //Try to load the response from the cache
  InputStream fis = createInput(cacheFileName);
  if (fis != null) {
    try {
      ObjectInputStream ois = new ObjectInputStream(fis);
      responseObject = (Serializable)ois.readObject();
      ois.close();
      fis.close();
      logLine("Successful cache load from " + cacheFileName);
    } catch (Exception e) {
      logLine("Exception deserializing cache at " + cacheFileName);
    }
  }

  if (responseObject == null) {
    //Cache miss, perform the actual API call
    logLine("Executing API call: " + call);
    responseObject = call.executeCall();

    if (responseObject != null) {
      //Cache the response
      OutputStream fos = createOutput(cacheFileName);
      if (fos != null) {
        try {
          ObjectOutputStream oos = new ObjectOutputStream(fos);
          oos.writeObject(responseObject);
          oos.close();
          fos.close();
          logLine("Wrote " + call + " to cache at " + cacheFileName);
        } catch (IOException ioe) {
          logLine("IOException writing " + call + " to cache file at " + cacheFileName
              + ". Exception: " + ioe.getMessage());
        }
      }
    } else {
      logLine("API call " + call + " failed and no cache is available.");
    }
  }
  return responseObject;
}

//---------- Drawing Functions ---------------//

void draw() {
  for (Avatar avatar : avatars.values()) {
    avatar.position.x += 0.01 * avatar.scale;
    avatar.position.y += 0.01 * avatar.scale;
    avatar.draw();
  }

  if (messageString != null) {
    text(messageString, 0, height - 50);
  }
}

//---------- Utility Functions ---------------//

long[][] divideArray(long[] source, int chunksize) {


        long[][] ret = new long[(int)Math.ceil(source.length / (double)chunksize)][chunksize];

        int start = 0;

        for(int i = 0; i < ret.length; i++) {
            ret[i] = java.util.Arrays.copyOfRange(source,start, start + chunksize);
            start += chunksize ;
        }

        return ret;
}

void logLine(String message) {
  //messageString = message; //TODO: display loading to user somehow
  println(message);
}

void printDelimiter() {
  printDelimiter(13);
}

void printDelimiter(int numNewlines) {
  printNewlines(numNewlines);
  println("===================================================");
  printNewlines(numNewlines);
}

void printNewlines(int num) {
  for (int i = 0; i < num; i++) {
    print("\n");
  }
}
