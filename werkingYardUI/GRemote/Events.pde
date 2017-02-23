// cP5 UI events
  public void controlEvent(ControlEvent theEvent) {
    boolean RenderZero = false;
    String s = "";
    int arc_offset;
    int j[] = new int[idx.size()];
    for (int i=0; i<idx.size(); i++)
      j[i] = 0;  // clear temp array

    if(theEvent.isFrom("menu")){
      Map m = ((MenuList)theEvent.getController()).getItem(int(theEvent.getValue()));
      currentSelectedCNCFile = (File)m.get("cncFile");
      Button b = cP5.get(Button.class, "IMG");
      PImage img = (PImage)m.get("jpgFile");
      img.resize(b.getWidth(), 0);
      b.setImages(img, img, img);
      return ;
    }

    // because only permitted (for current state) elements are available in the UI,
    // we assume that if we received an event, we can handle it without checking state
    // the above is not true for keypresses, where state has to be explicitly checked before handling event
    if (theEvent.getName().equals("PORT")) {
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


    // jog setting selected
    if (theEvent.getName()=="JOG X") {
      i = (int)theEvent.getValue();
      jog[idx.X] = intCoord(FractionalJog ? jog_frac_value[i] : jog_dec_value[i]);
      //      println(jog[idx.X]);
      // store current jog dropdown values - workaround to enable inc/dec of jog values with keyboard shortcut (dropdownlist doesn't seem to have .setValue)
      jog_ddl_idx[idx.X] = i; 
      jog_ddl_frac[idx.X] = FractionalJog;
      return;
    }
    if (theEvent.getName()=="JOG Y") {
      i = (int)theEvent.getValue();
      jog[idx.Y] = intCoord(FractionalJog ? jog_frac_value[i] : jog_dec_value[i]);
      //      println(jog[idx.Y]);
      // store current jog dropdown values - workaround to enable inc/dec of jog values with keyboard shortcut (dropdownlist doesn't seem to have .setValue)
      jog_ddl_idx[idx.Y] = i; 
      jog_ddl_frac[idx.Y] = FractionalJog;
      return;
    }
    if (theEvent.getName()=="JOG Z") {
      i = (int)theEvent.getValue();
      jog[idx.Z] = intCoord(FractionalJog ? jog_frac_value[i] : jog_dec_value[i]);
      //      println(jog[idx.Z]);
      // store current jog dropdown values - workaround to enable inc/dec of jog values with keyboard shortcut (dropdownlist doesn't seem to have .setValue)
      jog_ddl_idx[idx.Z] = i; 
      jog_ddl_frac[idx.Z] = FractionalJog;
      return;
    }

    if (theEvent.isGroup()) { 

      if (theEvent.getGroup().getName()=="GROUP_JOGGING") {
        if (theEvent.getGroup().isOpen()) {
          open_group('J');
        }
      }
      if (theEvent.getGroup().getName()=="GROUP_ARCS") {
        if (theEvent.getGroup().isOpen()) {
          open_group('A');
        }
      }
      if (theEvent.getGroup().getName()=="GROUP_HOMING") {
        if (theEvent.getGroup().isOpen()) {
          open_group('H');
        }
      }
      if (theEvent.getGroup().getName()=="GROUP_SETTING") {
        if (theEvent.getGroup().isOpen()) {
          open_group('S');
        }
      }
      // baud rate selected
      if (theEvent.getGroup().getName()=="BAUD") { 
        baudrate = (int)theEvent.getGroup().getValue(); 
        println("baud="+baudrate); 
      }
      return;
    }

    if (theEvent.isController()) { 

      //    print("control event from controller: "+theEvent.getController().getName());
      //    println(", value : "+theEvent.getController().getValue());

      // manually entered command
      if (theEvent.getController().getName() == "GCODE") {
        s = theEvent.getController().getStringValue().toUpperCase();
        HaveStringToSend = true; // UI_ClearFocusTF = true;
      }

      // absolute mode toggle
      if (theEvent.getController().getName() == "absolute_mode") {
        s = ((int)theEvent.getController().getValue() == 1) ? "G90" : "G91";
        HaveStringToSend = true;
      }

      // inch mode toggle
      if (theEvent.getController().getName() == "inch_mode") {
        s = ((int)theEvent.getController().getValue() == 1) ? "G20" : "G21";
        HaveStringToSend = true;
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
      // cancel (sending file) button
      if (theEvent.getController().getName() == "CANCEL") {
        SendingSequence = false;
        Paused = false;
         
        console_println(": send sequence cancelled");
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

      // jog control toggles
      if (theEvent.getController().getName() == "fractional_jog") {
        if ((int)theEvent.getController().getValue() == 1)
          FractionalJog = true;
        else 
          FractionalJog = false;
        UI_ReloadJogDDL = true;
      }
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

      // jog button events
      if (theEvent.getController().getName() == "X+") { 
        j[idx.X] = jog[idx.X];
        if (XYZMode) { 
          accumulated_jog[idx.X] += jog[idx.X]; 
          return;
        }
        if (ZeroMode) j[idx.X] = -position[idx.X];
        if (MemMode) 
          if (memorySet[idx.X]) j[idx.X] = memory[idx.X] - position[idx.X];
          else return;
        if (ArcMode) {
          arc_offset = ArcCCW ? -90 : 90;
          s = arc_string(ArcCCW, arc_radius, arc_offset + (ArcCCW? arc_start : -arc_start), arc_offset + (ArcCCW? arc_end : -arc_end), G_AbsoluteMode);
          HaveStringToSend = true;
        } else if (j[idx.X] != 0) { 
          s = jog_string(j, G_AbsoluteMode, RenderZero); 
          HaveStringToSend = true;
        }
        if (ZeroMode) { 
          ZeroMode = false; 
          UI_ClearGCodeTF = true;
        }
        if (MemMode) { 
          MemMode = false; 
          UI_ClearGCodeTF = true;
        }
      }
      if (theEvent.getController().getName() == "X-") { 
        j[idx.X] = -jog[idx.X];
        if (XYZMode) { 
          accumulated_jog[idx.X] -= jog[idx.X]; 
          return;
        }
        if (MemMode) { 
          memory[idx.X] = position[idx.X]; 
          memorySet[idx.X] = true; 
          return;
        }
        if (ArcMode) {
          arc_offset = ArcCCW ? 90 : -90;
          s = arc_string(ArcCCW, arc_radius, arc_offset + (ArcCCW? arc_start : -arc_start), arc_offset + (ArcCCW? arc_end : -arc_end), G_AbsoluteMode);
          HaveStringToSend = true;
        } else {
          s = ZeroMode ? "G92 X0" : jog_string(j, G_AbsoluteMode, RenderZero);
          HaveStringToSend = true;
        }
        //      if (ZeroMode) { ZeroMode = false; UI_ClearGCodeTF = true; }
      }
      if (theEvent.getController().getName() == "Y+") { 
        j[idx.Y] = jog[idx.Y];
        if (XYZMode) { 
          accumulated_jog[idx.Y] += jog[idx.Y]; 
          return;
        }
        if (ZeroMode) j[idx.Y] = -position[idx.Y];
        if (MemMode) 
          if (memorySet[idx.Y]) j[idx.Y] = memory[idx.Y] - position[idx.Y];
          else return;
        if (ArcMode) {
          arc_offset = ArcCCW ? 0 : 180;
          s = arc_string(ArcCCW, arc_radius, arc_offset + (ArcCCW? arc_start : -arc_start), arc_offset + (ArcCCW? arc_end : -arc_end), G_AbsoluteMode);
          HaveStringToSend = true;
        } else if (j[idx.Y] != 0) { 
          s = jog_string(j, G_AbsoluteMode, RenderZero); 
          HaveStringToSend = true;
        }
        if (ZeroMode) { 
          ZeroMode = false; 
          UI_ClearGCodeTF = true;
        }
        if (MemMode) { 
          MemMode = false; 
          UI_ClearGCodeTF = true;
        }
      }
      if (theEvent.getController().getName() == "Y-") { 
        j[idx.Y] = -jog[idx.Y];
        if (XYZMode) { 
          accumulated_jog[idx.Y] -= jog[idx.Y]; 
          return;
        }
        if (MemMode) { 
          memory[idx.Y] = position[idx.Y]; 
          memorySet[idx.Y] = true; 
          return;
        }
        if (ArcMode) {
          arc_offset = ArcCCW ? -180 : 0;
          s = arc_string(ArcCCW, arc_radius, arc_offset + (ArcCCW? arc_start : -arc_start), arc_offset + (ArcCCW? arc_end : -arc_end), G_AbsoluteMode);
          HaveStringToSend = true;
        } else {
          s = ZeroMode ? "G92 Y0" : jog_string(j, G_AbsoluteMode, RenderZero);
          HaveStringToSend = true;
        }
        //      if (ZeroMode) { ZeroMode = false; UI_ClearGCodeTF = true; }
      }
      if (theEvent.getController().getName() == "Z+") { 
        j[idx.Z] = jog[idx.Z];
        if (XYZMode) { 
          accumulated_jog[idx.Z] += jog[idx.Z]; 
          return;
        }
        if (ZeroMode) j[idx.Z] = -position[idx.Z];
        if (MemMode) 
          if (memorySet[idx.Z]) j[idx.Z] = memory[idx.Z] - position[idx.Z];
          else return;
        if (j[idx.Z] != 0) { 
          s = jog_string(j, G_AbsoluteMode, RenderZero); 
          HaveStringToSend = true;
        }

        if (ZeroMode) { 
          ZeroMode = false; 
          UI_ClearGCodeTF = true;
        }
        if (MemMode) { 
          MemMode = false; 
          UI_ClearGCodeTF = true;
        }
      }
      if (theEvent.getController().getName() == "Z-") { 
        j[idx.Z] = -jog[idx.Z];
        if (XYZMode) { 
          accumulated_jog[idx.Z] -= jog[idx.Z]; 
          return;
        }
        if (MemMode) { 
          memory[idx.Z] = position[idx.Z]; 
          memorySet[idx.Z] = true; 
          return;
        }
        s = ZeroMode ? "G92 Z0" : jog_string(j, G_AbsoluteMode, RenderZero);
        HaveStringToSend = true; 
        //      if (ZeroMode) { ZeroMode = false; UI_ClearGCodeTF = true; }
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