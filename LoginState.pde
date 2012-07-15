/**
 * LoginState presents the user with a login prompt and obtains their OAuth token.
 * Once it has this, it switches to the LoadingState which will fetch data from the cache or the Twitter API.
 */
class LoginState implements GameState {
  Twitter twitter;
  User authenticatedUser = null;
  RequestToken requestToken;
  String propFilename = "twitter4j.properties";
  String accessTokenPropName = "oauth.accessToken";
  String accessSecretPropName = "oauth.accessTokenSecret";
  Properties prop = new Properties();

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

    if ((null == credentials) || (credentials.length < 2) || DEBUG) {
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

    if ((null == credentialsDecrypted) || (credentialsDecrypted.length < 2)) {
      fatalError("Invalid config at " + configFileName);
      return;
    }

    //logLine("READ CREDENTIALS file " + configFileName + ":\n\n" + java.util.Arrays.asList(credentials));
    cb.setOAuthConsumerKey(credentialsDecrypted[0]);
    cb.setOAuthConsumerSecret(credentialsDecrypted[1]);


    //First, try to retrieve stored OAuth token
    InputStream is = createInput(propFilename);
    boolean requestNewToken = true;
    if (is != null) {
      try {
        prop.load(is);
        String accessTokenString = prop.getProperty(accessTokenPropName);
        String accessTokenSecretString = prop.getProperty(accessSecretPropName);
        if (null != accessTokenString && null != accessTokenSecretString ) {
          requestNewToken = false;
          println("found old token");
          cb.setOAuthAccessToken(accessTokenString);
          cb.setOAuthAccessTokenSecret(accessTokenSecretString);
        }
      } catch (IOException ioe) {
        println("IOException reading file " + propFilename + " : " + ioe);
      }
    }

    //Make the twitter object
    twitter = new TwitterFactory(cb.build()).getInstance();

    //Validate stored token
    requestNewToken = !isUserValid();
    println((requestNewToken ? "invalid" : "valid") + " credentials");

    //Obtain new OAuth access token for user if needed
    if (requestNewToken) {
      try {
        requestToken = twitter.getOAuthRequestToken();
        println("Got request token.");
        println("Request token: " + requestToken.getToken());
        println("Request token secret: " + requestToken.getTokenSecret());

        //println("Open the following URL and grant access to your account:");
        //println(requestToken.getAuthorizationURL());
        link(requestToken.getAuthorizationURL());

      } catch (TwitterException te) {
        //Skip authorization in case we have the data cached already
        if (te.isCausedByNetworkIssue()) {
          println("Encountered network issue, proceeding anyway.");
        } else {
          println("Unknown Twitter API error when trying to authenticate" + (DEBUG ? ". Please check that your consumer key and secret are valid in " + configFileName : "" ) + ". Proceeding anyway.");
        }
        goToLoadState();
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
    } else {
      goToLoadState();
    }
  }

  boolean isUserValid() {
    boolean valid = false;
    try {
      authenticatedUser = twitter.verifyCredentials();
      valid = true;
    } catch (Exception e) {
      println("Verify credentials failed : " +  e);
      twitter.setOAuthAccessToken(null);
    }
    return valid;
  }

  void goToLoadState() {
      engineChangeState(new LoadingState(twitter, authenticatedUser));
  }

  void loginWithPin(String pin) {
    AccessToken accessToken = null;

    try {
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
            prop.setProperty(accessTokenPropName, accessToken.getToken());
            prop.setProperty(accessSecretPropName, accessToken.getTokenSecret());
            os = createOutput(propFilename);
            if (null != os) {
              prop.store(os, "twitter4j.properties");
              os.close();
            }
          println("Successfully stored access token to " + propFilename + ".");
        } catch (IOException ioe) {
            ioe.printStackTrace();
            println("Error saving OAuth token to " + propFilename);
        } finally {
            if (os != null) {
                try {
                    os.close();
                } catch (IOException ignore) {
                }
            }
        }
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
      isUserValid(); //Update authenticatedUser
      goToLoadState();
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
    if (CODED == key) {
    } else {
      if ('v' == key) {
        if (commandKeyDown) {
          String clipboard = getClipboardString();
          if (null != clipboard) {
            pinField.setText(clipboard);
            pinField.setFocus(true);
          }
        }
      }
    }
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
