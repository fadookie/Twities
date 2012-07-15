/**
 * LoginState presents the user with a login prompt and obtains their OAuth token.
 * Once it has this, it switches to the LoadingState which will fetch data from the cache or the Twitter API.
 */
class LoginState implements GameState {
  void setup() {
    //Set up Twitter API Credentials
    ConfigurationBuilder cb = new ConfigurationBuilder();
    
    //We expect a config file containing newline-delimited consumer key, consumer secret, OAuth access token, and OAuth access token secret.
    String configFileName = "credentials-prod.txt";
    String credentials[] = loadStrings(configFileName);
    String credentialsDecrypted[] = null;

    if ((null == credentials) || (credentials.length < 4) || DEBUG) {
      println("No production config found at " + configFileName + " or DEBUG mode set, checking for dev config.");
      configFileName = "credentials-dev.txt";
      //Dev config is not encrypted
      credentialsDecrypted = loadStrings(configFileName);
      CryptoHelper cryptoHelper = new CryptoHelper();
      String[] credentialsEncrypted = cryptoHelper.encryptCredentials(credentialsDecrypted);
      printDelimiter(1);
      println("Here are your encrypted credentials for " + configFileName + " : \n");
      for (String credential : credentialsEncrypted) {
        println(credential);
      }
      printDelimiter(1);
    } else {
      //Decrypt credentials-prod.txt
      CryptoHelper cryptoHelper = new CryptoHelper();
      credentialsDecrypted = cryptoHelper.decryptCredentials(credentials);
    }

    if ((null == credentialsDecrypted) || (credentialsDecrypted.length < 4)) {
      logLine("Invalid config at " + configFileName);
      noLoop();
      exit();
    }

    //logLine("READ CREDENTIALS file " + configFileName + ":\n\n" + java.util.Arrays.asList(credentials));
    cb.setOAuthConsumerKey(credentialsDecrypted[0]);
    cb.setOAuthConsumerSecret(credentialsDecrypted[1]);
    cb.setOAuthAccessToken(credentialsDecrypted[2]);
    cb.setOAuthAccessTokenSecret(credentialsDecrypted[3]);

    //Make the twitter object
    Twitter twitter = new TwitterFactory(cb.build()).getInstance();

    //Obtain OAuth access token for user
    /*
    try {
      RequestToken requestToken = twitter.getOAuthRequestToken();
      println("Got request token.");
      println("Request token: " + requestToken.getToken());
      println("Request token secret: " + requestToken.getTokenSecret());
      AccessToken accessToken = null;
    } catch (TwitterException te) {
      logLine("Twitter Exception: " + te);
      noLoop();
      exit();
    }
    */

    engineChangeState(new LoadingState(twitter));
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
