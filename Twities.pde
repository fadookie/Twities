void setup() {
  noLoop();

  ConfigurationBuilder cb = new ConfigurationBuilder();
  cb.setOAuthConsumerKey("lPFSpjBppo5u4KI5xEXaQ");
  cb.setOAuthConsumerSecret("SYt3e4xxSHUL1gPfM9bxQIq6Jf34Hln9T1q9KGCPs");
  cb.setOAuthAccessToken("17049577-Yyo3AEVsqZZopPTr055TFdySop228pKKAZGbJDtnV");
  cb.setOAuthAccessTokenSecret("6ZjJBebElMBiOOeyVeh8GFLsROtXXtKktXALxAT0I");
  
  Twitter twitter = new TwitterFactory(cb.build()).getInstance();
  
  Query query = new Query("#OWS");
  query.setRpp(100); //Set results per page
  
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
      }
  }
  catch (TwitterException te) {
    println("Couldn't connect: " + te);
  }
}

void printDelimiter() {
  printDelimiter(13);
}

void printDelimiter(numNewlines) {
  printNewlines(numNewlines);
  println("===================================================");
  printNewlines(numNewlines);
}

void printNewlines(int num) {
  for (int i = 0; i < num; i++) {
    print("\n");
  }
}
