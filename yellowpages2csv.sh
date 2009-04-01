# YellowPages.com to CSV converter
#
#This is a ghetto script written years ago for a customers project to create a CSV file from information scraped from yellowpages.com
#
# YellowPages has since overhauled their site and this is now only useful for reference.
#
#usage state firstpagenumber lastpagenumber

category="food"

#query
QW=${1}
#state
ST=${2}
#first page number
FPN=${3}
#last page number
LPN=${4}

ssid=`elinks -dump "http://anywho.yellowpages.com/sp/co/anywho/aw_ypresults.jsp?t=0&v=3&s=2&p=13&st=${1}&q=${QW}" | \
      grep jsessionid | \
      head -n1 | \
      sed 's#.*jsessionid=\(.*\);#\1#g'`

num=$2
while (( num<=$3 )) ; do
  elinks -dump -no-numbering -no-references \
  "http://anywho.yellowpages.com/sp/co/anywho/ypmore_refinements_add.jsp;${sessid}?t=0&v=3&s=2&p=${num}&q=#{category}&st=${1}&id=1&rType=headingtext" | \
  grep -B7 SEARCH | \
  sed -e 's#SEARCH NEARBY  \|  MAP  \|  DIRECTIONS##g' \
   -e 's#--##g' \
   -e 's#^.\{30\}##' \
   -e 's#^\(.*\w\)   .*$#\1#' \
   -e 's#\[IMG\]##g' \
   -e '/||/d' \
   -e 's#^\s*-\s*$##' \
   -ne '/\S/ { H } ; /^$/ { x;s/\n/,/g;p }' | \
   sed -e 's/^,//' \
   -e '/^$/d' \
   -e '/.*[^[:digit:]]$/d' \
   -e 's/More Info//' \
   -e 's/\s*Online,//' \
   >> addressdump_${1} ;
   echo ${num} ${sessid}
  let num=num+1
done

echo $ssid
