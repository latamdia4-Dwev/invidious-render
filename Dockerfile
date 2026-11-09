# Build multi-etapa para Render.com
FROM docker.io/crystallang/crystal:1-alpine AS builder

RUN apk add --no-cache sqlite-static yaml-static git

WORKDIR /invidious

COPY ./shard.yml ./shard.lock ./
RUN shards install --production

COPY ./src/ ./src/
COPY ./scripts/ ./scripts/
COPY ./assets/ ./assets/
COPY ./videojs-dependencies.yml ./videojs-dependencies.yml

# Dependencias del reproductor: se descargan en un paso aislado (con log y timeout)
# en vez de dentro de una macro de compilacion, donde un fallo de red queda mudo.
RUN timeout 600 crystal run ./scripts/fetch-player-dependencies.cr -- --minified && \
    ls -R ./assets/videojs | head -50

# src/invidious.cr requiere un repo git para CURRENT_BRANCH/COMMIT/VERSION;
# el ZIP no incluye .git, se genera uno sintetico.
RUN git init -q -b master . && \
    git -c user.name=render -c user.email=render@localhost add -A >/dev/null 2>&1 && \
    git -c user.name=render -c user.email=render@localhost commit -q -m "render build"

# -no-pie: ver https://github.com/crystal-lang/distribution-scripts/issues/445
RUN crystal build ./src/invidious.cr \
    --release -p --mcpu=x86-64-v2 \
    --static --warnings all \
    -Dskip_videojs_download -Dminified_player_dependencies \
    --link-flags "-lxml2 -llzma -no-pie"

FROM alpine:3.22
RUN apk add --no-cache rsvg-convert ttf-opensans tini tzdata
WORKDIR /invidious
RUN addgroup -g 1000 -S invidious && adduser -u 1000 -S invidious -G invidious
COPY --chown=invidious ./config/config.render.yml ./config/config.yml
COPY ./config/sql/ ./config/sql/
COPY ./locales/ ./locales/
COPY --from=builder /invidious/assets ./assets/
COPY --from=builder /invidious/invidious .
RUN chmod o+rX -R ./assets ./config ./locales

EXPOSE 10000
USER invidious
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/invidious/invidious"]
