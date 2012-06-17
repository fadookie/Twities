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
  
  //Make the twitter object
  Twitter twitter = new TwitterFactory(cb.build()).getInstance();
  
  //Prepare the query
  Query query = new Query("#20FactsAboutMe");
  query.setRpp(100); //Set results per page
  
  //Try making the query
  try {
    QueryResult result = twitter.search(query);
    printDelimiter(1);
    println("GOT RESPONSE:\n\n"+result);
    printDelimiter();
    
    ArrayList tweets = (ArrayList)result.getTweets();
    for (int i = 0; i < tweets.size(); i++) {
      Tweet t = (Tweet)tweets.get(i);
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

  }
  catch (TwitterException te) {
    println("Couldn't connect: " + te);
  }
}

void draw() {
  //Draw a faint black rectangle over what is currently on the stage so it fades over time.
  fill(0,1);
  rect(0,0,width,height);
 
  //Draw a word from the list of words that we've built
  int i = (frameCount % words.size());
  String word = words.get(i);
 
  //Put it somewhere random on the stage, with a random size and colour
  fill(255,random(50,150));
  textSize(random(10,30));
  text(word, random(width), random(height));
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
