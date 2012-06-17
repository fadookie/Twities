//Build an ArrayList to hold all of the words that we get from the imported tweets
CacheManager cacheManager = new CacheManager();
long rootUserId = -1;
IDs friendIds; 
HashMap<Long, User> users = new HashMap();
HashMap<User, Avatar> avatars = new HashMap();
TreeSet<Building> buildings = new TreeSet();
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

  String userFileName = "rootUser.txt";
  String rootUserName[] = loadStrings(userFileName);
  if ((null == rootUserName) || (rootUserName.length < 1)) {
    logLine("Invalid root user config file at " + userFileName);
    noLoop();
    exit();
  }

  try {
    rootUserId = Long.parseLong(rootUserName[0]);
  } catch (NumberFormatException nfe) {
    logLine("Invalid user ID number: " + rootUserName[0] + " exception: " + nfe);
    noLoop();
    exit();
  }

  logLine("READ USER CONFIG file " + userFileName + ", proceeding with root User ID " + rootUserId + "\n\n");
  
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
    TwitterCachedFriendsIDCall friendsIdCall = new TwitterCachedFriendsIDCall(
        twitter,
        rootUserId,
        cacheManager.cachePrefixForFile("followingIds", String.valueOf(rootUserId)),
        true /*save on cache miss*/
    );
    friendIds = (IDs)cacheManager.loadFromCacheOrRequest(friendsIdCall);

    if (friendIds != null) {
      logLine("Got " + friendIds.getIDs().length + " Friend IDs.");
    } else {
      logLine("Failed to get Friend IDs. :(");
      noLoop();
      exit();
    }

    //Get user info for following
    long[] followingMaster = friendIds.getIDs();

    TwitterCachedLookupUsersCall lookupCall = new TwitterCachedLookupUsersCall(
        twitter,
        followingMaster,
        cacheManager.cachePrefixForFile("lookupUsers"),
        false /*save on cache miss*/
    );
    ResponseList<User> usersResponse = (ResponseList<User>)cacheManager.loadFromCacheOrRequest(lookupCall);
    if (usersResponse != null) {
      logLine("Got " + usersResponse.size() + " usersResponse!");
    } else {
      logLine("No users were found.");
      noLoop();
      exit();
    }

    for (User user : usersResponse) {
      users.put(user.getId(), user);
    }

    //Load avatars
    for (User user : users.values()) {
      try {
        Avatar userAvatar = new Avatar(user);
        avatars.put(user, userAvatar);
      } catch (IOException e) {
        logLine("IOException when trying to load Avatar at " + user.getProfileImageURL().toString());
      }
    }

    //Create buildings
    {
      //Create them
      for (Avatar avatar : avatars.values()) {
        Building building = new Building(avatar);
        buildings.add(building); //Will use natural sort order of Comparable<Building>
      }
      //Position buildings
      int columns = 7;
      int xCounter = 0;
      int yCounter = 0;
      float spacer = 60;
      for (Building building : buildings) {
        //For now, arrange in a grid
        //println("x: " + xCounter % columns + " y: " + yCounter);
        building.position.x = spacer * (xCounter % columns);
        building.position.y = spacer * yCounter;
        xCounter++;
        if ((xCounter % columns) == (columns - 1)) {
          yCounter++;
        }
      }

      printDelimiter();
      println("prepared buildings:\n" + buildings);
    }

    messageString = null;
}


//---------- Drawing Functions ---------------//

void draw() {
  background(0);

  for (Building building : buildings) {
    //building.position.x += 0.01 * building.scale;
    //building.position.y += 0.01 * building.scale;
    building.draw();
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
