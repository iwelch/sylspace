From perl:5.26

RUN apt-get update
RUN apt-get install -y libz-dev libssl-dev gcc make vim-tiny
RUN cpanm Carton 
RUN mkdir /usr/src/app

WORKDIR /usr/src/app

COPY cpanfile* /usr/src/app/
RUN carton install

RUN mkdir /var/sylspace

COPY . /usr/src/app/

RUN carton exec perl -Ilib ./initsylspace.pl -f

RUN echo '{}' > SylSpace-Secrets.conf

RUN carton exec -- prove -lr -j4 

RUN carton exec bin/load_site startersite

EXPOSE 3000

ENTRYPOINT [ "carton", "exec", "--" ]

CMD [ "morbo", "SylSpace" ]
