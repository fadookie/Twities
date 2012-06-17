//Build an ArrayList to hold all of the words that we get from the imported tweets
ArrayList<String> words = new ArrayList();
IDs friendIds; 
ResponseList<User> users;

//---------- Loading Functions ---------------//

void setup() {
  size(550,550);
  background(0);
  smooth();
 
  //Credentials
  ConfigurationBuilder cb = new ConfigurationBuilder();
  
  //We expect a config file containing newline-delimited consumer key, consumer secret, OAuth access token, and OAuth access token secret.
  String configFileName = "credentials.txt";
  String credentials[] = loadStrings(configFileName);
  if ((null == credentials) || (credentials.length < 4)) {
    println("Invalid config at " + configFileName);
    noLoop();
    exit();
  }
  println("READ CREDENTIALS file " + configFileName + ":\n\n" + java.util.Arrays.asList(credentials));
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
      println("Listing followers's ids.");
      do {
          followerIds = twitter.getFollowersIDs(rootUserId, cursor);
          for (long id : followerIds.getIDs()) {
              //System.out.format("%d\n", id);
          }
          println("Got Follower IDs: " + followerIds.getIDs().length);
      } while ((cursor = followerIds.getNextCursor()) != 0);
    }
    */

    printDelimiter(1);

    //Get following IDs
    TwitterCachedFriendsIDCall friendsIdCall = new TwitterCachedFriendsIDCall(twitter, rootUserId, "followingIds.bin");
    friendIds = (IDs)loadFromCacheOrRequest(friendsIdCall);

    if (friendIds != null) {
      println("Got " + friendIds.getIDs().length + " Friend IDs.");
    } else {
      println("Failed to get Friend IDs. :(");
      noLoop();
      exit();
    }

    //Get user info for following
    long[] followingMaster = friendIds.getIDs();

    TwitterCachedLookupUsersCall lookupCall = new TwitterCachedLookupUsersCall(twitter, followingMaster, "lookupUsers.bin");
    users = (ResponseList<User>)loadFromCacheOrRequest(lookupCall);
    if (users != null) {
      println("Got " + users.size() + " users!");
    } else {
      println("No users were found.");
      noLoop();
      exit();
    }

    noLoop();
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
      println("Successful cache load from " + cacheFileName);
    } catch (Exception e) {
      println("Exception deserializing cache at " + cacheFileName);
    }
  }

  if (responseObject == null) {
    //Cache miss, perform the actual API call
    System.out.println("Executing API call: " + call);
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
          println("Wrote " + call + " to cache at " + cacheFileName);
        } catch (IOException ioe) {
          println("IOException writing " + call + " to cache file at " + cacheFileName
              + ". Exception: " + ioe.getMessage());
        }
      }
    } else {
      println("API call " + call + " failed and no cache is available.");
    }
  }
  return responseObject;
}

//---------- Drawing Functions ---------------//

void draw() {
  //Draw a faint black rectangle over what is currently on the stage so it fades over time.
  fill(0,1);
  rect(0,0,width,height);

  if (users != null) {
    for (User user : users) {
      //Put it somewhere random on the stage, with a random size and colour
      fill(255,random(50,150));
      textSize(random(10,30));
      text(user.getScreenName(), random(width), random(height));
    }
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
