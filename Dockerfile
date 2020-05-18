From perl:5.30

RUN apt-get update
RUN apt-get install -y libz-dev libssl-dev gcc make emacs-nox git
RUN cpanm Carton && mkdir /usr/src/app

WORKDIR /usr/src/app

COPY cpanfile* /usr/src/app/
RUN carton install

RUN apt-get install -y rsync

COPY . /usr/src/app/

RUN carton exec perl -Ilib ./initsylspace.pl

RUN carton exec prove -l t/SylSpace/Model/mkstartersite.t

RUN carton exec perl -Ilib bin/addsite.pl mysample.course instructor@gmail.com

RUN touch /var/sylspace/domainname=lvh.me

EXPOSE 3000

CMD [ "carton", "exec", "morbo", "SylSpace" ]
