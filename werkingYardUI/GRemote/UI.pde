

  // UI and controlP5 related functions
  //
  // Todo: build update functions for all buttons and toggles, dependent solely on state flags.


  int console_size = 10;
  int next_line = 0;
  String[] console = new String[console_size];
  String[] ord_console = new String[console_size];
  String[] jog_buttons = {"X+", "X-", "Y+", "Y-", "Z+", "Z-"};
  String[] jog_toggles = {"arc_mode", "xyz_mode", "zero_mode"/*, "mem_mode"*/  };
  String[] jog_frac_name = {"1/32", "1/16", "1/8", "1/4", "1/2", "1"};
  Float[] jog_frac_value = {0.03125f, 0.0625f, 0.125f, 0.25f, 0.5f, 1.0f};
  String[] jog_dec_name = {"0.1", "1", "10", "100"};
  Float[] jog_dec_value = {0.1f, 1.0f, 10.0f, 100.0f};
  Integer[] baud_values = {9600, 19200, 38400, 57600, 115200};
  DropdownList jogX_ddl, jogY_ddl, jogZ_ddl;
  ControlGroup Jogging_grp, Homing_grp, Arcs_grp, Setting_grp;
  int[] jog_ddl_idx;
  boolean[] jog_ddl_frac;
  ArrayList<File> files;

  public void setup_file_list(int x1, int y1, int x2, int y2) {
    MenuList menu = new MenuList( cP5, "menu", x1, y1, x2, y2 );

    files = getFiles(dataPath, extention);
    for(File current : files){
      try {
        menu.addItem(makeItem(current));
        console_println(current.getName() + " : LOADED");
      } catch (Exception e) {
        console_println(e.getMessage());
        deleteDirectory(current);
      }
    }
    menu.hide();
  }

  public void update_file_list() {
    MenuList menu = cP5.get(MenuList.class, "menu");
    menu.setVisible(PortResponding || DEBUG);

    ArrayList<File> currentFiles = getFiles(dataPath, extention);
    ArrayList<File> currentFilesClone = new ArrayList<File>(currentFiles);
    currentFilesClone.removeAll(files);
    
    for(File current : currentFilesClone){
      try {
        menu.addItem(makeItem(current));
        console_println(current.getName() + " : LOADED");
      } catch (Exception e) {
        console_println(e.getMessage());
        deleteDirectory(current);
      }
    }
    files = getFiles(dataPath, extention);
  }


  // console functions
  // setup_console(10, 10, 200, height-50);  
  public void setup_console(int x1, int y1, int x2, int y2) {
    cP5.addTextarea("CONSOLE", "", x1, y1, x2, y2)
      .setColorBackground(0xff000000);
    for (int i = 0; i < console_size; i++) { 
      console[i] = ""; 
      ord_console[i] = "";
    }
    ord_console[0] = "Select serial port";
    Textfield t = cP5.addTextfield("GCODE", x1, y1+y2 - 20, x2, 20);
    t.setColorBackground(0xffffffff);
    t.setColorLabel(0xff000000);
    t.setColorValue(0xff000000);
    t.setLabel("");

    cP5.addTextlabel("X_POS", "", x1, y1+y2 + 10);
    cP5.addTextlabel("Y_POS", "", (int)(x1 + x2 *0.5)-20, y1+y2 + 10);
    cP5.addTextlabel("Z_POS", "", x1 + x2 - 30, y1+y2 + 10);
  }

  public void clear_console() {
    for (int i=0; i<console_size; i++) { 
      console[i]=""; 
      ord_console[i]="";
    }
  }

  public void console_println(String s) {
    // add to buffer
    println(s);
    console[next_line] = s;
    if (next_line < console_size-1){
      next_line++;
    }
    else {
      next_line = 0;
    }

    // reorder console array into ord_console array
    int j = 0; 
    int k = next_line;
    for (int i = k; i < console_size; i++) { 
      ord_console[j] = console[i]; 
      j++;
    }
    for (int i = 0; i < k; i++) { 
      ord_console[j] = console[i]; 
      j++;
    }
  }

  public void update_console() {
    


    cP5.get(Textarea.class, "CONSOLE").setText(join(ord_console, '\n'));

    for (int i=0; i<idx.size(); i++) {
      ((Textlabel)cP5.getController(idx.strVal[i]+"_POS")).setVisible(PortResponding || DEBUG );
      ((Textlabel)cP5.getController(idx.strVal[i]+"_POS")).setValue(idx.strVal[i]+floatCoord(position[i]));
    }
    if (port == null || SendingSequence && !Paused) { 
      cP5.getController("GCODE").setVisible(false || DEBUG);
    } else { 
      cP5.getController("GCODE").setVisible(true || DEBUG);
      if (UI_ClearGCodeTF) {
        ((Textfield)cP5.getController("GCODE")).setText("");
        UI_ClearGCodeTF = false;
      }
      if (XYZMode)
        ((Textfield)cP5.getController("GCODE")).setText(jog_string(accumulated_jog, G_AbsoluteMode, true));
      if (ZeroMode)
        ((Textfield)cP5.getController("GCODE")).setText(zero_string());
      if (MemMode)
        ((Textfield)cP5.getController("GCODE")).setText(mem_string());    

      cP5.getController("GCODE").setLock(XYZMode || ZeroMode || MemMode);
    }
  }

  // toggle functions
  public void setup_toggles(int x, int y) {
    cP5.addToggle("sending_LED")
      .setPosition(x, y)
      .setSize(14, 14)
      .setLabel("SENDING")
      .setLock(true)
      .setColorBackground(color(80, 80, 80))
      .setColorActive(color(0, 255, 0))
      .getCaptionLabel().getStyle().setMargin(-14, 0, 0, 18);

    cP5.addToggle("paused_LED")
      .setPosition(x+70, y)
      .setSize(14, 14)
      .setLabel("PAUSED")
      .setLock(true)
      .setColorBackground(color(80, 80, 80))
      .setColorActive(color(255, 255, 0))
      .getCaptionLabel().getStyle().setMargin(-14, 0, 0, 18);

    cP5.addToggle("waiting_LED")
      .setPosition(x+140, y)
      .setSize(14, 14)
      .setLabel("WAITING")
      .setLock(true)
      .setColorBackground(color(80, 80, 80))
      .setColorActive(color(255, 0, 0))
      .getCaptionLabel().getStyle().setMargin(-14, 0, 0, 18);

    cP5.addToggle("absolute_mode")
      .setPosition(x, y+20)
      .setSize(14, 14)
      .setLabel("ABSOLUTE")
      .getCaptionLabel().getStyle().setMargin(-14, 0, 0, 18);

    //  t.setLock(true);
    /*
  t = cP5.addToggle("inch_mode",false,x+75,y+20,14,14);
     t.setLabel("INCHES");
     t.captionLabel().style().marginTop = -14;
     t.captionLabel().style().marginLeft = 18;
     */
    //  t.setLock(true);
  }

  public void update_toggles() {
    // set visibility
    cP5.getController("sending_LED").setVisible(PortResponding || DEBUG);
    cP5.getController("paused_LED").setVisible(PortResponding || DEBUG);
    cP5.getController("waiting_LED").setVisible(PortResponding || DEBUG);
    cP5.getController("absolute_mode").setVisible(PortResponding || DEBUG);
    //cP5.getController("inch_mode").setVisible(PortResponding);

    // set lock
    cP5.getController("absolute_mode").setLock(SendingSequence && !Paused);
    //cP5.getController("inch_mode").setLock(SendingSequence && !Paused);

    // set values
    if ((int)cP5.getController("sending_LED").getValue() != (SendingSequence? 1:0))
      cP5.getController("sending_LED").setValue((SendingSequence? 1:0));
    if ((int)cP5.getController("paused_LED").getValue() != (Paused? 1:0))
      cP5.getController("paused_LED").setValue((Paused? 1:0));
    if ((int)cP5.getController("waiting_LED").getValue() != (WaitingForResponse? 1:0))
      cP5.getController("waiting_LED").setValue((WaitingForResponse? 1:0));
    if ((int)cP5.getController("absolute_mode").getValue() != (G_AbsoluteMode? 1:0))
      cP5.getController("absolute_mode").setValue((G_AbsoluteMode? 1:0));
  }
  

  public void setup_port_led(int x, int y) {
    cP5.addToggle("port_LED")
      .setPosition(x, y)
      .setSize(14, 14)
      .setLabel("")
      .setLock(true)
      .setColorBackground(color(0, 0, 127))
      .setColorActive(color(0, 0, 255));
  }

  public void update_port_led() {
    int c = 0;
    if (port != null)
      c = port.available();
    if (c > 1)
      c = 1;
    if ((int)cP5.getController("port_LED").getValue() != c)
      cP5.getController("port_LED").setValue(c);
  }


  
  // port selection functions
  public void setup_port_selector(int x, int y, int x2, int y2) {
    //DropdownList baud_ddl = cP5.addDropdownList("BAUD",x,y+10,80,180);
    //   ControlGroup g = cP5.addGroup("PORT", x, y, 100).activateEvent(true);
    DropdownList ports_ddl = cP5.addDropdownList("PORT", x, y, x2, y2);
    //ports_ddl.setGroup(g);
    ports_ddl.close();
    //cP5.addScrollableList("PORT")
    //  .setPosition(x, y)
    // .setSize(x2, y2);
    /*baud_ddl.captionLabel().set("115200");
     baud_ddl.captionLabel().getFont().setSize(14);
     baud_ddl.captionLabel().getFont().sharp();
     baud_ddl.captionLabel().style().marginTop = 8;
     baud_ddl.setBarHeight(28);
     for (int i=0; i<baud_values.length; i++) baud_ddl.addItem( baud_values[i].toString(),baud_values[i]);
     */
    ports_ddl.getCaptionLabel().set("PORT");
    ports_ddl.getCaptionLabel().getFont().setSize(14);
    ports_ddl.getCaptionLabel().getFont().sharp();
    ports_ddl.getCaptionLabel().getStyle().setMarginTop(0);
    ports_ddl.setBarHeight(28);  
    ports_ddl.setItemHeight(28);
    int n_ports = Serial.list().length;
    for (i=0; i<n_ports; i++) {
      ports_ddl.addItem(Serial.list()[i], i);
    }
  }
  public void update_port_selector() {
    cP5.get(DropdownList.class, "PORT").setVisible(!SendingSequence);
    //((DropdownList)cP5.group("BAUD")).setVisible(!SendingSequence);
  }

  // buttons
  public void setup_func_buttons(int x, int y) {
    Button b = cP5.addButton("FILE")
      .setPosition(x, y)
      .setSize(122, 30);
    b.getCaptionLabel().setSize(10);
    b.getCaptionLabel().getStyle().setMarginLeft(0);

    b = cP5.addButton("PAUSE/RESUME")
      .setPosition(x+128, y)
      .setSize(122, 30);
    b.getCaptionLabel().setSize(10);
    b.getCaptionLabel().getStyle().setMarginLeft(0);

    b = cP5.addButton("CANCEL")
      .setPosition(x+128+128, y)
      .setSize(122, 30);
    b.getCaptionLabel().setSize(10);
    b.getCaptionLabel().getStyle().setMarginLeft(0);


    b = cP5.addButton("IMG")
            .setPosition(x, y + 40)
            .setSize(128+128+122 ,  215 );
  }

  public void update_func_buttons() {
    if (!PortResponding && !DEBUG ) {
      cP5.getController("FILE").setVisible(false);
      cP5.getController("PAUSE/RESUME").setVisible(false);
      cP5.getController("CANCEL").setVisible(false);
      cP5.getController("IMG").setVisible(false);
      return;
    }
    cP5.getController("FILE").setVisible((!SendingSequence) || DEBUG);
    cP5.getController("CANCEL").setVisible(SendingSequence || DEBUG);
    cP5.getController("PAUSE/RESUME").setVisible(SendingSequence || DEBUG);
    cP5.getController("IMG").setVisible(SendingSequence || DEBUG);
    if (Paused) cP5.getController("PAUSE/RESUME").setLabel("RESUME");
    else cP5.getController("PAUSE/RESUME").setLabel("PAUSE");
  }

  public void setup_jog_buttons(int x, int y) {  
    int buttonWidth = 122;
    int buttonHeight = 60;
    int buttonmargin = 6;

    PVector pos = new PVector(x, y);

    Toggle t = cP5.addToggle("arc_mode")
      .setPosition(pos.x, pos.y)
      .setSize(buttonWidth, buttonHeight);
    t.setLabel("ARCS");
    t.getCaptionLabel().getStyle().setMargin(-31, 0, 0, 14);
    t.getCaptionLabel().getFont().setSize(14);

    pos.x += buttonmargin+buttonWidth;
    t = cP5.addToggle("xyz_mode")
      .setPosition(pos.x, pos.y)
      .setSize(buttonWidth, buttonHeight);
    t.setLabel("XYZ");
    t.getCaptionLabel().getStyle().setMargin(-31, 0, 0, 14);
    t.getCaptionLabel().getFont().setSize(14);

    pos.x += buttonmargin+buttonWidth;
    t = cP5.addToggle("zero_mode")
      .setPosition(pos.x, pos.y)
      .setSize(buttonWidth, buttonHeight);
    t.setLabel("ZERO");
    t.getCaptionLabel().getStyle().setMargin(-31, 0, 0, 14);
    t.getCaptionLabel().getFont().setSize(14);
   
    pos = new PVector(x, y+2*(buttonmargin+buttonHeight));

    Button b = cP5.addButton("X+")
      .setPosition(pos.x, pos.y)
      .setSize(buttonWidth, buttonHeight);
    b.getCaptionLabel().getStyle().setMargin(10, 0, 0, 3);
    b.getCaptionLabel().getFont().setSize(14); 

    pos.x += buttonmargin+buttonWidth;
    b=cP5.addButton("Y+")
      .setPosition(pos.x, pos.y)
      .setSize(buttonWidth, buttonHeight);
    b.getCaptionLabel().getStyle().setMargin(10, 0, 0, 3);
    b.getCaptionLabel().getFont().setSize(14); 

    pos.x += buttonmargin+buttonWidth;
    b=cP5.addButton("Z+")
      .setPosition(pos.x, pos.y)
      .setSize(buttonWidth, buttonHeight);
    b.getCaptionLabel().getStyle().setMargin(10, 0, 0, 3);
    b.getCaptionLabel().getFont().setSize(14); 

    pos = new PVector(x, y+(buttonmargin+buttonHeight));

    b=cP5.addButton("X-")
      .setPosition(pos.x, pos.y)
      .setSize(buttonWidth, buttonHeight);
    b.getCaptionLabel().getStyle().setMargin(10, 0, 0, 3);
    b.getCaptionLabel().getFont().setSize(14);  

    pos.x += buttonmargin+buttonWidth;
    b=cP5.addButton("Y-")
      .setPosition(pos.x, pos.y)
      .setSize(buttonWidth, buttonHeight);
    b.getCaptionLabel().getStyle().setMargin(10, 0, 0, 3);
    b.getCaptionLabel().getFont().setSize(14);   

    pos.x += buttonmargin+buttonWidth;
    b = cP5.addButton("Z-")
      .setPosition(pos.x, pos.y)
      .setSize(buttonWidth, buttonHeight);
    b.getCaptionLabel().getStyle().setMargin(10, 0, 0, 3);
    b.getCaptionLabel().getFont().setSize(14);  

    for (int i = 0; i < jog_buttons.length; i++) {
      ((Button)cP5.getController(jog_buttons[i])).activateBy(ControlP5.PRESSED);
    }
  }  

  public void update_jog_buttons() {
    String s;
    Boolean Visible = (PortResponding && (!SendingSequence || SendingSequence && Paused)) || DEBUG;

    if ((int)cP5.getController("arc_mode").getValue() != (ArcMode? 1:0)) cP5.getController("arc_mode").setValue((ArcMode? 1:0));
    if ((int)cP5.getController("xyz_mode").getValue() != (XYZMode? 1:0)) cP5.getController("xyz_mode").setValue((XYZMode? 1:0));
    if ((int)cP5.getController("zero_mode").getValue() != (ZeroMode? 1:0)) cP5.getController("zero_mode").setValue((ZeroMode? 1:0));
    // if ((int)cP5.getController("mem_mode").getValue() != (MemMode? 1:0)) cP5.getController("mem_mode").setValue((MemMode? 1:0));

    for (int i = 0; i < jog_buttons.length; i++) cP5.getController(jog_buttons[i]).setVisible(Visible);
    for (int i = 0; i < jog_toggles.length; i++) cP5.getController(jog_toggles[i]).setVisible(Visible);

    // button labels
    s = "   X+";
    if (ZeroMode) s = "  GO X0";
    if (MemMode) s = "  GO XM";
    if (ArcMode) s = ArcCCW? "  R&UP":"  R&DN";
    cP5.getController("X+").setLabel(s);
    s = "   X-";
    if (ZeroMode) s = " SET X0";
    if (MemMode) s = " SET XM";
    if (ArcMode) s = ArcCCW? "  L&DN":"  L&UP";
    cP5.getController("X-").setLabel(s);

    s = "   Y+";
    if (ZeroMode) s = "  GO Y0";
    if (MemMode) s = "  GO YM";
    if (ArcMode) s = ArcCCW? "  UP&L":"  UP&R";
    cP5.getController("Y+").setLabel(s);
    s = "   Y-";
    if (ZeroMode) s = " SET Y0";
    if (MemMode) s = " SET YM";
    if (ArcMode) s = ArcCCW? "  DN&R":"  DN&L";
    cP5.getController("Y-").setLabel(s);

    s = "   Z+";
    if (ZeroMode) s = "  GO Z0";
    if (MemMode) s = "  GO ZM";
    cP5.getController("Z+").setLabel(s);
    s = "   Z-";
    if (ZeroMode) s = " SET Z0";
    if (MemMode) s = " SET ZM";
    cP5.getController("Z-").setLabel(s);
  }  

  public void setup_jog_controls(int x, int y, int y_off) { 
    /*ControlGroup g = cP5.addGroup("GROUP_JOGGING", x, y, 200);
    //g.setLabel("JOGGING"); 
    g.open(); 
    Jogging_grp = g;
    */
    //g.setBarHeight(20);
    //g.getCaptionLabel().getFont().setSize(10);
    //g.getCaptionLabel().getStyle().setMarginTop(5);
    
   // x = 0;
   // y = y_off;
    /*
  cP5.addTextlabel("set_jog_label", "SET JOG ", x, y+4).setGroup(g);
     
     Toggle t = cP5.addToggle("fractional_jog", false, x+50, y, 14, 14);
     t.setGroup(g); t.setLabel("FRAC");
     t.captionLabel().style().marginTop = -14;
     t.captionLabel().style().marginLeft = 18;
     
     t = cP5.addToggle("rapid_positioning", false, x+95, y, 14, 14);
     t.setGroup(g); t.setLabel("RAPID");
     t.captionLabel().style().marginTop = -14;
     t.captionLabel().style().marginLeft = 18;
     */

    cP5.addTextlabel("jog_z_label", "Z", x+135, y);
    jogZ_ddl = cP5.addDropdownList("JOG Z", x+15+135, y, 50, y+99);
    jogZ_ddl.close();
    
    jogZ_ddl.getCaptionLabel().set("1");
    jogZ_ddl.getCaptionLabel().getStyle().setMarginTop(0);
    jogZ_ddl.setBarHeight(40);
    jogZ_ddl.setItemHeight(30);

    cP5.addTextlabel("jog_y_label", "Y", x+70, y);
    jogY_ddl = cP5.addDropdownList("JOG Y", x+15+70, y, 50, y+84);
    jogY_ddl.close();
    jogY_ddl.getCaptionLabel().set("1");
    jogY_ddl.getCaptionLabel().getStyle().setMarginTop(0);
    jogY_ddl.setBarHeight(40);
    jogY_ddl.setItemHeight(30);

    cP5.addTextlabel("jog_x_label", "X", x, y);
    jogX_ddl = cP5.addDropdownList("JOG X", x+15, y, 50, y+69);
    jogX_ddl.close();
    jogX_ddl.getCaptionLabel().set("1");
    jogX_ddl.getCaptionLabel().getStyle().setMarginTop(0);
    jogX_ddl.setBarHeight(40);
    jogX_ddl.setItemHeight(30);
    /*
  Numberbox nbr = cP5.addNumberbox("FEED X", 10, x+95, y+20, 50, 14); nbr.setGroup(g);
     nbr.setLabel("");  nbr.setMin(1); nbr.setMultiplier(1);
     nbr = cP5.addNumberbox("FEED Y", 10, x+95, y+35, 50, 14); nbr.setGroup(g);
     nbr.setLabel("");  nbr.setMin(1); nbr.setMultiplier(1);
     nbr = cP5.addNumberbox("FEED Z", 10, x+95, y+50, 50, 14); nbr.setGroup(g);
     nbr.setLabel("");  nbr.setMin(1); nbr.setMultiplier(1);
     */
    int n = FractionalJog ? jog_frac_name.length : jog_dec_name.length;
    for (int i=0; i<n; i++) {
      jogX_ddl.addItem(FractionalJog ? jog_frac_name[i] : jog_dec_name[i], i);
      jogY_ddl.addItem(FractionalJog ? jog_frac_name[i] : jog_dec_name[i], i);
      jogZ_ddl.addItem(FractionalJog ? jog_frac_name[i] : jog_dec_name[i], i);
    }
    jog_ddl_idx = new int[idx.size()];
    jog_ddl_frac = new boolean[idx.size()];
    for (int i=0; i<idx.size(); i++) {
      jog_ddl_idx[i] = 1; // index of "1" in jog_dec_value[], default
      jog_ddl_frac[i] = false;
      jog[i] = intCoord(jog_dec_value[jog_ddl_idx[i] ]);
    }
  }

  public void update_jog_controls() {
    cP5.getController("JOG Z").setVisible(PortResponding || DEBUG);
    cP5.getController("JOG Y").setVisible(PortResponding || DEBUG);
    cP5.getController("JOG X").setVisible(PortResponding || DEBUG);
    
    cP5.getController("jog_z_label").setVisible(PortResponding || DEBUG);
    cP5.getController("jog_y_label").setVisible(PortResponding || DEBUG);
    cP5.getController("jog_x_label").setVisible(PortResponding || DEBUG);
    
    //Jogging_grp.setVisible(PortResponding && (!SendingSequence || SendingSequence && Paused));
    //if ((int)cP5.getController("fractional_jog").getValue() != (FractionalJog? 1:0)) cP5.getController("fractional_jog").setValue((FractionalJog? 1:0));
    //if ((int)cP5.getController("rapid_positioning").getValue() != (RapidPositioning? 1:0)) cP5.getController("rapid_positioning").setValue((RapidPositioning? 1:0));  
    //if (cP5.getController("FEED X").getValue() != feed[idx.X]) cP5.getController("FEED X").setValue(feed[idx.X]);
    //if (cP5.getController("FEED Y").getValue() != feed[idx.Y]) cP5.getController("FEED Y").setValue(feed[idx.Y]);
    //if (cP5.getController("FEED Z").getValue() != feed[idx.Z]) cP5.getController("FEED Z").setValue(feed[idx.Z]);
    if (UI_ReloadJogDDL) {
      UI_ReloadJogDDL = false;
      jogX_ddl.clear(); 
      jogY_ddl.clear(); 
      jogZ_ddl.clear();
      int n = FractionalJog ? jog_frac_name.length : jog_dec_name.length;
      for (int i=0; i<n; i++) {
        jogX_ddl.addItem(FractionalJog ? jog_frac_name[i] : jog_dec_name[i], i);
        jogY_ddl.addItem(FractionalJog ? jog_frac_name[i] : jog_dec_name[i], i);
        jogZ_ddl.addItem(FractionalJog ? jog_frac_name[i] : jog_dec_name[i], i);
      }
      //    println("jog*_ddl reloaded");
      //    println("jogX_ddl.getValue() = "+jogX_ddl.getValue());
    }
    jogX_ddl.getCaptionLabel().set( jog_ddl_frac[idx.X]? jog_frac_name[jog_ddl_idx[idx.X]] : jog_dec_name[jog_ddl_idx[idx.X]] );
    jogY_ddl.getCaptionLabel().set( jog_ddl_frac[idx.Y]? jog_frac_name[jog_ddl_idx[idx.Y]] : jog_dec_name[jog_ddl_idx[idx.Y]] );
    jogZ_ddl.getCaptionLabel().set( jog_ddl_frac[idx.Z]? jog_frac_name[jog_ddl_idx[idx.Z]] : jog_dec_name[jog_ddl_idx[idx.Z]] );  

    // ***********************************    
    // ***********************************  
    // ***********************************
  }  

  public void setup_setting_controls(int x, int y, int y_off) {
    ControlGroup g = cP5.addGroup("GROUP_SETTING", x, y, 200).activateEvent(true);
    g.setLabel("SETTING"); 
    g.close(); 
    Setting_grp = g;

    g.setBarHeight(20);
    g.getCaptionLabel().getStyle().setMarginTop(5);
    g.getCaptionLabel().getFont().setSize(10);

    x = 0;
    y = y_off;
    int marginLeft = 35;
    int positionLeft = 40;
    Textfield tf = cP5.addTextfield("X_DIR_PIN", x+positionLeft, y, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("X DIR");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    tf = cP5.addTextfield("X_STEP_PIN", x+positionLeft, y+26, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("X STEP");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    tf = cP5.addTextfield("X_MIN_PIN", x+positionLeft, y+52, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("X MIN");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    tf = cP5.addTextfield("X_MAX_PIN", x+positionLeft, y+78, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("X MAX");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    ((Textfield)cP5.getController("X_DIR_PIN")).setText(String.valueOf(x_dir_pin));
    ((Textfield)cP5.getController("X_STEP_PIN")).setText(String.valueOf(x_step_pin));
    ((Textfield)cP5.getController("X_MIN_PIN")).setText(String.valueOf(x_min_pin));
    ((Textfield)cP5.getController("X_MAX_PIN")).setText(String.valueOf(x_max_pin));

    positionLeft+=96;

    tf = cP5.addTextfield("Y_DIR_PIN", x+positionLeft, y, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("Y DIR");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    tf = cP5.addTextfield("Y_STEP_PIN", x+positionLeft, y+26, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("Y STEP");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    tf = cP5.addTextfield("Y_MIN_PIN", x+positionLeft, y+52, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("Y MIN");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    tf = cP5.addTextfield("Y_MAX_PIN", x+positionLeft, y+78, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("Y MAX");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    ((Textfield)cP5.getController("Y_DIR_PIN")).setText(String.valueOf(y_dir_pin));
    ((Textfield)cP5.getController("Y_STEP_PIN")).setText(String.valueOf(y_step_pin));
    ((Textfield)cP5.getController("Y_MIN_PIN")).setText(String.valueOf(y_min_pin));
    ((Textfield)cP5.getController("Y_MAX_PIN")).setText(String.valueOf(y_max_pin));

    positionLeft+=96;

    tf = cP5.addTextfield("Z_DIR_PIN", x+positionLeft, y, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("Z DIR");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    tf = cP5.addTextfield("Z_STEP_PIN", x+positionLeft, y+26, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("Z STEP");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    tf = cP5.addTextfield("Z_MIN_PIN", x+positionLeft, y+52, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("Z MIN");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    tf = cP5.addTextfield("Z_MAX_PIN", x+positionLeft, y+78, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("Z MAX");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    ((Textfield)cP5.getController("Z_DIR_PIN")).setText(String.valueOf(z_dir_pin));
    ((Textfield)cP5.getController("Z_STEP_PIN")).setText(String.valueOf(z_step_pin));
    ((Textfield)cP5.getController("Z_MIN_PIN")).setText(String.valueOf(z_min_pin));
    ((Textfield)cP5.getController("Z_MAX_PIN")).setText(String.valueOf(z_max_pin));

    positionLeft+=96;

    tf = cP5.addTextfield("X_PER_MM", x+positionLeft, y, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("X PPM");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    tf = cP5.addTextfield("Y_PER_MM", x+positionLeft, y+26, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("Y PPM");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);

    tf = cP5.addTextfield("Z_PER_MM", x+positionLeft, y+52, 50, 20); 
    tf.setGroup(g); 
    tf.setLabel("Z PPM");
    tf.getCaptionLabel().getStyle().setMarginTop(-17);
    tf.getCaptionLabel().getStyle().setMarginLeft(-30);


    ((Textfield)cP5.getController("X_PER_MM")).setText(String.valueOf(x_steps_per_mm));
    ((Textfield)cP5.getController("Y_PER_MM")).setText(String.valueOf(y_steps_per_mm));
    ((Textfield)cP5.getController("Z_PER_MM")).setText(String.valueOf(z_steps_per_mm));

    Button b = cP5.addButton("SAVE")
      .setPosition(x+positionLeft-marginLeft, y+78)
      .setSize(50+marginLeft, 20);
    b.getCaptionLabel().getStyle().setMarginLeft(b.getCaptionLabel().getStyle().marginLeft-6);
    b.setGroup(g);

    
      String[] settingList = loadStrings(sketchPath+"/setting.ini");
    
    try {

      ((Textfield)cP5.getController("X_DIR_PIN")).setText(settingList[1]);
      ((Textfield)cP5.getController("X_STEP_PIN")).setText(settingList[2]);
      ((Textfield)cP5.getController("X_MIN_PIN")).setText(settingList[3]);
      ((Textfield)cP5.getController("X_MAX_PIN")).setText(settingList[4]);
      ((Textfield)cP5.getController("Y_DIR_PIN")).setText(settingList[5]);
      ((Textfield)cP5.getController("Y_STEP_PIN")).setText(settingList[6]);
      ((Textfield)cP5.getController("Y_MIN_PIN")).setText(settingList[7]);
      ((Textfield)cP5.getController("Y_MAX_PIN")).setText(settingList[8]);
      ((Textfield)cP5.getController("Z_DIR_PIN")).setText(settingList[9]);
      ((Textfield)cP5.getController("Z_STEP_PIN")).setText(settingList[10]);
      ((Textfield)cP5.getController("Z_MIN_PIN")).setText(settingList[11]);
      ((Textfield)cP5.getController("Z_MAX_PIN")).setText(settingList[12]);
      ((Textfield)cP5.getController("X_PER_MM")).setText(settingList[13]);
      ((Textfield)cP5.getController("Y_PER_MM")).setText(settingList[14]);
      ((Textfield)cP5.getController("Z_PER_MM")).setText(settingList[15]);
    }
    catch(Exception e) {
      ((Textfield)cP5.getController("X_DIR_PIN")).setText(String.valueOf(x_dir_pin));
      ((Textfield)cP5.getController("X_STEP_PIN")).setText(String.valueOf(x_step_pin));
      ((Textfield)cP5.getController("X_MIN_PIN")).setText(String.valueOf(x_min_pin));
      ((Textfield)cP5.getController("X_MAX_PIN")).setText(String.valueOf(x_max_pin));
      ((Textfield)cP5.getController("Y_DIR_PIN")).setText(String.valueOf(y_dir_pin));
      ((Textfield)cP5.getController("Y_STEP_PIN")).setText(String.valueOf(y_step_pin));
      ((Textfield)cP5.getController("Y_MIN_PIN")).setText(String.valueOf(y_min_pin));
      ((Textfield)cP5.getController("Y_MAX_PIN")).setText(String.valueOf(y_max_pin));
      ((Textfield)cP5.getController("Z_DIR_PIN")).setText(String.valueOf(z_dir_pin));
      ((Textfield)cP5.getController("Z_STEP_PIN")).setText(String.valueOf(z_step_pin));
      ((Textfield)cP5.getController("Z_MIN_PIN")).setText(String.valueOf(z_min_pin));
      ((Textfield)cP5.getController("Z_MAX_PIN")).setText(String.valueOf(z_max_pin));
      ((Textfield)cP5.getController("X_PER_MM")).setText(String.valueOf(x_steps_per_mm));
      ((Textfield)cP5.getController("Y_PER_MM")).setText(String.valueOf(y_steps_per_mm));
      ((Textfield)cP5.getController("Z_PER_MM")).setText(String.valueOf(z_steps_per_mm));
    }
  }
  public void update_setting_controls() {
    Setting_grp.setVisible((PortResponding && (!SendingSequence || SendingSequence && Paused)|| DEBUG));
  }





  public void update_textfields() {
    if (UI_ClearFocusTF) {
      ((Textfield)cP5.getController("GCODE")).setFocus(false);
      ((Textfield)cP5.getController("ARC_RADIUS")).setFocus(false);
      ((Textfield)cP5.getController("ARC_START")).setFocus(false);
      ((Textfield)cP5.getController("ARC_END")).setFocus(false);
      UI_ClearFocusTF = false;
    }
  }

  public void open_group(char g) {
    if (g == 'J') {
      //Jogging_grp.open();
      //Homing_grp.close();
      //Arcs_grp.close();
      Setting_grp.close();
    }// else //Jogging_grp.close();
    if (g == 'H') {
      //Homing_grp.open();
      //Jogging_grp.close();
      //Arcs_grp.close();
      Setting_grp.close();
    }// else Homing_grp.close();
    if (g == 'A') {
      //Arcs_grp.open(); 
      //Homing_grp.close();
      //Jogging_grp.close();
      Setting_grp.open();
    } else {
      //Arcs_grp.close();
    }
    if (g == 'S') {
      Setting_grp.open(); 
      //Homing_grp.close();
      //Jogging_grp.close();
      //Arcs_grp.close();
    } else {
      Setting_grp.close();
    }
  }

  public void update_groups() {
    //Jogging_grp.setColorLabel(Jogging_grp.isOpen() ? 0xFFFFFFFF : 0xFF888888); // 0xFF08A2CF);
    //Homing_grp.setColorLabel(Homing_grp.isOpen() ? 0xFFFFFFFF : 0xFF888888);
    //Arcs_grp.setColorLabel(Arcs_grp.isOpen() ? 0xFFFFFFFF : 0xFF888888);  
    Setting_grp.setColorLabel(Setting_grp.isOpen() ? 0xFFFFFFFF : 0xFF888888);
  }
