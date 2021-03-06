// cP5 UI events
  public void moveCursor(){
	  if(PLATEFORM != OSX){
      robot.mouseMove(width, height);
    }
  }


  public void controlEvent(ControlEvent theEvent) {
    boolean RenderZero = false;
    String s = "";
    int arc_offset;
    int j[] = new int[idx.size()];
    for (int i=0; i<idx.size(); i++)
      j[i] = 0;  // clear temp array

    if(theEvent.isFrom("menu")){
      moveCursor();
      Map m = ((MenuList)theEvent.getController()).getCurrentItem();
      if(m!= null){
        currentSelectedCNCFile = (File)m.get("cncFile");
        Button b = cP5.get(Button.class, "IMG");
        PImage img = (PImage)m.get("jpgFile");
        img.resize(b.getWidth(), 0);
        b.setImages(img, img, img);
      }
      return ;
    }

    // because only permitted (for current state) elements are available in the UI,
    // we assume that if we received an event, we can handle it without checking state
    // the above is not true for keypresses, where state has to be explicitly checked before handling event
    if (theEvent.getName().equals("PORT")) {
      moveCursor();
      if (port != null) port.stop();
      try { 
        port = new Serial(this, Serial.list()[(int)theEvent.getValue()], baudrate);
      }
      catch (Exception e) {
        console_println(": can't open selected port!");
      }
      clear_console();
      PortWasReset = true;
      PortResponding = false;
      WaitingForResponse = false;
      println("port open: " + Serial.list()[(int)theEvent.getValue()]);
      port.bufferUntil('\n');
      port.write("\r\n");
      return;
    }

    for (int i=0; i<jog_dec_name.length; i++) {
      if(theEvent.getName().equals("Z "+jog_dec_name[i])){
        moveCursor();
        jog[idx.Z] = intCoord(jog_dec_value[(int)theEvent.getValue()]);
        //      println(jog[idx.Z]);
        // store current jog dropdown values - workaround to enable inc/dec of jog values with keyboard shortcut (dropdownlist doesn't seem to have .setValue)
        jog_ddl_idx[idx.Z] = (int)theEvent.getValue(); 
        return;
      }
      if(theEvent.getName().equals("Y "+jog_dec_name[i])){
        moveCursor();
        jog[idx.Y] = intCoord(jog_dec_value[(int)theEvent.getValue()]);
        //      println(jog[idx.Y]);
        // store current jog dropdown values - workaround to enable inc/dec of jog values with keyboard shortcut (dropdownlist doesn't seem to have .setValue)
        jog_ddl_idx[idx.Y] = (int)theEvent.getValue(); 
        return;
      }
      if(theEvent.getName().equals("X "+jog_dec_name[i])){
        moveCursor();
        jog[idx.X] = intCoord(jog_dec_value[(int)theEvent.getValue()]);
        //      println(jog[idx.X]);
        // store current jog dropdown values - workaround to enable inc/dec of jog values with keyboard shortcut (dropdownlist doesn't seem to have .setValue)
        jog_ddl_idx[idx.X] = (int)theEvent.getValue();
        return;
      }
    }
    /*
    // jog setting selected
    if (theEvent.getName()=="JOG X") {
      moveCursor();
      i = (int)theEvent.getValue();
      jog[idx.X] = intCoord(FractionalJog ? jog_frac_value[i] : jog_dec_value[i]);
      //      println(jog[idx.X]);
      // store current jog dropdown values - workaround to enable inc/dec of jog values with keyboard shortcut (dropdownlist doesn't seem to have .setValue)
      jog_ddl_idx[idx.X] = i; 
      jog_ddl_frac[idx.X] = FractionalJog;
      return;
    }
    if (theEvent.getName()=="JOG Y") {
      moveCursor();
      i = (int)theEvent.getValue();
      jog[idx.Y] = intCoord(FractionalJog ? jog_frac_value[i] : jog_dec_value[i]);
      //      println(jog[idx.Y]);
      // store current jog dropdown values - workaround to enable inc/dec of jog values with keyboard shortcut (dropdownlist doesn't seem to have .setValue)
      jog_ddl_idx[idx.Y] = i; 
      jog_ddl_frac[idx.Y] = FractionalJog;
      return;
    }
    if (theEvent.getName()=="JOG Z") {
      moveCursor();
      i = (int)theEvent.getValue();
      jog[idx.Z] = intCoord(FractionalJog ? jog_frac_value[i] : jog_dec_value[i]);
      //      println(jog[idx.Z]);
      // store current jog dropdown values - workaround to enable inc/dec of jog values with keyboard shortcut (dropdownlist doesn't seem to have .setValue)
      jog_ddl_idx[idx.Z] = i; 
      jog_ddl_frac[idx.Z] = FractionalJog;
      return;
    }
    */
    if (theEvent.isGroup()) { 
      moveCursor();
      
      if (theEvent.getGroup().getName()=="GROUP_SETTING") {
        if (theEvent.getGroup().isOpen()) {
          open_group('S');
        }
      }
      return;
    }

    if (theEvent.isController()) { 
      moveCursor();
      //    print("control event from controller: "+theEvent.getController().getName());
      //    println(", value : "+theEvent.getController().getValue());

      // manually entered command
      if (theEvent.getController().getName() == "GCODE") {
        s = theEvent.getController().getStringValue().toUpperCase();
        HaveStringToSend = true; // UI_ClearFocusTF = true;
      }
      
      // send file button
      if (theEvent.getController().getName() == "START") {
        if(currentSelectedCNCFile != null && currentSelectedCNCFile.exists()){
          send_file(currentSelectedCNCFile);
        }else{
          console_println("NO FILE SELECTED");
        }
        //selectInput("Select GCode file to send", "send_file");
        //      String file = selectInput("Select GCode file to send");
        //      if (file == null) return;
        //      send_file(file);
        return;
      }

       // cancel (sending file) button
      if (theEvent.getController().getName() == "CANCEL") {
        console_println(": send sequence cancelled");
        SendingSequence = false;
        Paused = false;
        cancel_file();
        
        return;
      }

      // pause/resume (sending file) button
      if (theEvent.getController().getName() == "PAUSE/RESUME") {
        if (!Paused) {
          console_println(": send sequence paused");
          Paused = true;
        } else {
          console_println(": send sequence resumed");
          Paused = false;
          send_next_line();
        }
        return;
      }

      if (theEvent.getController().getName() == "REMOVE") {
        MenuList menu = cP5.get(MenuList.class, "menu");
        menu.removeCurrentItem();
        currentSelectedCNCFile = null;
        Button b = cP5.get(Button.class, "IMG");
        PImage img = new PImage();
        b.setImages(img, img, img);
        return;
      }

      if (theEvent.getController().getName() == "REMOVE ALL") {
        MenuList menu = cP5.get(MenuList.class, "menu");
        menu.removeAllItem();
        currentSelectedCNCFile = null;
        Button b = cP5.get(Button.class, "IMG");
        PImage img = new PImage();
        b.setImages(img, img, img);
        return;
      }

      if (theEvent.getController().getName() == "NEXT") {
        MenuList menu = cP5.get(MenuList.class, "menu");
        menu.next();
        return;
      }
      if (theEvent.getController().getName() == "PREV") {
        MenuList menu = cP5.get(MenuList.class, "menu");
        menu.prev();
        return;
      }

      if (theEvent.getController().getName() == "POWER OFF") {
        
        try{
          console_println("POWER OFF");
          Runtime.getRuntime().exec("shutdown -h now");
          console_println("OK");
          System.exit(0);
        }catch (IOException e) {
          console_println("ERROR : POWER OFF");          
        }
        return;
      }
      
      if (theEvent.getController().getName() == "SAVE") {

        String[] settingData={"Setting", 
          ((Textfield)cP5.getController("X_DIR_PIN")).getText(), 
          ((Textfield)cP5.getController("X_STEP_PIN")).getText(), 
          ((Textfield)cP5.getController("X_MIN_PIN")).getText(), 
          ((Textfield)cP5.getController("X_MAX_PIN")).getText(), 
          ((Textfield)cP5.getController("Y_DIR_PIN")).getText(), 
          ((Textfield)cP5.getController("Y_STEP_PIN")).getText(), 
          ((Textfield)cP5.getController("Y_MIN_PIN")).getText(), 
          ((Textfield)cP5.getController("Y_MAX_PIN")).getText(), 
          ((Textfield)cP5.getController("Z_DIR_PIN")).getText(), 
          ((Textfield)cP5.getController("Z_STEP_PIN")).getText(), 
          ((Textfield)cP5.getController("Z_MIN_PIN")).getText(), 
          ((Textfield)cP5.getController("Z_MAX_PIN")).getText(), 
          ((Textfield)cP5.getController("X_PER_MM")).getText(), 
          ((Textfield)cP5.getController("Y_PER_MM")).getText(), 
          ((Textfield)cP5.getController("X_PER_MM")).getText()};
        
        saveStrings(sketchPath+"/setting.ini", settingData);
        init_sequence();
        return;
      }
     
      /*
      // jog control toggles
      if (theEvent.getController().getName() == "fractional_jog") {
        if ((int)theEvent.getController().getValue() == 1)
          FractionalJog = true;
        else 
          FractionalJog = false;
        UI_ReloadJogDDL = true;
      }
      */
      if (theEvent.getController().getName() == "rapid_positioning") {
        if ((int)theEvent.getController().getValue() == 1)
          RapidPositioning = true;
        else { 
          RapidPositioning = false; 
          lastFeed = 0;
        }
      }

      if (theEvent.getController().getName() == "FEED X") { 
        feed[idx.X] = theEvent.getController().getValue();
      }
      if (theEvent.getController().getName() == "FEED Y") { 
        feed[idx.Y] = theEvent.getController().getValue();

      }
      if (theEvent.getController().getName() == "FEED Z") { 
        feed[idx.Z] = theEvent.getController().getValue();
      }

      if (theEvent.getController().getName() == "arc_mode") {
        if (XYZMode || ZeroMode || MemMode) return; //UI should be locked instead of state check
        if ((int)theEvent.getController().getValue() == 1) {
          ArcMode = true;
        } else {
          ArcMode = false;
        }
        open_group(ArcMode? 'A':'J');
      }

      if (theEvent.getController().getName() == "xyz_mode") {
        if (ArcMode || ZeroMode || MemMode) return; //UI should be locked instead of state check
        if ((int)theEvent.getController().getValue() == 1) {
          for (i=0; i<accumulated_jog.length; i++) accumulated_jog[i] = 0;        
          XYZMode = true;
        } else {
          int jog_total = 0;
          for (i=0; i<accumulated_jog.length; i++) jog_total += abs(accumulated_jog[i]);
          if (jog_total > 0) {
            s = jog_string(accumulated_jog, G_AbsoluteMode, false);
            HaveStringToSend = true;
          }
          XYZMode = false;
          UI_ClearGCodeTF = true;
        }
      }

      if (theEvent.getController().getName() == "zero_mode") {
        if (ArcMode || XYZMode || MemMode) return; //UI should be locked instead of state check
        if ((int)theEvent.getController().getValue() == 1) {
          ZeroMode = true;
        } else {
          ZeroMode = false;
          UI_ClearGCodeTF = true;
        }
      }
      /*
    if(theEvent.getController().getName() == "mem_mode") {
       if (ArcMode || XYZMode || ZeroMode) return; //UI should be locked instead of state check
       if ((int)theEvent.getController().getValue() == 1) {
       MemMode = true;
       }
       else {
       MemMode = false;
       UI_ClearGCodeTF = true;
       }
       }
       */

      // homing controls
      if (theEvent.getController().getName() == "homing_set_zero") {
        if ((int)theEvent.getController().getValue() == 1) HomingSetZero = true;
        else HomingSetZero = false;
      }
      //    println("raw: "+homing_limit[idx.X] + ", ceil: "+ceil(100*homing_limit[idx.X]) + ", floor: "+floor(100*homing_limit[idx.X]) );
      if (theEvent.getController().getName() == "homing_limit_x") homing_limit[idx.X] = theEvent.getController().getValue();
      if (theEvent.getController().getName() == "homing_limit_y") homing_limit[idx.Y] = theEvent.getController().getValue();
      if (theEvent.getController().getName() == "homing_limit_z") homing_limit[idx.Z] = theEvent.getController().getValue();
      // fix for values returned by controller - they often have many decimals (accumulated errors from float/double additions/subtractions?)
      for (i = 0; i<idx.size(); i++) homing_limit[i] = (homing_limit[i]>=0)? floor(homing_limit[i]*100)/100.0f : ceil(homing_limit[i]*100)/100.0f;
      if (theEvent.getController().getName() == "homing_infinity") homingInfinity = theEvent.getController().getValue();
      if (theEvent.getController().getName() == "homing_feed") homingFeed = theEvent.getController().getValue();
      // home XY & Z buttons
      if (theEvent.getController().getName() == "HOME XY") {
        homing_sequence("XY");
      }
      if (theEvent.getController().getName() == "HOME Z") {
        homing_sequence("Z");
      }    

      // arc controls
      if (theEvent.getController().getName() == "ARC_CCW") {
        if ((int)theEvent.getController().getValue() == 1) ArcCCW = true;
        else ArcCCW = false;
      }
      if (theEvent.getController().getName() == "ARC_RADIUS") {
        f = arc_radius;
        arc_radius = isFloat(theEvent.getController().getStringValue()) ? Float.parseFloat(theEvent.getController().getStringValue()) : arc_radius; 
        if (arc_radius <=0) arc_radius = f;
        UI_ReloadArcTF = true;
        UI_ClearFocusTF = true;
      }
      if (theEvent.getController().getName() == "ARC_START") {
        f = arc_start;
        arc_start = isFloat(theEvent.getController().getStringValue()) ? Float.parseFloat(theEvent.getController().getStringValue()) : arc_start; 
        if (arc_start <0 || arc_start >= 360 || arc_start >= arc_end) arc_start = f;
        UI_ReloadArcTF = true;
        UI_ClearFocusTF = true;
      }
      if (theEvent.getController().getName() == "ARC_END") { 
        f = arc_end;
        arc_end = isFloat(theEvent.getController().getStringValue()) ? Float.parseFloat(theEvent.getController().getStringValue()) : arc_end; 
        if (arc_end <=0 || arc_end > 360 || arc_start >= arc_end) arc_end = f;
        UI_ReloadArcTF = true; 
        UI_ClearFocusTF = true;
      }
      if(theEvent.getController().getName() == "set0"){
        j[idx.X] = -jog[idx.X];
        j[idx.Y] = -jog[idx.Y];
        j[idx.Z] = -jog[idx.Z];
        s = "G92 X0  Y0  Z0";
        HaveStringToSend = true;
        UI_ClearGCodeTF = true;
      }
      if(theEvent.getController().getName() == "go0"){
        j[idx.X] = -position[idx.X];
        j[idx.Y] = -position[idx.Y];
        j[idx.Z] = -position[idx.Z];
        if (j[idx.X] != 0 || j[idx.Y] != 0 || j[idx.Z] != 0) { 
          s = jog_string(j, G_AbsoluteMode, RenderZero); 
          HaveStringToSend = true;
        }
        ZeroMode = false; 
        UI_ClearGCodeTF = true;
      }
      // jog button events
      if (theEvent.getController().getName() == "X+") { 
        j[idx.X] = jog[idx.X];
        if (XYZMode) { 
          accumulated_jog[idx.X] += jog[idx.X]; 
          return;
        }
        if (j[idx.X] != 0) { 
          s = jog_string(j, G_AbsoluteMode, RenderZero); 
          HaveStringToSend = true;
        }
      }
      if (theEvent.getController().getName() == "X-") { 
        j[idx.X] = -jog[idx.X];
        if (XYZMode) { 
          accumulated_jog[idx.X] -= jog[idx.X]; 
          return;
        }
        s = jog_string(j, G_AbsoluteMode, RenderZero);
        HaveStringToSend = true;
      }
      if (theEvent.getController().getName() == "Y+") { 
        j[idx.Y] = jog[idx.Y];
        if (XYZMode) { 
          accumulated_jog[idx.Y] += jog[idx.Y]; 
          return;
        }
        if (j[idx.Y] != 0) { 
          s = jog_string(j, G_AbsoluteMode, RenderZero); 
          HaveStringToSend = true;
        }
      }
      if (theEvent.getController().getName() == "Y-") { 
        j[idx.Y] = -jog[idx.Y];
        if (XYZMode) { 
          accumulated_jog[idx.Y] -= jog[idx.Y]; 
          return;
        }
        
        s = jog_string(j, G_AbsoluteMode, RenderZero);
        HaveStringToSend = true;
      }
      if (theEvent.getController().getName() == "Z+") { 
        j[idx.Z] = jog[idx.Z];
        if (XYZMode) { 
          accumulated_jog[idx.Z] += jog[idx.Z]; 
          return;
        }
        if (j[idx.Z] != 0) { 
          s = jog_string(j, G_AbsoluteMode, RenderZero); 
          HaveStringToSend = true;
        }
      }
      if (theEvent.getController().getName() == "Z-") { 
        j[idx.Z] = -jog[idx.Z];
        if (XYZMode) { 
          accumulated_jog[idx.Z] -= jog[idx.Z]; 
          return;
        }
        if (j[idx.Z] != 0) { 
          s = jog_string(j, G_AbsoluteMode, RenderZero);
          HaveStringToSend = true; 
        }
      }

      if (HaveStringToSend) {
        HaveStringToSend = false;
        if (WaitingForResponse) { 
          delay(50);
        } // wait a bit
        if (WaitingForResponse) { 
          java.awt.Toolkit.getDefaultToolkit().beep(); 
          return;
        } // beep & exit if still no response from port
        process_command(s);
      }
    }
  }


  // keyboard events

  public void keyPressed() {
    String s = "";
    if (!(PortResponding && (!SendingSequence || SendingSequence && Paused))) return;
    if (((Textfield)cP5.getController("GCODE")).isFocus()) return; // do not process keystrokes while editing GCode

    if (key == 'j' || key == 'J') open_group('J');
    if (key == 'h' || key == 'H') open_group('H');
    if (key == 'a' || key == 'A') open_group('A');

    if (key == '+') { 
      feed[idx.X] += feedInc; 
      feed[idx.Y] += feedInc;
    }
    if (key == '-') { 
      feed[idx.X] -= feedInc; 
      feed[idx.Y] -= feedInc;
    }
    
    if (key == CODED && keyCode == RIGHT) { 
      ((Button)cP5.getController("X+")).setValue(ControlP5.PRESSED);
    }
    if (key == CODED && keyCode == LEFT) { 
      ((Button)cP5.getController("X-")).setValue(ControlP5.PRESSED);
    }
    if (key == CODED && keyCode == UP) { 
      ((Button)cP5.getController("Y+")).setValue(ControlP5.PRESSED);
    }
    if (key == CODED && keyCode == DOWN) { 
      ((Button)cP5.getController("Y-")).setValue(ControlP5.PRESSED);
    }
    if (key ==  ',') { 
      ((Button)cP5.getController("Z+")).setValue(ControlP5.PRESSED);
    }
    if (key ==  '.') { 
      ((Button)cP5.getController("Z-")).setValue(ControlP5.PRESSED);
    }  
    if (key == DELETE) {
      ((Toggle)cP5.getController("xyz_mode")).setValue(!XYZMode);
    }
    if (key == '[') {
      ((Toggle)cP5.getController("arc_mode")).setValue(!ArcMode); 
      open_group(ArcMode? 'A':'J');
    }
    if (key == ']') {
      ((Toggle)cP5.getController("zero_mode")).setValue(!ZeroMode);
    }
    /*
  if (key == ';') {
     ((Toggle)cP5.getController("mem_mode")).setValue(!MemMode);
     }
     */
  }

  // serial events
  public void serialEvent(Serial port)
  {
    //  if(!SendingSequence) delay(100);
    delay(10); 
    String s = port.readString();
    console_println("> "+s.trim());
    s = s.trim().toUpperCase();

    // process response
    // start/ok line-based protocol is supported by most reprap firmware

    // firmware reset (not all firmware does this though)
    if (s.equals("START")) {
      console_println("firmware start, sending init sequence");
      SendingSequence = false; 
      Paused = false;
      PortWasReset = false; 
      PortResponding = true; 
      WaitingForResponse = false;
      for (int i=0; i<idx.size(); i++) position[i] = 0; // zero position
      init_sequence();
      return;
    }

    // response to a command
    if (s.equals("OK")) { 
      WaitingForResponse = false; // let everyone know they can send more to the port
      if (SendingSequence && !Paused) send_next_line();
      if (SendingSequence && SequenceLastLineSent) { 
        SequenceLastLineSent = false;
        SendingSequence = false;
        console_println(": done sending sequence");
      }
      return;
    }

    // if we received something other than OK or START after port reset, assume port is responding
    // kludgy but should work for firmware that supports 'ok' but not 'start' e.g. Grbl (as of 0.7d)
    if (PortWasReset) {
      console_println("port reset, sending init sequence");
      PortWasReset = false; 
      PortResponding = true; 
      init_sequence();
    }
  }
