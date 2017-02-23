
  public void update_file_import() {
    ArrayList<File> currentDisks = getMountedDisk();
    ArrayList<File> currentDisksClone = new ArrayList<File>(currentDisks);
    currentDisksClone.removeAll(knownDisks);
    for (int i = 0; i<currentDisksClone.size(); i ++) {
      if(i == 0){
        delay(1000);
      }
      console_println(currentDisksClone.get(i) + " : MOUNTED");
      ArrayList<File> files = getFiles(currentDisksClone.get(i), extention);

      for(int j = 0 ; j < files.size() ; j ++){
       try{
          File newFile = new File(dataPath+"/"+files.get(j).getName());
          if(!newFile.exists()){
            Files.copy(files.get(j).toPath(), newFile.toPath());
            console_println(files.get(j).getName() + " :IMPORTED");
          }
        }catch(IOException error){
          println(error);
        }
      }
      delay(1000);
      exec(new String[] { "diskutil", "umount", currentDisksClone.get(i).getPath() });
      delay(1000);
      console_println(currentDisksClone.get(i) + " : UNMOUNTED");
    }
    knownDisks = currentDisks;
  }

  public void setup_file_import() {
    knownDisks = getMountedDisk();
  }