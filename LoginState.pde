/**
 * LoginState presents the user with a login prompt and obtains their OAuth token.
 * Once it has this, it switches to the LoadingState which will fetch data from the cache or the Twitter API.
 */
class LoginState implements GameState {
  Twitter twitter;
  RequestToken requestToken;

  ControlP5 cp5;
  Group loginGroup;
  Textfield pinField;

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
    //cb.setOAuthAccessToken(credentialsDecrypted[2]);
    //cb.setOAuthAccessTokenSecret(credentialsDecrypted[3]);

    //Make the twitter object
    twitter = new TwitterFactory(cb.build()).getInstance();

    //Obtain OAuth access token for user
    try {
      requestToken = twitter.getOAuthRequestToken();
      println("Got request token.");
      println("Request token: " + requestToken.getToken());
      println("Request token secret: " + requestToken.getTokenSecret());

      println("Open the following URL and grant access to your account:");
      println(requestToken.getAuthorizationURL());
      link(requestToken.getAuthorizationURL());
      print("Enter the PIN(if available) and hit enter after you granted access.[PIN]:");

    } catch (TwitterException te) {
      logLine("Twitter Exception: " + te);
      noLoop();
      exit();
    }

    //Set up GUI

    //Set up ControlP5
    cp5 = new ControlP5(getMainInstance());

    loginGroup = cp5.addGroup("g1");

    pinField = cp5.addTextfield("pin");
    pinField.setPosition((width/2) - (200/2), (height/2) - (40/2))
       .setSize(200,40)
       .setGroup(loginGroup)
       //.setFont(font)
       .setCaptionLabel("Login PIN from Twitter (if available)")
       //.setFocus(true)
       .setAutoClear(false)
       ;
  }

  void loginWithPin(String pin) {
    AccessToken accessToken = null;

    try {
      String filename = "twitter4j.properties";
      Properties prop = new Properties();

      OutputStream os = null;
      if (pin.length() > 0) {
          accessToken = twitter.getOAuthAccessToken(requestToken, pin);
      } else {
          accessToken = twitter.getOAuthAccessToken(requestToken);
      }
      if (accessToken != null) {
        println("Got access token.");
        println("Access token: " + accessToken.getToken());
        println("Access token secret: " + accessToken.getTokenSecret());

        try {
            prop.setProperty("oauth.accessToken", accessToken.getToken());
            prop.setProperty("oauth.accessTokenSecret", accessToken.getTokenSecret());
            os = createOutput(filename);
            if (null != os) {
              prop.store(os, "twitter4j.properties");
              os.close();
            }
        } catch (IOException ioe) {
            ioe.printStackTrace();
            noLoop();
            exit();
        } finally {
            if (os != null) {
                try {
                    os.close();
                } catch (IOException ignore) {
                }
            }
        }
        println("Successfully stored access token to " + filename + ".");
      }
    } catch (TwitterException te) {
        if (401 == te.getStatusCode()) {
            println("Unable to get the access token.");
        } else {
            te.printStackTrace();
        }
    }

    if (accessToken != null) {
      //Success!
      engineChangeState(new LoadingState(twitter));
    }
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
    background(66);

    //ControlP5 GUI
    cp5.draw();
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
    //Manually invoke the appropriate event
    if (pinField == theEvent.getController()) {
      loginWithPin(theEvent.getController().getStringValue().trim());
    } else {
      println("unrecognized event: " + theEvent);
    }
  }
}
