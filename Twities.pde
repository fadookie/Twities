import processing.opengl.*;
import javax.media.opengl.*;
import peasy.*;
import controlP5.*;
ControlP5 cp5;

boolean DEBUG = false;
boolean saveNextFrame = false;

PeasyCam camera;
long msCameraTweenTime = 1000;
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
ArrayList<Building> buildings = new ArrayList(); //Master list of buildings, sortable
HashMap<String, Building> buildingsByName = new HashMap(); //Index of buildings keyed by Twitter username
PVector cityCenter;
PVector citySize;
PVector maxCityBounds = new PVector();
PVector minCityBounds = new PVector();

ArrayList<Polygons> levelGeometry = new ArrayList();
PImage roadImage;
PImage[] grassImages;
int currentGrassImage = 0;

int maxFollowers; //How many followers the most popular user has
String messageString = null;
boolean searchMode = true;
String searchUsername = "";
Group searchGroup;
Textfield searchUsernameTextfield;
Bang searchUsernameButton;
//Bang searchHideButton;

//---------- Loading Functions ---------------//

void setup() {
  size(800,800, OPENGL);

  //Default processing camera perspective, but move the near clip plane in and far clip plane out
  float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
  perspective(PI/3.0, width/height, cameraZ/200.0, cameraZ*20.0);

  //Set up GUI
  cp5 = new ControlP5(this);
  searchGroup = cp5.addGroup("g1");

  searchUsernameTextfield = cp5.addTextfield("searchUsername");
  searchUsernameTextfield.setPosition(20, height - 50)
     .setSize(200,40)
     .setGroup(searchGroup)
     //.setFont(font)
     .setCaptionLabel("")
     //.setFocus(true)
     .setAutoClear(false)
     ;

  searchUsernameButton = cp5.addBang("search");
  searchUsernameButton.setPosition(240, height - 50)
     .setSize(80,40)
     .setGroup(searchGroup)
     .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
     ;    

  /*
  searchHideButton = cp5.addBang("x");
  searchHideButton.setPosition(340, height - 50)
     .setSize(40,40)
     .setGroup(searchGroup)
     .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
     ;    
 */
 
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
  {
    //Create them
    for (User user : following) {
      Building building = new Building(user);
      building.setAvatar(avatars.get(user)); //This might fail, we will fall back to color rendering
      buildings.add(building); //Will use natural sort order of Comparable<Building>
      buildingsByName.put(user.getScreenName().toLowerCase(), building); //Add building to index by screen name
    }

    //Sort list by follower count, descending
    Collections.sort(buildings);

    //Position buildings in outward spiral
    Building previousBuilding = null;
    Building legHeadBuilding = null;

    PVector spiralDirection = new PVector(1, 0, 0);
    PVector margin = new PVector(5, 0, 5);

    for (Building building : buildings) {
      if (legHeadBuilding == null) {
        //This must be the first building in natural sort order
        legHeadBuilding = building;
        maxFollowers = building.user.getFollowersCount(); //Careful, this must be set before calling building.getScale()
      }
      if (previousBuilding != null) {
        building.position = previousBuilding.position.get();

        //Biting my lip and creating a ton of garbage for the sake of clarity
        PVector offset = new PVector(previousBuilding.getXScale(), 0, previousBuilding.getZScale());
        offset.add(margin);
        offset.mult(spiralDirection); //This will cancel movement off the axis of the current spiral leg

        building.position.add(offset);

        //Rotate spiral direction if neccessary
        PVector buildingBounds = building.getMaxBounds();
        PVector oldBounds = previousBuilding.getMaxBounds();
        if (
               buildingBounds.x     < minCityBounds.x
            || building.position.x  > maxCityBounds.x
            || buildingBounds.z     < minCityBounds.z
            || building.position.z  > maxCityBounds.z
        ) {
          legHeadBuilding = building;

          PVector oldDirection = spiralDirection.get();
          spiralDirection.x = -oldDirection.z;
          spiralDirection.z = oldDirection.x;
          //println("rotate to " + spiralDirection);
        }
//        println("offset(" + offset + ") * spiralDirection(" + spiralDirection + ") = position("+building.position+")");
      }

      //println(building +" margin="+margin);

      previousBuilding = building;

      //Set our max bounds for camera centering later
      PVector buildingBounds = building.getMaxBounds();
      if (buildingBounds.x > maxCityBounds.x) maxCityBounds.x = buildingBounds.x;
      if (buildingBounds.z > maxCityBounds.z) maxCityBounds.z = buildingBounds.z;
      //Set our min bounds
      if (building.position.x < minCityBounds.x) minCityBounds.x = building.position.x;
      if (building.position.z < minCityBounds.z) minCityBounds.z = building.position.z;
    }

    printDelimiter(1);
  }
  println("prepared " + buildings.size() + " buildings.");

  //Set up camera/HUD stuff
  cityCenter = PVector.add(minCityBounds, maxCityBounds); 
  cityCenter.div(2);

  citySize = PVector.mult(minCityBounds, -1); //Treat minCityBounds as the origin, not sure if this math here is correct
  citySize.add(maxCityBounds);

  //println("citySize="+citySize+" cityCenter="+cityCenter);

  //Start looking at the center of the city
  camera = new PeasyCam(this, cityCenter.x, -40, cityCenter.z, 500/*distance*/);
  //camera.setMinimumDistance(-10);
  camera.setMaximumDistance(6500);

  messageString = null;
  
  //Load additional assets

  //grassImage = loadImage("grass"+round(random(1, 4))+".png");
  grassImages = new PImage[4];
  for (int i = 0; i < grassImages.length; i++) {
    grassImages[i] = loadImage("grass"+(i+1)+".png");
  }
  roadImage  = loadImage("road.png");

  {
    Quads roadTest = new Quads(roadImage);
    roadTest.addQuad(1, 10, minCityBounds, new PVector(100, 0, 2000));
    roadTest.addQuad(1, 10, maxCityBounds, new PVector(100, 0, 2000));
    levelGeometry.add(roadTest);
  }
}


//---------- Drawing Functions ---------------//

void draw() {
  PGraphicsOpenGL pgl = (PGraphicsOpenGL)g;

  background(color(112, 252, 255));

  //Draw ground
  hint(DISABLE_DEPTH_TEST); //Was getting some weird interlacing stuff, so i'm now drawing the ground in it's own depth buffer underneath the buildings at all times
  pushStyle();
  noStroke();
  fill(0);

  pushMatrix();

  //Just make the ground plane really large
  scale(1000, 0, 1000);

  beginShape(QUADS);
  pgl.textureSampling(Texture.LINEAR);
  pgl.textureWrap(Texture.REPEAT); //Set texture wrap mode to GL_REPEAT. See http://code.google.com/p/processing/issues/detail?id=94
  textureMode(NORMAL);
  texture(grassImages[currentGrassImage]);
  float textureScale = 90000;
  vertex(minCityBounds.x, 0, minCityBounds.z, 0, 0);
  vertex(maxCityBounds.x, 0, minCityBounds.z, textureScale, 0);
  vertex(maxCityBounds.x, 0, maxCityBounds.z, textureScale, textureScale);
  vertex(minCityBounds.x, 0, maxCityBounds.z, 0, textureScale);
  endShape();

  popMatrix();

  //Draw roads
  /*
  beginShape(QUADS);
  texture(roadImage);
  vertex(minCityBounds.x, 0, minCityBounds.z, 0, 0);
  vertex(1, 0, minCityBounds.z, 1, 0);
  vertex(1, 0, maxCityBounds.z, 1, 1);
  vertex(minCityBounds.x, 0, maxCityBounds.z, 0, 1);
  endShape();
  */

  //Draw "level geometry"
  for (Polygons p : levelGeometry) {
    p.draw();
  }

  popStyle();
  hint(ENABLE_DEPTH_TEST);

  pgl.textureSampling(Texture.BILINEAR);

  //Draw buildings
  /*
  for (Building building : buildings) {
    building.draw();
  }
  */

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

  //float[] position = camera.getPosition();
  //float[] rotations = camera.getRotations();
  //println(position);
  //println("rotX: " + degrees(rotations[0]) + ", rotY: " +degrees(rotations[1])+ ", rotZ: " +degrees(rotations[2]) + ", dist: " + camera.getDistance());
  //

  if (saveNextFrame) {
    saveNextFrame = false;
    //Note, this doesn't seem to work with Processing 0206
    saveFrame("screenshot-###.png"); 
  }
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
  if (!searchUsernameTextfield.isActive()) {
    if (CODED == key) {
    } else {
      switch(key) {
        case '/':
          toggleSearchMode();
          break;
        case 'd':
          DEBUG = !DEBUG;
          break;
        case 's':
          saveNextFrame = true;
          break;
        case '1':
        case '2':
        case '3':
        case '4':
          //Switch grass texture to texture 1-4 (stored in array items 0-3)
          currentGrassImage = Integer.parseInt(Character.toString(key)) - 1;
          break;
      }
    }
  }
}

void toggleSearchMode() {
  searchMode = !searchMode;
  if (searchMode) {
    searchGroup.hide();
    this.clear();
  } else {
    searchGroup.show();
    searchUsernameTextfield.setFocus(true);
  }
}

//---------- ControlP5 GUI Event Handlers ---------------//

public void search() {
  //Event handler for Search button being pressed
  searchUsernameTextfield.submit();
}

/*
public void x() {
  toggleSearchMode();
}
*/

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
    //The center is the actual center of the building, we want to center our camera on the top of the building so we use the Y scale. Remember to flip the sign since "up" in this city is the -Y axis
    camera.lookAt(center.x, -resultBuilding.getYScale(), center.z, msCameraTweenTime);
    camera.setRotations(radians(90), 0, 0);
    camera.setDistance(170, msCameraTweenTime);
    searchUsernameTextfield.setColor(color(255));
    searchUsernameTextfield.clear();
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
