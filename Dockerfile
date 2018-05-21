FROM debian:stretch

MAINTAINER crito <crito@blizzlike.org>

ENV APP_DIR /home/blizzlike
ENV CONTRIB_DIR ./contrib

RUN apt-get update && \
  apt-get -y install vim git \
    nginx libnginx-mod-http-lua \
    luarocks lua-cjson lua-sql-mysql lua-socket

RUN luarocks install luna && \
  luarocks install lbase64 && \
  luarocks install lua-salt && \
  luarocks install uuid && \
  mkdir -p /etc/luna /var/lib/luna/endpoints

RUN useradd \
  -m -d ${APP_DIR} \
  -s /bin/bash \
  -U blizzlike

WORKDIR ${APP_DIR}

COPY --chown=blizzlike ./src ${APP_DIR}/core-api
COPY ${CONTRIB_DIR}/nginx.conf.dist /etc/nginx/nginx.conf
COPY ${CONTRIB_DIR}/luna.conf.dist /etc/nginx/conf.d/luna.conf
COPY ${CONTRIB_DIR}/rc.lua.dist /etc/luna/rc.lua
COPY ${CONTRIB_DIR}/run.sh ${APP_DIR}/run.sh

RUN ln -s ${APP_DIR}/core-api/endpoints /var/lib/luna/endpoints/v1 && \
  ln -s ${APP_DIR}/core-api/modules /var/lib/luna/modules

EXPOSE 80/tcp

VOLUME ["/etc/luna/core.lua"]
CMD ["/home/blizzlike/run.sh"]
