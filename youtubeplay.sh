#!/bin/bash
#Plays a given YouTube URL in your media player of choice

mplayer -fs $(echo "http://youtube.com/get_video.php?`curl $1 | grep "watch_fullscreen" | sed "s;.*\(video_id.\+\)&title.*;\1;"`")

