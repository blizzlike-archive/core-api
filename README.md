# api for wow core

this is an api for our wow core based on the [nginx lua module](https://github.com/openresty/lua-nginx-module).
the api documentation is available [here](https://docs.blizzlike.org/core-api).

## instructions

### docker

    docker pull blizzlike/core-api:stable
    docker run --name core-api \
      -v /path/to/etc/core.lua:/etc/luna/core.lua \
      -p 9095:80 -d blizzlike/core-api:stable

### migrate database

    lua5.1 ./migrate <db> <user> <pass> <host> [<port>]

## generate docs

    make documentation
