#!/bin/bash
#FlashSucker 0.59999924ish
#by lrvick and Viaken

#Default site (crunchyroll.com, youtube.com)
default="crunchyroll"

#your media player and args of choice, must have flv support, mplayer or vlc will do the job
mediap="mplayer -vo fbdev -vf scale=1280:800"

#CrunchyRoll.com subscriber UserID and Key (found in your browsers cookie file)
cruserid=1698336
cruserkey=9505ssosq21sqp7p1qn8

#Browser to pretend to be
header="Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)"

if [ "$*" = "" ] ; then
 echo 'Usage: deadflash.sh [-opts] [Direct URL] [search terms]'
fi

terms=`echo $*| tr ' ' '+'`

function youtube {
  if [[ `echo $1 | grep youtube.com` ]] ; then
   ${mediap} "http://youtube.com/get_video.php?"`curl -s $1 | grep "watch_fullscreen" | sed "s;.*\(video_id.\+\)&title.*;\1;"`
   exit
  fi
  search=`curl -s -A "${header}" "http://youtube.com/results?search_query=${terms}&search=Search"| grep watch?`
  results=`for line in ${search} ;do echo $line| grep href | sed -e 's#href="/watch?v=##g;s#"##';done`
  results=`echo ${results} | sed -e 's/ /\n/g' | uniq`
  for id in ${results} ;
    do
      realid=`curl -s -A "${header}" http://youtube.com/watch?v=${id} | grep "watch_fullscreen" | sed "s;.*\(video_id.\+\)&title.*;\1;"`
      tubeline="$tubeline http://youtube.com/get_video.php?${realid}"
    done
  ${mediap} \"${tubeline}\"
}

function crunchyroll {
if [[ `echo $1 | grep crunchyroll.com` ]] ; then
 echo "http://youtube.com/get_video.php?"`curl -s $1 | grep "watch_fullscreen" | sed "s;.*\(video_id.\+\)&title.*;\1;"`
 exit
fi
rawresults=`curl -s -A "${header}" -b "c_userid=${userid};c_userkey=${userkey};smv=-1" "http://www.crunchyroll.com/search?q=${terms}"| grep showmedia | sed 's#</td></tr> #\n#g' | tr ' ' '_'| sed 's#</td></tr># #g'| grep "</a><br_/>` 
num=1
if [[ `echo $rawresults| wc -l` != 1 ]] ;then
  echo "Multiple Matches:"
  for each in $rawresults
    do
      #echo ${each};
      id[num]=`echo ${each} | sed -n '/showmedia/s/.*id=\([^'\'']*\).*/\1/p'`
      desc=`echo ${each} | sed 's/.*_title='\"'\([^'\'']*\)'\"'.*/\1/p' |uniq | tr '_' ' '`
      echo ${num} - ${desc}
      let num=num+1
    done
  echo "Enter Video Number #"
  read -e SEL
  mediaid=${id[$SEL]}
else
  mediaid=`echo ${each} | sed -n '/showmedia/s/.*id=\([^'\'']*\).*/\1/p'`
fi
hash=`curl -s -A "${header}" -b "c_userid=${cruserid};c_userkey=${cruserkey};smv=-1" "http://www.crunchyroll.com/showmediafs?id=${mediaid}&hires=1" | sed -n '/flashvars/s/.*%3Fih%3D\([^%]*\)%26.*/\1/p'`
videoid=`curl -s -A "${header}" -b "c_userid=${cruserid};c_userkey=${cruserkey};smv=-1" "http://www.crunchyroll.com/showmediafs?id=${mediaid}&hires=1" |sed -n '/flashvars/s/.*videoid%3D\([^%]*\)%26.*/\1/p'`
fakeurl="http://www.crunchyroll.com/getitem?ih=${hash}&videoid=${videoid}&mediaid=${mediaid}&autoStart=true&delay=3&hash=${hash}&fs=true&cbinterval=300000&cburl=http://www.crunchyroll.com/logajax?req=smv&mediaid=${mediaid}&userid=${userid}&cbcount=1"
realurl=`curl -s -A "{$header}" -b "c_userid=${cruserid};c_userkey=${cruserkey};smv=-1" -I "${fakeurl}" |grep Location | sed -e 's#Location: ##g'`
touch video.flv && rm video.flv && wget "`echo ${realurl} | tr -d '\r' `" &
sleep 10
${mediap} video.flv && killall wget && rm video.flv
}

if [[ $1 = *-cr* ]] ;then
   crunchyroll `echo $* | sed 's#-cr##g' |tr ' ' '+'`
   exit
# else if [[ $1 = *-yt* ]] ;then
#   youtube `echo $* | sed 's#-yt##g' |tr ' ' '+'`
#   exit
 else 
   ${default} `echo $* | tr ' ' '+'`
fi



