import peasy.*;

boolean DEBUG = false;

PeasyCam camera;
PVector cameraLookAt;
//Camera debug stuff
PVector  axisXHud = new PVector();
PVector  axisYHud = new PVector();
PVector  axisZHud = new PVector();
PVector  axisOrgHud = new PVector();

//Build an ArrayList to hold all of the words that we get from the imported tweets
CacheManager cacheManager = new CacheManager();
long rootUserId = -1;
IDs friendIds; 
ArrayList<User> following = new ArrayList();
HashMap<Long, User> users;
HashMap<User, Avatar> avatars = new HashMap();
TreeSet<Building> buildings = new TreeSet();
int maxFollowers = 0; //How many followers the most popular user has
String messageString = null;

//---------- Loading Functions ---------------//

void setup() {
  size(800,800, OPENGL);
  background(0);
 
  //Set up Twitter API Credentials
  ConfigurationBuilder cb = new ConfigurationBuilder();
  
  //We expect a config file containing newline-delimited consumer key, consumer secret, OAuth access token, and OAuth access token secret.
  String configFileName = "credentials.txt";
  String credentials[] = loadStrings(configFileName);
  if ((null == credentials) || (credentials.length < 4)) {
    logLine("Invalid config at " + configFileName);
    noLoop();
    exit();
  }
  //logLine("READ CREDENTIALS file " + configFileName + ":\n\n" + java.util.Arrays.asList(credentials));
  cb.setOAuthConsumerKey(credentials[0]);
  cb.setOAuthConsumerSecret(credentials[1]);
  cb.setOAuthAccessToken(credentials[2]);
  cb.setOAuthAccessTokenSecret(credentials[3]);

  //Read in the user name that will be at the center of our graph. TODO: retrieve OAuth token for this user dynamically.
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

  printDelimiter(1);

  //Load users from cache if available
  users = (HashMap<Long, User>)cacheManager.loadFromCache(cacheManager.cachePrefixForFile("users"));
  if (users == null) {
    users = new HashMap<Long, User>();
  }

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

  //Use set operations to pare list down to only uncached users
  //Stupid Java... we have to manually convert long to Long
  HashSet<Long> followingNotCached = new HashSet<Long>(followingMaster.length);
  for (long id : followingMaster)
  {
    followingNotCached.add(id);
  }
  followingNotCached.removeAll(users.keySet());
  
  if (followingNotCached.size() > 0) {
    //We need to request the info for some users that aren't in our cache.
    //First we need to convert the HashSet<Long> back to long[] :(
    long[] followingNotCachedArray = new long[followingNotCached.size()];
    {
      int i = 0;
      for (Long id : followingNotCached) {
        followingNotCachedArray[i] = id;
        i++;
      }
    }

    TwitterCachedLookupUsersCall lookupCall = new TwitterCachedLookupUsersCall(
        twitter,
        followingNotCachedArray,
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
      println("fetched user " + user.getId());
    }

    //Write new users map to cache
    printDelimiter(5);
    println("Writing updated users map to cache.");
    cacheManager.saveToCache(cacheManager.cachePrefixForFile("users"), users);
  }

  //Populate following list
  for (long id : friendIds.getIDs()) {
    User user = users.get(id);
    if (user != null) {
      following.add(user);
    } else {
      println("User " + id + " was null.");
    }
  }

  //Load avatars
  for (User user : following) {
    try {
      Avatar userAvatar = new Avatar(user);
      avatars.put(user, userAvatar);
    } catch (IOException e) {
      logLine("IOException when trying to load Avatar at " + user.getProfileImageURL().toString());
    }
  }

  //Create buildings
  PVector maxCityBounds = new PVector();
  {
    //Create them
    for (Avatar avatar : avatars.values()) {
      Building building = new Building(avatar);
      buildings.add(building); //Will use natural sort order of Comparable<Building>
    }
    //Position buildings
    Building previousBuilding = null;
    Building rowHeadBuilding = null;
    float margin = 5;
    float cityWidth = 500;
    for (Building building : buildings) {
      if (rowHeadBuilding == null) {
        //This must be the first building in natural sort order
        rowHeadBuilding = building;
        maxFollowers = building.user.getFollowersCount(); //Careful, this must be set before calling building.getScale()
      }
      if (previousBuilding != null) {
        PVector oldBounds = previousBuilding.getMaxBounds();
        if (oldBounds.x + margin + building.getXScale() <= cityWidth) {
          building.position.x = oldBounds.x + margin;
          building.position.z = previousBuilding.position.z;
          println("oB.x="+oldBounds.x+" margin="+margin+" scale="+building.getScale());
        } else {
          building.position.x = 0;
          building.position.z = rowHeadBuilding.getMaxBounds().z + margin;
          rowHeadBuilding = building;
          println("reset row");
        }
      }

      previousBuilding = building;

      //Set our max bounds for camera centering later
      PVector buildingBounds = building.getMaxBounds();
      if (buildingBounds.x > maxCityBounds.x) maxCityBounds.x = buildingBounds.x;
      if (buildingBounds.z > maxCityBounds.z) maxCityBounds.z = buildingBounds.z;
    }

    printDelimiter(1);
    println("prepared buildings.");
  }

  //Set up camera/HUD stuff
  cameraLookAt = PVector.div(maxCityBounds, 2); //Start looking at the center of the city

  camera = new PeasyCam(this, cameraLookAt.x, 0, cameraLookAt.z, 500/*distance*/);
  camera.setMinimumDistance(-10);
  camera.setMaximumDistance(Integer.MAX_VALUE);

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

  if (DEBUG) {
    calculateAxis(50); //For debug drawing
  }

  //HUD
  camera.beginHUD();
  if (messageString != null) {
    text(messageString, 0, height - 50);
  }
  if (DEBUG) {
    drawAxis(2);
  }
  camera.endHUD();
}

void calculateAxis(float length) {
   // Store the screen positions for the X, Y, Z and origin
   axisXHud.set( screenX(length,0,0), screenY(length,0,0), 0 );
   axisYHud.set( screenX(0,length,0), screenY(0,length,0), 0 );     
   axisZHud.set( screenX(0,0,length), screenY(0,0,length), 0 );
   axisOrgHud.set( screenX(0,0,0), screenY(0,0,0), 0 );
}

void drawAxis(float weight) {
   pushStyle();

     strokeWeight( weight );      // Line width

     stroke( 255,   0,   0 );     // X axis color (Red)
     line( axisOrgHud.x, axisOrgHud.y, axisXHud.x, axisXHud.y );
 
     stroke(   0, 255,   0 );
     line( axisOrgHud.x, axisOrgHud.y, axisYHud.x, axisYHud.y );

     stroke(   0,   0, 255 );
     line( axisOrgHud.x, axisOrgHud.y, axisZHud.x, axisZHud.y );


      fill(255);                   // Text color

      text( "X", axisXHud.x, axisXHud.y );
      text( "Y", axisYHud.x, axisYHud.y );
      text( "Z", axisZHud.x, axisZHud.y );

   popStyle();
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
