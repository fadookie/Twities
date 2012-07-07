import peasy.*;
import controlP5.*;
ControlP5 cp5;

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
ArrayList<Building> buildings = new ArrayList();
HashMap<String, Building> buildingsByName = new HashMap();
int maxFollowers = 0; //How many followers the most popular user has
String messageString = null;
boolean searchMode = false;
String searchUsername = "";
Textfield searchUsernameTextfield;
Bang searchUsernameButton;

//---------- Loading Functions ---------------//

void setup() {
  size(800,800, OPENGL);

  //Default processing camera perspective, but move the near clip plane in
  float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
  perspective(PI/3.0, width/height, cameraZ/200.0, cameraZ*10.0);

  //Set up GUI
  cp5 = new ControlP5(this);
  searchUsernameTextfield = cp5.addTextfield("searchUsername");
  searchUsernameTextfield.setPosition(20, height - 50)
     .setSize(200,40)
     //.setFont(font)
     .setFocus(true)
     .setAutoClear(false)
     ;

  searchUsernameButton = cp5.addBang("search");
  searchUsernameButton.setPosition(240, height - 50)
     .setSize(80,40)
     .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
     ;    
 
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

  //Add root user to so we can make sure we have their user data cached
  followingNotCached.add(rootUserId);

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

  //Add root user so they are on the graph
  following.add(users.get(rootUserId));

  println("Loaded " + following.size() + " following users.");

  //Load avatars
  for (User user : following) {
    try {
      Avatar userAvatar = new Avatar(user);
      avatars.put(user, userAvatar);
    } catch (IOException e) {
      logLine("IOException when trying to load Avatar at " + user.getProfileImageURL().toString());
    }
  }

  println("Loaded " + avatars.size() + " avatars.");

  //Create buildings
  PVector maxCityBounds = new PVector();
  {
    //Create them
    for (User user : following) {
      Building building = new Building(user);
      building.setAvatar(avatars.get(user)); //This might fail, we will fall back to color rendering
      buildings.add(building); //Will use natural sort order of Comparable<Building>
      buildingsByName.put(user.getScreenName().toLowerCase(), building); //Add building to index by screen name
    }
    Collections.sort(buildings);
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
          //println("oB.x="+oldBounds.x+" margin="+margin+" scale="+building.getScale());
        } else {
          building.position.x = 0;
          building.position.z = rowHeadBuilding.getMaxBounds().z + margin;
          rowHeadBuilding = building;
          //println("reset row");
        }
      }

      previousBuilding = building;

      //Set our max bounds for camera centering later
      PVector buildingBounds = building.getMaxBounds();
      if (buildingBounds.x > maxCityBounds.x) maxCityBounds.x = buildingBounds.x;
      if (buildingBounds.z > maxCityBounds.z) maxCityBounds.z = buildingBounds.z;
    }

    printDelimiter(1);
  }
  println("prepared " + buildings.size() + " buildings.");

  //Set up camera/HUD stuff
  cameraLookAt = PVector.div(maxCityBounds, 2); //Start looking at the center of the city

  camera = new PeasyCam(this, cameraLookAt.x, 0, cameraLookAt.z, 500/*distance*/);
  //camera.setMinimumDistance(-10);
  camera.setMaximumDistance(6500);

  messageString = null;
}


//---------- Drawing Functions ---------------//

void draw() {
  background(240);

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
  //Clear depth buffer so the HUD is guaranteed to be on top
  hint(DISABLE_DEPTH_TEST); 
  if (messageString != null) {
    text(messageString, 0, height - 50);
  }
  if (DEBUG) {
    drawAxis(2);
  }

  //ControlP5 GUI
  cp5.draw();

  hint(ENABLE_DEPTH_TEST);
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

//---------- Input Handling Functions ---------------//

void keyPressed() {
  if (CODED == key) {
  } else {
    if ('/' == key) {
      searchMode = true;
    }
  }
}

//---------- ControlP5 GUI Event Handlers ---------------//

public void search() {
  //Event handler for Search button being pressed
  searchUsernameTextfield.submit();
}

public void clear() {
  searchUsernameTextfield.setColor(color(255));
  searchUsernameTextfield.clear();
}

public void searchUsername(String screenName) {
  // event handler for searchUsername being submitted
  tryHighlightUser(screenName.trim());
}

void tryHighlightUser(String screenName) {
  Building resultBuilding = buildingsByName.get(screenName.toLowerCase());
  if (null != resultBuilding) {
    PVector center = resultBuilding.getCenterPosition();
    camera.lookAt(center.x, center.y, center.z);
    searchUsernameTextfield.setColor(color(255));
  } else {
    searchUsernameTextfield.setText(screenName);
    searchUsernameTextfield.setColor(color(255, 0, 0));
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
