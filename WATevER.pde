import tramontana.library.*;
import websockets.*;
import processing.video.*;
import processing.sound.*;
// import gifAnimation.*; // GIF Player
// import ddf.minim.*; // Sound Fade Effect

// Imported Files
PImage wheel, pushCupBelow, bigPicture;
PImage[] countryInfo = new PImage[14];
SoundFile file, waterFilling, backgroundMusic;
Movie waterDrop, wave, pointer;
PFont Faro;

// State-Related Variables
String state = "init"; // init > waiting > spinning > flowing > ending
int selectedCountry = 0;
final String[] countries = { "nepal","niger","norway","yemen","haiti","italy","bhutan","gabon","ghana","peru","india","chile","uganda","mexico" };
float wheelDegree, wheelDegreeNow, wheelStep = 0;
int isCupCountdown = 0;
boolean isWaterFlowDelay, isWaterFlow = false;
int waterFlowCountdown, waterFlowStartTime, waterFlowStopTime = 0;
int bigPictureEndTime = 0;

// Tramontana t;
// WebsocketServer ws;
int now = 0;
// float[] joints = {0,0,0,0};

// Setting
final int fps = 30;
final boolean isTramontana = false;
final boolean isWebSocket = false;

// Parameters
final int waterFlowDelayTime = 40; // unit: frame
final int[] waterFlowLastTime = {45000, 30000, 15000}; // unit: millisecond
final int bigPictureLastTime = 15000; // unit: millisecond

void setup()
{   
  fullScreen();
  // size(1920,1800);
  frameRate(fps);
  
  // External Connection
  // if(isTramontana) t = new Tramontana(this,"10.0.1.2");
  // if(isWebSocket) ws = new WebsocketServer(this,8025,"");
  
  // Import Images
  wheel = loadImage("piechart02.png");
  pushCupBelow = loadImage("pushCupBelow.png");
  bigPicture = loadImage("other-country-2.png");
  for(int i=0; i<14; i++)
  {
    String s = countries[i] + ".png";
    countryInfo[i] = loadImage(s);
  }
  
  // Import Sounds
  waterFilling = new SoundFile(this, "water-filling.wav");
  backgroundMusic = new SoundFile(this, "mainBG.wav");
  backgroundMusic.loop();

  // Import Videos
  waterDrop = new Movie(this, "water-drop.mp4");
  waterDrop.loop();
  pointer = new Movie(this, "pointer.mp4");
  pointer.loop();
  wave = new Movie(this, "wave.mp4");
  wave.loop();
  
  // Import Font
  // Faro = createFont("Faro-DisplayLucky.otf", 120);
}

void draw(){
  background(0);  
  // checkIsCup();

  // Draw Visual Objects
  drawWheel();
  
  if(state == "init")
  {
    image(waterDrop, 850, 870, 220, 220);
  }
  else if(state == "waiting")
  {
    image(pointer, 885, 940, 150, 150);
    image(pushCupBelow, 710, 825);
  }
  else if(state == "flowing")
  {
    pumpAction();
    if(!isWaterFlowDelay) // Water Flow Delay
    {
      image(countryInfo[selectedCountry], 0, 117, 1920, 963);
      image(wave, 545, 515); 
      // image(wave, 535, 575);
      // drawWaterFlowPercentage();
    }
  }
  else if(state == "ending")
  {
    image(bigPicture, 0, 117, 1920, 963);
    int n = millis();
    if(n > bigPictureEndTime)
    {
      reset();
      state = "init";
    }
  }
  // Web Socket Reception
  // if(isWebSocket)
  // {
  //   if(millis()>now+5000)
  //   {
  //     ws.sendMessage("Server message");
  //     now=millis();
  //   }
  // }
}

void keyPressed() { 
  if(keyCode == UP && state == "waiting") // Cup Detection
  {
    // isCupCountdown = 10;
    state = "flowing";
    // Water Flow Delay
    isWaterFlowDelay = true;
    waterFlowCountdown = waterFlowDelayTime;
  }
  else if(key == ' ' && wheelDegree == wheelDegreeNow) // Check if Wheel is not spining
  {
    spinWheel();
  }
  else if(isTramontana) // Pump Control, ON[e] OFF[d]
  {
    // if     (key=='e') t.setRelayEmbeddedOn(1);
    // else if(key=='d') t.setRelayEmbeddedOff(1);
  }
}

void drawWheel() {
  pushMatrix();
  translate(960, 1080.5);
  if(state == "spinning")
  {
    if((wheelDegreeNow + wheelStep) > wheelDegree)
    {
      wheelDegreeNow = wheelDegree;
      state = "waiting";
    }
    else
    {
      wheelDegreeNow += wheelStep;
    }
  }
  rotate(radians(wheelDegreeNow));
  image(wheel, -830.5, -830.5, 1661, 1661);
  popMatrix();
}

void drawWaterFlowPercentage()
{
  String s = str(int(float(millis()-waterFlowStartTime)*100/float(waterFlowStopTime-waterFlowStartTime)));
  textFont(Faro);
  textAlign(CENTER, BOTTOM);
  fill(125, 210, 200);
  text(s+"%", 695, 600);
}


void checkIsCup() { 
  if(isCupCountdown > 0)
  {
    isCupCountdown -= 1;
    if(isCupCountdown == 0)
    {
      isCupCountdown = 0;
    }
  }
}

void spinWheel()
{
  if(state == "waiting")
  {
    reset();
    state = "init";
  }
  if(state == "init")
  {
    selectedCountry = int(random(14));
    wheelDegree += (720.0+(360.0/14)*float(selectedCountry));
    wheelStep = (720.0+(360.0/14)*float(selectedCountry))/40;
    state = "spinning";
    // Play Spinning Sound
    file = new SoundFile(this, "spinning.mp3");
    file.play();
  }
}

void pumpAction()
{
  if(isWaterFlowDelay) // Water Flow Delay Countdown
  {
    waterFlowCountdown -= 1;
    if(waterFlowCountdown <= 0)
    {
      isWaterFlowDelay = false;
      waterFlowStart();
    }
    return;
  }
  int n = millis();
  if(n > waterFlowStopTime) // Flow End
  {
    waterFilling.stop();
    // if(isTramontana) t.setRelayEmbeddedOff(1);
    state = "ending";
    bigPictureEndTime = n + bigPictureLastTime;
  }
}

void waterFlowStart()
{
  int n = selectedCountry;
  int m = 0;
  if     (n == 2 || n == 5 || n == 11)                               m = waterFlowLastTime[0]; // norway, italy, chile
  else if(n == 6 || n == 7 || n == 9 || n == 10 || n == 13)          m = waterFlowLastTime[1]; // bhutan, gabon, peru, india, mexico
  else if(n == 0 || n == 1 || n == 3 || n == 4 || n == 8 || n == 12) m = waterFlowLastTime[2]; // nepal, niger, yemen, haiti, ghana, uganda
  waterFlowStartTime = millis();
  waterFlowStopTime = waterFlowStartTime + m;
  waterFilling.play();
  // Pump Starts
  // if(isTramontana) t.setRelayEmbeddedOn(1);
}

void reset() {
  // Reset Wheel Degree
  wheelDegree = 0; 
  wheelDegreeNow = 0;
  selectedCountry = 0;
  isWaterFlow = false;
  isWaterFlowDelay = false;
}

void movieEvent(Movie m) // For Playing Movie
{
  m.read();
}
