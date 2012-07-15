import processing.opengl.*;
import javax.media.opengl.*;
import peasy.*;
import controlP5.*;
ControlP5 cp5;

boolean DEBUG = false;
boolean saveNextFrame = false;

/** Stack to hold the game states in use.
 * Please don't access this directly, use the engine state functions. */
Stack<GameState> states = new Stack();
float lastUpdateTimeMs = Float.MIN_VALUE;

PeasyCam camera;
long msCameraTweenTime = 1000;
//Camera debug stuff
PVector  axisXHud = new PVector();
PVector  axisYHud = new PVector();
PVector  axisZHud = new PVector();
PVector  axisOrgHud = new PVector();

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

Quads roads;
PImage roadImage;
float roadVerticalTextureTileSize = 10;
//PImage testImage;
PImage[] grassImages;
int currentGrassImage = 0;

static final int TEX_DIRECTION_BACK = 1;
static final int TEX_DIRECTION_RIGHT = 2;
static final int TEX_DIRECTION_FORWARD = 3;
static final int TEX_DIRECTION_LEFT = 4;

int maxFollowers; //How many followers the most popular user has
String messageString = null;

//---------- Loading Functions ---------------//

void setup() {
  size(800,800, OPENGL);

  //Set up ControlP5
  cp5 = new ControlP5(this);

  engineChangeState(new LoginState());
}

//---------- Drawing Functions ---------------//

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

void mouseDragged() {
  engineGetState().mouseDragged();
}

void mousePressed() {
  engineGetState().mousePressed();
}

void mouseReleased() {
  engineGetState().mouseReleased();
}

void keyPressed() {
  engineGetState().keyPressed();
}

void keyReleased() {
  engineGetState().keyReleased();
}

void controlEvent(ControlEvent theEvent) {
  engineGetState().controlEvent(theEvent);
}

//---------- Game State Handling Functions ---------------//

/**
 * Update and draw game state
 */
void draw() {
  float deltaTime = millis() - lastUpdateTimeMs;
  engineGetState().update(deltaTime);
  lastUpdateTimeMs = millis();

  engineGetState().draw();
}


GameState engineGetState() {
  if (!states.isEmpty()) {
    return (GameState)states.peek();
  } 
  else {
    return null;
  }
}

void engineChangeState(GameState state) {
  //Cleanup current state
  if (!states.isEmpty()) {
    GameState currentState = (GameState)states.peek();
    currentState.cleanup();
    states.pop();
  }

  //Store and setup new state
  states.push(state);
  state.setup();
}

void enginePushState(GameState state) {
  //Cleanup current state
  if (!states.isEmpty()) {
    GameState currentState = (GameState)states.peek();
    currentState.pause();
  }

  //Store and setup new state
  states.push(state);
  state.setup();
}

void enginePopState() {
  GameState previousState = null;
  //Cleanup current state
  if (!states.isEmpty()) {
    GameState currentState = (GameState)states.peek();
    currentState.cleanup();
    previousState = currentState;
    states.pop();
  }

  //Resume previous state
  if (!states.isEmpty()) {
    GameState currentState = (GameState)states.peek();
    currentState.resume(previousState);
  }
}

/**
 * Clear the state stack in reverse order, 
 */
void engineResetToState(GameState state) {
  //Empty out current state stack, giving each state a chance to run cleanup()
  if (!states.isEmpty()) {
    for (int i = states.size(); i > 0;) {
      GameState currentState = (GameState)states.peek();
      currentState.cleanup();
      states.pop();
      i = states.size();
    }
  }

  engineChangeState(state);
}

void stop() {
  //Let the states clean up
  while (engineGetState() != null) {
    enginePopState();
  }
  super.stop();
}

/**
 * Return a reference to the main PApplet instance for this sketch.
 * Where in a normal Processing sketch you might initialize a library
 * from the main class like so:
 * Fisica.init(this);
 * When initializing a library from a GameState, you need to do:
 * Fisica.init(getMainInstance());
 * */
PApplet getMainInstance() {
  return this;
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
