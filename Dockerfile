FROM mysql

# switch to root to build image
# =================================================
USER root

# prepare rootfs
# =================================================
RUN mkdir /rootfs
WORKDIR /rootfs
RUN mkdir bin etc dev dev/pts lib usr proc sys tmp
RUN chmod 7777 tmp
RUN mkdir -p usr/lib64 usr/lib usr/bin usr/local/bin etc/init.d usr/sbin
RUN touch etc/resolv.conf
RUN cp /etc/nsswitch.conf etc/nsswitch.conf
RUN echo root:x:0:0:root:/:/bin/sh > etc/passwd
RUN echo mysql:x:500:500:root:/:/bin/sh >> etc/passwd
RUN echo root:x:0: > etc/group
RUN echo mysql:x:500: >> etc/group
# Starting sshd: Privilege separation user does not exist
RUN sed -i '/UsePrivilegeSeparation/aUsePrivilegeSeparation no' /etc/ssh/sshd_config
RUN cp -r --preserve=all /etc/ssh etc/
RUN ln -s lib lib64
RUN ln -s bin sbin
RUN ln -s bin/sh bin/bash

# install busybox
# =================================================
#ADD http://busybox.net/downloads/binaries/busybox-x86_64 /sbin/busybox
ADD /busybox-x86_64 /sbin/busybox
RUN chmod +x /sbin/busybox
RUN cp /sbin/busybox bin
RUN busybox --install -s bin

# extract mysql-server
# =================================================
RUN mdir=$(ls -d /usr/local/mysql-*) && mkdir -p ./$mdir && cp -r $mdir/{bin,etc,lib,share} ./$mdir && ln -sf $mdir usr/local/mysql

# extract mysql-server‘s dependencies
# =================================================
RUN bash -c "cp /lib64/lib{rt,m,dl,pthread,c,ncurses,tinfo}.so.* lib64/"
RUN cp /lib64/ld-linux-x86-64.so.2 lib64/
RUN bash -c "cp /usr/local/gcc/lib64/lib{gcc_s,stdc++}.so.* lib64"

# mkdir data and logs dir
RUN cp -r /data ./ && chown -R mysql.mysql data

# extract supervisor dependencies
RUN cp /etc/supervisord.conf etc/
RUN bash -c "cp /usr/bin/supervisor* usr/bin/"
RUN bash -c "cp /usr/bin/python* usr/bin/"
RUN bash -c "cp /usr/sbin/useradd usr/sbin"
RUN bash -c "cp -r /usr/lib64/python* usr/lib64/"
RUN bash -c "cp -r /usr/lib/python* usr/lib/"
RUN bash -c "cp /usr/lib64/libpython*.so* lib64/"
RUN bash -c "awk '\$3 ~ /\// {!a[\$3]++}END{for(i in a){system(\"/bin/cp \"i\" lib64/\")}}' <(ldd `which ssh-keygen`;ldd `which sshd`)"
RUN bash -c "cp /usr/sbin/sshd usr/sbin/;cp /usr/bin/ssh-keygen usr/bin"
RUN bash -c "cp /etc/init.d/mysqld etc/init.d/mysqld"
COPY /supervisord.sh usr/bin/supervisord.sh
RUN bash -c "chmod +x etc/init.d/* usr/sbin/* usr/bin/*"

# build rootfs
RUN tar cf /rootfs.tar . && echo "tar is overed!"
