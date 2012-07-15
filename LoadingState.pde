/**
 * LoadingState fetches data from the cache or the Twitter API.
 * After it has finished loading, it will switch to VisualizerState.
 */
class LoadingState implements GameState {
  Twitter twitter;
  User authenticatedUser = null; //nullable

  LoadingState(Twitter t, User a) {
    twitter = t;
    authenticatedUser = a;
  }

  void setup() {
    //Read in the user name that will be at the center of our graph. TODO: retrieve OAuth token for this user dynamically.
    String userFileName = "rootUser.txt";
    String rootUserName[] = loadStrings(userFileName);
    if ((null == rootUserName) || (rootUserName.length < 1)) {
      println("No root user ID at " + userFileName + ", defaulting to currently authenticated user.");
    } else {
      try {
        rootUserId = Long.parseLong(rootUserName[0]);
      } catch (NumberFormatException nfe) {
        println("Invalid user ID number: " + rootUserName[0] + " exception: " + nfe);
      }

      logLine("READ USER CONFIG file " + userFileName + ", proceeding with root User ID " + rootUserId + "\n\n");
    }

    if(rootUserId < 0) {
      //Default to currently authenticated user if possible
      if (null != authenticatedUser) {
        rootUserId = authenticatedUser.getId();
      } else {
        fatalError("No config for root user found at " + userFileName + " and no user is currently authenticated.");
        return;
      }
    }

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
      fatalError("Failed to get Friend IDs. :(");
      return;
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
        fatalError("No users were found.");
        return;
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

    
    //Load additional assets

    //grassImage = loadImage("grass"+round(random(1, 4))+".png");
    grassImages = new PImage[4];
    for (int i = 0; i < grassImages.length; i++) {
      grassImages[i] = loadImage("grass"+(i+1)+".png");
    }
    roadImage  = loadImage("road.png");
    //testImage = loadImage("number.png");

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

      roads = new Quads(roadImage);

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

        {
          //Add upper horizontal road segment
          PVector roadPos = building.position.get();
          roadPos.z -= margin.z;

          PVector roadSize = new PVector();
          roadSize.x = margin.x + building.getXScale() + 0.15 /*add a bit on the end to hopefully close up any seams*/;
          roadSize.z = margin.z;

          roads.addQuad(TEX_DIRECTION_LEFT, 0, 0, 1, roadSize.x / roadVerticalTextureTileSize, roadPos, roadSize);
        }
        {
          //Add lower horizontal road segment
          PVector roadPos = building.position.get();
          roadPos.z += building.getZScale();

          PVector roadSize = new PVector();
          roadSize.x = margin.x + building.getXScale() + 0.15 /*add a bit on the end to hopefully close up any seams*/;
          roadSize.z = margin.z;

          roads.addQuad(TEX_DIRECTION_LEFT, 0, 0, 1, roadSize.x / roadVerticalTextureTileSize, roadPos, roadSize);
        }
        {
          //Add right vertical road segment
          PVector roadPos = building.position.get();
          roadPos.x += building.getXScale();

          PVector roadSize = new PVector();
          roadSize.x = margin.x;
          roadSize.z = margin.z + building.getZScale();

          roads.addQuad(TEX_DIRECTION_FORWARD, 0, 0, 1, roadSize.z / roadVerticalTextureTileSize, roadPos, roadSize);
        }
        {
          //Add left vertical road segment
          PVector roadPos = building.position.get();
          roadPos.x -= margin.x;
          roadPos.z -= margin.z;

          PVector roadSize = new PVector();
          roadSize.x = margin.x;
          roadSize.z = (margin.z * 2) + building.getZScale() + 0.15;

          roads.addQuad(TEX_DIRECTION_FORWARD, 0, 0, 1, roadSize.z / roadVerticalTextureTileSize, roadPos, roadSize);
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

    engineChangeState(new VisualizerState());
  }

  void cleanup() {
  }

  void pause() {
  }

  void resume(GameState previousState) {
  }

  void update(float deltaTime) {
  }

  void draw() {
  }

  void mouseDragged() {
  }

  void mousePressed() {
  }

  void mouseReleased() {
  }

  void keyPressed() {
  }

  void keyReleased() {
  }

  void controlEvent(ControlEvent theEvent) {
  }
}
