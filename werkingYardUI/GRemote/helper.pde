
  // Conversion, helpers etc

  class EnumXYZ
  {
    public String strVal[] = {"X", "Y", "Z"};
    public int X = 0;
    public int Y = 1;
    public int Z = 2;
    public int size() {
      return 3;
    }
    public int toAZ(int idx) {
      return idx+23;
    }
  }

  class EnumAZ
  {
    public String strVal[] = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"};
    public int A = 0; 
    public int B = 1;
    public int C = 2;
    public int D = 3;
    public int E = 4;
    public int F = 5;
    public int G = 6;
    public int H = 7;
    public int I = 8;
    public int J = 9;
    public int K = 10;
    public int L = 11;
    public int M = 12;
    public int N = 13;
    public int O = 14;
    public int P = 15;
    public int Q = 16;
    public int R = 17;
    public int S = 18;
    public int T = 19;
    public int U = 20;
    public int V = 21;
    public int W = 22;
    public int X = 23;
    public int Y = 24;
    public int Z = 25;
    public int size() {
      return 26;
    }
    public int toXYZ(int idx) {
      return idx-23;
    }
  }

  public boolean isInteger( String input )
  {  
    try  
    {  
      Integer.parseInt( input );  
      return true;
    }  
    catch(Exception e)  
    {  
      return false;
    }
  }

  public boolean isFloat( String input )
  {  
    try  
    {  
      Float.parseFloat( input );  
      return true;
    }  
    catch(Exception e)  
    {  
      return false;
    }
  }

  public float[] polar2cartesian(float r, float t) {
    float[] xy = { 0.0f, 0.0f };
    xy[idx.X] = (float)(r*Math.cos(Math.toRadians(t)));
    xy[idx.Y] = (float)(r*Math.sin(Math.toRadians(t)));
    return xy;
  }

  public String floatCoord(int coord) {
    return String.valueOf((float)coord/resolution);
  }

  public int intCoord(float coord) {
    return (int)(coord*resolution);
  }

  public int[] intCoord(float[] f) {
    int[] I = new int[f.length];
    for (int i=0; i<f.length; i++) I[i] = intCoord(f[i]);
    return I;
  }

  public void unmount(String diskPath){
    String [] CMD = new String[] { "" , "", ""};
    if(PLATEFORM == OSX){
      CMD[0] = "diskutil";
      CMD[1] = "umount";
      CMD[2] = diskPath;
      exec(CMD);
      return;
    }
    if(PLATEFORM == LINUX){
      CMD[0] = "umount";
      CMD[1] = diskPath;
      CMD[2] = "";
      exec(CMD);
      return;
    }
    console_println("UNKNOW plateform : unable to unmount");
  }
  public int getPlateform(){
    Properties props=System.getProperties(); 
    String osName = props.getProperty("os.name");
    console_println(osName);
    if(osName.indexOf("Mac")>-1){
      PLATEFORM = OSX;
      return OSX;
    }else if(osName.indexOf("Linux")>-1){
      PLATEFORM = LINUX;
      return LINUX;
    }
    PLATEFORM = UNKNOW;
    return UNKNOW;
  }

  public ArrayList<File> getMountedDisk() {
    String diskPath = PLATEFORM == OSX ? "/Volumes/" : (PLATEFORM == LINUX ? "/media/pi/" : ""); 
    File f = new File(diskPath);
    return new ArrayList<File>(Arrays.asList(f.listFiles()));
  }

  public ArrayList<File> getFiles(String root, String end_with) {
    File f = new File(root);
    return getFiles(f, end_with);
  }


  public ArrayList<File> getFiles(File root, String end_with) {
    File [] files = root.listFiles();
    ArrayList<File> _files = new ArrayList<File>();
    for(int j = 0 ; j < files.length ; j ++){
      if(files[j].getName().toLowerCase().endsWith(end_with)){
        _files.add(files[j]);
      }    
    }
    return _files;
  }

  public void copyFolder(File src, File dest) throws IOException{

      if(src.isDirectory()){

        //if directory not exists, create it
        if(!dest.exists()){
           dest.mkdir();
        }

        //list all the directory contents
        String files[] = src.list();

        for (String file : files) {
           //construct the src and dest file structure
           File srcFile = new File(src, file);
           File destFile = new File(dest, file);
           //recursive copy
           copyFolder(srcFile, destFile);
        }

      }else{
        //if file, then copy it
        Files.copy(src.toPath(), dest.toPath());
      }
    }
    public boolean deleteDirectory(File dir) {
      if(! dir.exists() || !dir.isDirectory())    {
        return false;
      }

      String[] files = dir.list();
      for(int i = 0, len = files.length; i < len; i++)    {
        File f = new File(dir, files[i]);
        if(f.isDirectory()) {
            deleteDirectory(f);
        }else   {
            f.delete();
        }
      }
      if(dir.delete()){
        console_println(dir.getName() + " is deleted!");
        return true;
      }else{
        console_println("Delete operation is failed.");
        return false;
      }
}