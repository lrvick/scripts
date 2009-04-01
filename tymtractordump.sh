# A simple script I wrote for a client that wanted a listing of TWM tractor dealers to market to.

#This is dirty, inconsiderate, and mean to the server. I only used it once and it payed for some food...

zipcodes=`cat zipcodes.txt`
for each in $zipcodes; do
  elinks -dump "http://tym-usa.com/locator.php?ZIP=$each&Save=yes&=Find+Dealers" | grep E-mail | egrep -o "\w+([._-]\w)*@\w+([._-]\w)*\.\w{2,4}"
done
