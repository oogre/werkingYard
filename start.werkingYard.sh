echo "# GO TO /home/pi/werkingYard"
cd /home/pi/werkingYard
#echo "# git pull werkingYard"
#git pull
cd werkingYardUI
echo "# SETUP DISPLAY 0"
export DISPLAY=:0
echo "# starting APP"
processing-java --sketch=/home/pi/werkingYard/werkingYardUI/GRemote --run ${PWD}


#cd /Users/ogre/Work/7102/felix/WerkingYard
#git pull
#cd werkingYardUI
#sudo processing-java --sketch=/Users/ogre/Work/7102/felix/WerkingYard/werkingYardUI/GRemote --run ${PWD}
