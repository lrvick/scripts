#!/bin/bash
#YouTubeRandom 0.9999999422ish

#Plays given YouTube URL takes search terms to play random videos with those search terms.

#Idea and prototype by me (Lance Reagan Vick) with some cleanup and regex help from David T. Pflug

#your media player and args of choice, must have flv support, mplayer or vlc will do the job
mediap="mplayer -vo fbdev -vf scale=1280:800"
terms="$*"

if [ "$terms" = "" ] ; then
 echo 'Usage: yts.sh [YouTube URL] [search terms]'
fi

if [[ `echo ${terms} | grep youtube.com` ]] ; then
 echo "http://youtube.com/get_video.php?"`curl -s $1 | grep "watch_fullscreen" | sed "s;.*\(video_id.\+\)&title.*;\1;"`
 exit
fi

terms=`echo ${terms}| tr ' ' '+'`

search=`curl -s "http://youtube.com/results?search_query=${terms}&search=Search"| grep watch?`
results=`for line in ${search} ;do echo $line| grep href | sed -e 's#href="/watch?v=##g;s#"##';done`
results=`echo ${results} | sed -e 's/ /\n/g' | uniq`

for id in ${results} ;
 do
    realid=`curl -s http://youtube.com/watch?v=${id} | grep "watch_fullscreen" | sed "s;.*\(video_id.\+\)&title.*;\1;"`
    tubeline="$tubeline http://youtube.com/get_video.php?${realid}"
done

    ${mediap} \"${tubeline}\"
