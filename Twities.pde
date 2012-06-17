void setup() {
  noLoop();

  ConfigurationBuilder cb = new ConfigurationBuilder();
  cb.setOAuthConsumerKey("lPFSpjBppo5u4KI5xEXaQ");
  cb.setOAuthConsumerSecret("SYt3e4xxSHUL1gPfM9bxQIq6Jf34Hln9T1q9KGCPs");
  cb.setOAuthAccessToken("17049577-Yyo3AEVsqZZopPTr055TFdySop228pKKAZGbJDtnV");
  cb.setOAuthAccessTokenSecret("6ZjJBebElMBiOOeyVeh8GFLsROtXXtKktXALxAT0I");
  
  Twitter twitter = new TwitterFactory(cb.build()).getInstance();
}
