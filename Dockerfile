FROM BASEIMAGE as builder
ENV PORTAGE_REF

COPY ./portage  /usr/portage
COPY ./Makefile /usr/src/Makefile

RUN set -ex \
    && cd /usr/src \
    && make emerge \
    && rm /usr/src/Makefile


FROM scratch
WORKDIR /
COPY --from=builder / /
CMD ["/bin/bash"]
