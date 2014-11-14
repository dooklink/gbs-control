--- .profile.bak	2014-11-14 15:26:14.281282853 +1000
+++ .profile	2014-11-14 15:29:44.314223214 +1000
@@ -20,3 +20,7 @@
 if [ -d "$HOME/bin" ] ; then
     PATH="$HOME/bin:$PATH"
 fi
+
+DIR=$HOME
+sudo python $DIR/scripts/rawProg.py $DIR/scripts/start.txt
+sudo bash $DIR/gbs-control.sh
