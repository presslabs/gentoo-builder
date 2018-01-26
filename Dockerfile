ARG SNAPSHOT=latest
ARG PORTAGE_IMAGE=docker.io/gentoo/portage:${SNAPSHOT}
ARG STAGE3_IMAGE=docker.io/gentoo/stage3-amd64-hardened:${SNAPSHOT}

ARG GENTOO_MIRRORS=http://mirror.leaseweb.com/gentoo/

# we need a portage snapshot
FROM ${PORTAGE_IMAGE} as portage

# build all the packages
FROM ${STAGE3_IMAGE} as builder
ARG GENTOO_MIRRORS
ENV GENTOO_MIRRORS=${GENTOO_MIRRORS}

COPY --from=portage /usr/portage /usr/portage
COPY ./files/ /

RUN set -ex \
    && env \
    && emerge --info

# update @world to new use flags and new pakage versions
RUN set -ex \
    && emerge -j4 -gk --pretend --update --changed-use sys-libs/glibc \
    && emerge -j4 -gk           --update --changed-use sys-libs/glibc

RUN set -ex \
    && emerge -j4 -gk --pretend --update --changed-use sys-devel/gcc \
    && emerge -j4 -gk           --update --changed-use sys-devel/gcc

RUN set -ex \
    && emerge -j4 -gk --pretend -uDU --with-bdeps=y @world \
    && emerge -j4 -gk           -uDU --with-bdeps=y @world \
    && emerge -j4 --depclean \
    && emerge -j4 -gk @preserved-rebuild

# install some additional packages (git, curl and layman)
RUN set -ex \
    && emerge --info \
    && emerge -j4 -gk --pretend dev-vcs/git net-misc/curl app-portage/layman \
    && emerge -j4 -gk           dev-vcs/git net-misc/curl app-portage/layman

RUN set -ex \
    && rm -rf /usr/portage/metadata/md5-cache/ \
    && rm -rf /usr/portage/packages/ \
    && rm -rf /usr/portage/distfiles/

FROM scratch
ARG GENTOO_MIRRORS
ENV GENTOO_MIRRORS=${GENTOO_MIRRORS}
WORKDIR /
COPY --from=builder / /
CMD ["/bin/bash"]
