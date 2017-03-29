public Map<String, Object> makeItem(File file) throws Exception {
    int i = file.getName().lastIndexOf('.');
    if (i <= 0) {
      throw new Exception(file.getName() + " IS NOT '.wy' FILE");
    }

    Map m = new HashMap<String, Object>();

    ArrayList <File> cncFiles = getFiles(file, ".cnc");
    ArrayList <File> jpgFiles = getFiles(file, ".jpg");

    if (cncFiles.size() <= 0 || jpgFiles.size() <= 0) {
      throw new Exception(file.getName() + " DOESN'T CONTAIN '.jpg' AND/OR '.cnc' files");
    }
    m.put("name", file.getName());
    m.put("headline", file.getName().substring(0, i));
    m.put("cncFile", cncFiles.get(0));
    m.put("jpgFile", loadImage(jpgFiles.get(0).getPath()));
    return m;
  }

class MenuList extends Controller<MenuList> {
  float pos, npos;
  int itemHeight = 100;
  int scrollerLength = 40;
  List< Map<String, Object>> items = new ArrayList< Map<String, Object>>();
  PGraphics menu;
  boolean updateMenu;

  MenuList(ControlP5 c, String theName, int x, int y , int theWidth, int theHeight) {
    super( c, theName, x, y, theWidth, theHeight );
    c.register( this );
    menu = createGraphics(getWidth(), getHeight() );

    setView(new ControllerView<MenuList>() {

      public void display(PGraphics pg, MenuList t ) {
        if (updateMenu) {
          updateMenu();
        }
        if (inside() ) {
          menu.beginDraw();
          int len = -(itemHeight * items.size()) + getHeight();
          int ty = int(map(pos, len, 0, getHeight() - scrollerLength - 2, 2 ) );
          menu.fill(255 );
          menu.rect(getWidth()-4, ty, 4, scrollerLength );
          menu.endDraw();
        }
        pg.image(menu, 0, 0);
      }
    }
    );
    updateMenu();
  }

  /* only update the image buffer when necessary - to save some resources */
  void updateMenu() {
    int len = -(itemHeight * items.size()) + getHeight();
    npos = constrain(npos, len, 0);
    pos += (npos - pos) * 0.1;
    menu.beginDraw();
    menu.noStroke();
    menu.background(64 );
    menu.textFont(cp5.getFont().getFont());
    menu.pushMatrix();
    menu.translate( 0, pos );
    menu.pushMatrix();

    int i0 = PApplet.max( 0, int(map(-pos, 0, itemHeight * items.size(), 0, items.size())));
    int range = ceil((float(getHeight())/float(itemHeight))+1);
    int i1 = PApplet.min( items.size(), i0 + range );

    menu.translate(0, i0*itemHeight);

    for (int i=i0;i<i1;i++) {
      Map m = items.get(i);
      menu.fill(100);
      menu.rect(0, 0, getWidth(), itemHeight-1 );
      menu.fill(255);
      //menu.textFont(f1);
      menu.text(m.get("headline").toString(), 10, 20 );
      //menu.textFont(f2);
      menu.textLeading(12);
      menu.image((PImage)m.get("jpgFile"), 110, 10, 50, 50 );
      menu.translate( 0, itemHeight );
    }
    menu.popMatrix();
    menu.popMatrix();
    menu.endDraw();
    updateMenu = abs(npos-pos)>0.01 ? true:false;
  }
  
  /* when detecting a click, check if the click happend to the far right, if yes, scroll to that position, 
   * otherwise do whatever this item of the list is supposed to do.
   */
  public void onClick() {
    if (getPointer().x()>getWidth()-10) {
      npos= -map(getPointer().y(), 0, getHeight(), 0, items.size()*itemHeight);
      updateMenu = true;
    } 
    else {
      int len = itemHeight * items.size();
      int index = int( map( getPointer().y() - pos, 0, len, 0, items.size() ) ) ;
      setValue(index);
    }
  }
  
  public void onMove() {
  }

  public void onDrag() {
    npos += getPointer().dy() * 2;
    updateMenu = true;
  } 

  public void onScroll(int n) {
    npos += ( n * 4 );
    updateMenu = true;
  }

  void addItem(Map<String, Object> m) {
    items.add(m);
    if(items.size()>0){
      setHeight(min(items.size()*100, height-20));
    }
    updateMenu = true;

  }
  
  Map<String,Object> getItem(int theIndex) {
    return items.get(theIndex);
  }
  void removeItem(File file) {

    Iterator<Map<String,Object>> i = items.iterator();
    while (i.hasNext()) {
      Map<String,Object> o = i.next();
      if(file.getName().equals(o.get("name"))){
        i.remove();
        deleteDirectory(file);
        updateMenu = true;
        return;
      }
    }
  }
}