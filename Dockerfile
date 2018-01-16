FROM BASEIMAGE
ENV PORTAGE_REF

COPY ./portage  /usr/portage
COPY ./Makefile /usr/src/Makefile

RUN set -ex \
    && cd /usr/src \
    && make emerge \
    && rm -rf /usr/portage /usr/src/Makefile \
    && mkdir /usr/portage
