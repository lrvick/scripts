for letter in {a..z}; do
  lastpage=`curl -s 'http://www.dafont.com/alpha.php?nb_ppp_old=50&page=1&lettre='${letter}'&text=test&nb_ppp=50&psize=s&classt=alpha&l\[\]=10&l\[\]=1' | egrep -o 'page=[[:digit:]]+' | tail -n 2 | head -n 1 | sed 's/page=//g'`
  for ((pagenum=1; pagenum<=$lastpage; pagenum++)); do 
    for url in `curl -s 'http://www.dafont.com/alpha.php?nb_ppp_old=50&page='${pagenum}'&lettre='${letter}'&text=test&nb_ppp=50&psize=s&classt=alpha&l\[\]=10&l\[\]=1' | egrep -o "http://img\.dafont\.com/dl/\?f=\w*"`; do
      aria2c -d dafonts "${url}"
    done
  done
done
