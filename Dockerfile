FROM node:16.14.0-alpine3.15 AS base

ENV NODE_ENV=production

WORKDIR /misskey

ENV BUILD_DEPS autoconf automake file g++ gcc libc-dev libtool make nasm pkgconfig python3 zlib-dev git

FROM base AS builder

RUN addgroup -g 10101 mk \
	&& adduser -h /misskey -s /bin/sh -D -G mk -u 10101 mk

COPY . ./

RUN chown -R mk:mk .

RUN apk add --no-cache $BUILD_DEPS && \
    su - mk -c 'git submodule update --init' && \
    su - mk -c 'yarn install' && \
    su - mk -c 'yarn build' && \
    rm -rf .git

FROM base AS runner

RUN apk add --no-cache \
    ffmpeg \
    tini

ENTRYPOINT ["/sbin/tini", "--"]

COPY --from=builder /misskey/node_modules ./node_modules
COPY --from=builder /misskey/built ./built
COPY --from=builder /misskey/packages/backend/node_modules ./packages/backend/node_modules
COPY --from=builder /misskey/packages/backend/built ./packages/backend/built
COPY --from=builder /misskey/packages/client/node_modules ./packages/client/node_modules
COPY . ./

CMD ["su", "-", "mk", "-c", "npm run migrateandstart"]

