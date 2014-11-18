--- .profile.orig	2014-06-20 15:48:23.000000000 +1000
+++ .profile	2014-11-18 15:29:33.753243142 +1000
@@ -20,3 +20,8 @@
 if [ -d "$HOME/bin" ] ; then
     PATH="$HOME/bin:$PATH"
 fi
+
+DIR=$HOME
+sudo python $DIR/scripts/rawProg.py $DIR/scripts/start.txt
+sudo python $DIR/scripts/regProg.py $DIR/settings/defaults/pi.set
+sudo bash $DIR/gbs-control.sh
