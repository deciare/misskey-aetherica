FROM node:16.14.0-alpine3.15 AS base

ENV NODE_ENV=production

WORKDIR /misskey

ENV BUILD_DEPS autoconf automake file g++ gcc libc-dev libtool make nasm pkgconfig python3 zlib-dev git

FROM base AS builder

COPY . ./

RUN apk add --no-cache $BUILD_DEPS && \
    git submodule update --init && \
    yarn install && \
    yarn build && \
    rm -rf .git

FROM base AS runner
ARG gid=10101
ARG group=mk
ARG uid=10101
ARG user=mk

RUN apk add --no-cache \
    ffmpeg \
    tini

RUN addgroup -g $gid $group
RUN adduser -h /misskey -s /bin/sh -D -G mk -u $uid $user

ENTRYPOINT ["/sbin/tini", "--"]

COPY --from=builder --chown=$user:$group /misskey/node_modules ./node_modules
COPY --from=builder --chown=$user:$group /misskey/built ./built
COPY --from=builder --chown=$user:$group /misskey/packages/backend/node_modules ./packages/backend/node_modules
COPY --from=builder --chown=$user:$group /misskey/packages/backend/built ./packages/backend/built
COPY --from=builder --chown=$user:$group /misskey/packages/client/node_modules ./packages/client/node_modules
COPY --chown=$user:$group . ./

USER $user

CMD ["npm", "run", "migrateandstart"]

