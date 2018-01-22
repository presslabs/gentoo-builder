ARG PORTAGE_IMAGE=docker.io/gentoo/portage:20180122
ARG STAGE3_IMAGE=docker.io/gentoo/stage3-amd64-hardened-nomultilib:20180122
ARG GENTOO_MIRRORS=http://mirror.leaseweb.com/gentoo/
ARG PORTAGE_BINHOST=https://storage.googleapis.com/gentoo.presslabs.net/packages/latest

# we need a portage snapshot
FROM ${PORTAGE_IMAGE} as portage

# build all the packages
FROM ${STAGE3_IMAGE} as builder
ARG GENTOO_MIRRORS
ARG PORTAGE_BINHOST
ENV PORTAGE_BINHOST=${PORTAGE_BINHOST}
ENV GENTOO_MIRRORS=${GENTOO_MIRRORS}

COPY --from=portage /usr/portage /usr/portage
COPY ./builder/ /

RUN set -ex \
    && env \
    && emerge --info
    # && make emerge \
    # && rm /usr/src/Makefile \
    # && rm -rf /usr/portage/packages

RUN set -ex \
    && emerge -j4 -gk --pretend -uDU --with-bdeps=y @world \
    && emerge -j4 -gk           -uDU --with-bdeps=y @world

RUN set -ex \
    && emerge -j4 --depclean

ENV FEATURES="sandbox usersandbox userpriv"
RUN set -ex \
    && emerge --info
    && emerge -j4 -gk --pretend dev-vcs/git net-misc/curl app-portage/layman \
    && emerge -j4 -gk           dev-vcs/git dev-libs/libassuan-2.5.1 \
    || cat /var/tmp/portage/dev-libs/libassuan-2.5.1/temp/build.log


# FROM scratch
# ARG GENTOO_MIRRORS
# ARG PORTAGE_BINHOST
# ENV PORTAGE_BINHOST=${PORTAGE_BINHOST}
# ENV GENTOO_MIRRORS=${GENTOO_MIRRORS}
# WORKDIR /
# COPY --from=builder / /
# CMD ["/bin/bash"]
