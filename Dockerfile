FROM BASEIMAGE

COPY portage /usr/portage

COPY packages /usr/portage/packages

RUN set -ex \
    && sh -c 'readlink /etc/portage/make.profile | grep no-multilib 2>&1 >/dev/null && eselect profile set default/linux/amd64/17.0/no-multilib || eselect profile set default/linux/amd64/17.0' \
    && emerge -uDU --usepkg --keep-going --with-bdeps=y @world \
    && emerge --depclean
