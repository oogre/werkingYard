echo "# GO TO /home/pi/werkingYard/werkingYard"
cd /home/pi/werkingYard/werkingYard
echo "# git pull werkingYard"
git pull
echo "# SETUP DISPLAY 0"
export DISPLAY=:0
echo "# starting APP"
processing-java --sketch=/home/pi/werkingYard/werkingYard/werkingYardUI/GRemote --present