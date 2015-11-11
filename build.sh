#!/bin/bash
docker build -t mysqltest .
dockerid=$(docker run -d -t mysqltest /bin/bash);
docker cp $dockerid:/rootfs.tar /tmp/
docker rm -f $dockerid
docker import -c "CMD sh /usr/bin/supervisord.sh" /tmp/rootfs.tar testmysql
docker run -it testmysql sh /usr/bin/supervisord.sh
