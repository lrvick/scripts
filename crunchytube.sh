#!/bin/bash
#CrunchyTube 0.59999924ish

#This no longer works with current CrunchyRoll and is a mess. 

#Most flash sites can be beaten with this type of logic however so this may be a good reference 
#for extracting flvs from the new crunchyroll or other sites that use flv embeds

#Default site (crunchyroll.com, youtube.com)
site="crunchyroll"

#your media player and args of choice, must have flv support, mplayer or vlc will do the job
mediap="mplayer -vo fbdev -vf scale=1280:800"

#CrunchyRoll.com subscriber UserID and Key (found in your browsers cookie file)
cruserid=1698336
cruserkey=9505ssosq21sqp7p1qn8

#Browser to pretend to be
header="Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)"

while getopts  "yclr: flag
do
if [[ $flag = y ]]; then
site=youtube
fi
if [[ $flag = c ]]; then
site=crunchyroll
fi
if [[ $flag = l ]]; then
list=1
fi
if [[ $flag = r ]]; then
respages=$OPTARG
fi
done

if [[ -z $* ]] ;then
  echo 'Usage: -y -c -l file [Direct URL] [search terms]'
  exit 1
fi

echo $*

terms=`echo $*| tr ' ' '+'`

function youtube {
  if [[ `echo $* | grep youtube.com` ]] ; then
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
if [[ `echo $* | grep crunchyroll.com` ]] ; then
 echo "http://youtube.com/get_video.php?"`curl -s $1 | grep "watch_fullscreen" | sed "s;.*\(video_id.\+\)&title.*;\1;"`
 exit
fi
rawresults=`curl -s -A "${header}" -b "c_userid=${userid};c_userkey=${userkey};smv=-1" "http://www.crunchyroll.com/search?q=${terms}"| grep showmedia | sed 's#</td></tr> #\n#g' | tr ' ' '_'| sed 's#</td></tr># #g'| grep "</a><br_/>"` 
rawresults=`echo ${rawresults} && curl -s -A "${header}" -b "c_userid=${userid};c_userkey=${userkey};smv=-1" "http://www.crunchyroll.com/search?q=${terms}&pg=1%20-%202"| grep showmedia | sed 's#</td></tr> #\n#g' | tr ' ' '_'| sed 's#</td></tr># #g'| grep "</a><br_/>"`
num=1
#if [[ -n $list ]] ;then 
  echo "Multiple Matches:"
  for each in $rawresults
    do
      id[num]=`echo ${each} | sed -n '/showmedia/s/.*id=\([^'\'']*\).*/\1/p'`
      desc=`echo ${each} | sed 's/.*_title='\"'\([^'\'']*\)'\"'.*/\1/p' |uniq | tr '_' ' '`
      echo ${num} - ${desc}
      let num=num+1
    done
  echo "Enter Video Number #"
  read -e SEL
  mediaids=${id[$SEL]}
else 
  mediaids=`echo $rawresults | sed -n '/showmedia/s/.*id=\([^'\'']*\).*/\1/p'`
fi
for mediaid in $mediaids ;do
  hash=`curl -s -A "${header}" -b "c_userid=${cruserid};c_userkey=${cruserkey};smv=-1" "http://www.crunchyroll.com/showmediafs?id=${mediaid}&hires=1" | sed -n '/flashvars/s/.*%3Fih%3D\([^%]*\)%26.*/\1/p'`
  videoid=`curl -s -A "${header}" -b "c_userid=${cruserid};c_userkey=${cruserkey};smv=-1" "http://www.crunchyroll.com/showmediafs?id=${mediaid}&hires=1" |sed -n '/flashvars/s/.*videoid%3D\([^%]*\)%26.*/\1/p'`
  fakeurl="http://www.crunchyroll.com/getitem?ih=${hash}&videoid=${videoid}&mediaid=${mediaid}&autoStart=true&delay=3&hash=${hash}&fs=true&cbinterval=300000&cburl=http://www.crunchyroll.com/logajax?req=smv&mediaid=${mediaid}&userid=${userid}&cbcount=1"
  realurl=`curl -s -A "{$header}" -b "c_userid=${cruserid};c_userkey=${cruserkey};smv=-1" -I "${fakeurl}" |grep Location | sed -e 's#Location: ##g'`
  touch video.flv && rm video.flv && wget "`echo ${realurl} | tr -d '\r' `" &
  sleep 10
  ${mediap} video.flv && killall wget && rm video.flv
done
}

$site


