import java.awt.Robot;
import java.awt.AWTException;
import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import controlP5.*; 
import processing.serial.*; 
import java.util.StringTokenizer; 
import java.awt.event.KeyEvent; 

import java.util.*;
import java.util.Map.Entry;
import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.nio.file.Files;
import java.io.FilenameFilter;
import java.util.Arrays;
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 
import java.util.Properties;
//public class GRemote extends PApplet {

  // GRemoteCNC - mini host interfacing with Arduino GCode Interpreter

  // Setup, event loops and state

  // Global variables
  boolean DEBUG = false;
  String extention = ".wy";
  String sketchPath, dataPath;
  ArrayList<File> knownDisks;
  File currentSelectedCNCFile;

  int PLATEFORM;
  final int UNKNOW = -1;
  final int OSX = 0 ;
  final int WINDOWS = 1 ; 
  final int LINUX = 2 ; 

  ControlP5 cP5;
  Serial port = null;
  int baudrate = 115200;
  EnumXYZ idx = new EnumXYZ();

  int resolution = 100000; // of a unit, for fixed-point calculations;
  int position[]; // absolute
  int jog[]; // relative
  int accumulated_jog[]; // relative

  int memory[]; // absolute
  boolean memorySet[];

  float feed[];
  float feedInc = 1*1000; // mm
  float lastFeed = 0;

  float homing_limit[]; // absolute
  float homingInfinity = 100*25; // mm
  float homingFeed = 10*25; // mm/min

  float arc_radius = 5; // current units
  float arc_start = 0; // degrees
  float arc_end = 360; // degrees
  boolean ArcCCW = false; // direction

  int x_dir_pin = 11;
  int x_step_pin = 10;
  int x_min_pin = 17;
  int x_max_pin = 18;
  int y_dir_pin = 8;
  int y_step_pin = 9;
  int y_min_pin = 13;
  int y_max_pin = 12;
  int z_dir_pin = 4;
  int z_step_pin = 5;
  int z_min_pin = 14;
  int z_max_pin = 15;
  float x_steps_per_mm = 40.0f;
  float y_steps_per_mm = 40.0f;
  float z_steps_per_mm = 40.0f;

  int i;
  float f;
  Robot robot;
  // State flags
  boolean PortWasReset = false;
  boolean PortResponding = false;
  boolean WaitingForResponse = false;
  boolean HaveStringToSend = false;

  boolean SendingSequence = false;
  boolean Paused = false;
  boolean SequenceLastLineSent = false;

  boolean G_AbsoluteMode = true;
  boolean G_InchMode = false;

  boolean RapidPositioning = false;
  boolean FractionalJog = false;
  boolean HomingSetZero = true;

  boolean UI_ReloadJogDDL = false;
  boolean UI_ReloadArcTF = false;
  boolean UI_ClearGCodeTF = false;
  boolean UI_ClearFocusTF = false;

  boolean ArcMode = false;
  boolean XYZMode = false;
  boolean ZeroMode = false;
  boolean MemMode = false;

  public boolean sketchFullScreen() {
    switch(getPlateform()){
      case OSX : {
        return false;
      }
      case LINUX : {
        return true;
      }
    }
    return false;
  }

  public void settings() {
    //size(800, 480);
  }

  // setup
  public void setup() {

    size(800, 480);
    if(PLATEFORM != OSX){
      noCursor();  
    }
    
    smooth();
    sketchPath = args[0] +"/GRemote";
    dataPath = sketchPath+"/data";
    
    cP5 = new ControlP5(this);
    cP5.setColorForeground(color(255, 100));
    cP5.setColorBackground(color(255, 64));
    //cP5.setColorLabel(0xffdddddd);
    //cP5.setColorValue(0xff88ff88);
    cP5.setColorActive(color(255, 200));


    position = new int[idx.size()];
    jog = new int[idx.size()];
    accumulated_jog = new int[idx.size()];
    memory = new int[idx.size()];
    memorySet = new boolean[idx.size()];
    feed = new float[idx.size()];
    homing_limit = new float[idx.size()];

    // init
    for (int i=0; i<idx.size(); i++) {
      position[i] = 0;
      jog[i] = resolution;
      accumulated_jog[i] = 0;
      memorySet[i] = false;
      feed[i] = 10*250;  // mm/min
      homing_limit[i] = 0;
    }

    setup_file_import();
    setup_file_list(width-10-170, 10, 170, height-20);
    setup_func_buttons(220, 215);
    setup_console(10, 45, 200, 160);  
    setup_toggles(10, 240);
    setup_jog_controls(10, 315, 30); 
    setup_setting_controls(10, 305, 60); 
    setup_jog_buttons(220, 10);
    setup_port_led(10, 10);
    setup_port_selector(30, 10, 170, 130); 
    try{
      robot = new Robot();
    } catch (AWTException e) {}
  }

  // draw loop
  public void draw() { 
    background(0);
    if(frameCount % 30 == 0 ){
      update_file_import();
      update_file_list();
    }
    if(PLATEFORM != OSX && frameCount % 10 == 0 ){
      moveCursor();
    }

    update_console();
    update_port_led();
    update_toggles(); 
    update_func_buttons(); 
    update_jog_buttons();
    update_jog_controls();
    update_port_selector();
    update_setting_controls();
    update_textfields(); // manage textfields focus
    update_groups(); // manage groups
  }
/*
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "GRemote" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
*/
