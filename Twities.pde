//Build an ArrayList to hold all of the words that we get from the imported tweets
ArrayList<String> words = new ArrayList();

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

  int rootUserId = 156560059;//70665746;
  
  try {
    //Make the twitter object
    Twitter twitter = new TwitterFactory(cb.build()).getInstance();
    

    IDs followerIds;
    {
      long cursor = -1; //If we get a paginated API response, keep track of our position
      println("Listing followers's ids.");
      do {
          followerIds = twitter.getFollowersIDs(rootUserId, cursor);
          for (long id : followerIds.getIDs()) {
              System.out.format("%d\n", id);
          }
          println("Got Follower IDs: " + followerIds.getIDs().length);
      } while ((cursor = followerIds.getNextCursor()) != 0);
    }

    printDelimiter();
    IDs followingIds;
    {
      long cursor = -1; //If we get a paginated API response, keep track of our position
      System.out.println("Listing following ids.");
      do {
          followingIds = twitter.getFriendsIDs(rootUserId, cursor);
          for (long id : followingIds.getIDs()) {
              System.out.format("%d\n", id);
          }
          println("Got Friend IDs: " + followingIds.getIDs().length);
      } while ((cursor = followingIds.getNextCursor()) != 0);
    }



    /*
    //Prepare the query
    Query query = new Query("#20FactsAboutMe");
    query.setRpp(100); //Set results per page
  
    //Try making the query
    QueryResult result = twitter.search(query);
    printDelimiter(1);
    println("GOT RESPONSE:\n\n"+result);
    printDelimiter();
    
    List<Tweet> tweets = result.getTweets();
    for (int i = 0; i < tweets.size(); i++) {
      Tweet t = tweets.get(i);
      String user = t.getFromUser();
      String msg = t.getText();
      Date d = t.getCreatedAt();
      println("Tweet by " + user + " at " + d + ": " + msg);
      
      //Break the tweet into words      
      String[] input = msg.split(" ");
      for (int j = 0;  j < input.length; j++) {
       //Put each word into the words ArrayList
       words.add(input[j]);
      }
    }
    */

  }
  catch (TwitterException te) {
    println("Couldn't connect: " + te);
  }

  noLoop();
}

void draw() {
  //Draw a faint black rectangle over what is currently on the stage so it fades over time.
  fill(0,1);
  rect(0,0,width,height);
 
  //Draw a word from the list of words that we've built
  if (words.size() > 0) {
    int i = (frameCount % words.size());
    String word = words.get(i);
   
    //Put it somewhere random on the stage, with a random size and colour
    fill(255,random(50,150));
    textSize(random(10,30));
    text(word, random(width), random(height));
  }
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
