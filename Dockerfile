From perl:5.26

RUN apt-get update
RUN apt-get install -y libz-dev libssl-dev gcc make emacs-nox git vim-tiny rsync
RUN cpanm Carton 
RUN mkdir /usr/src/app

WORKDIR /usr/src/app

COPY cpanfile* /usr/src/app/
RUN carton install

RUN mkdir /var/sylspace

COPY . /usr/src/app/

RUN carton exec perl -Ilib ./initsylspace.pl -f

RUN carton exec prove -l t/00mkstartersite.t

RUN carton exec perl -Ilib bin/addsite.pl mysample.course instructor@gmail.com

RUN touch /var/sylspace/domainname=lvh.me

EXPOSE 3000

CMD [ "carton", "exec", "morbo", "SylSpace" ]
