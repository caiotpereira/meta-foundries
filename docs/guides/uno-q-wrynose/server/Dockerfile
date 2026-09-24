FROM golang:1.25-bookworm AS build
RUN apt-get update && apt-get install -y --no-install-recommends git-lfs \
    && rm -rf /var/lib/apt/lists/*
ARG SERVER_REV=208e846d50febb6024953ff5a0079b45b900a58b
RUN git init /src/server && cd /src/server \
    && git remote add origin https://github.com/foundriesio/update-server.git \
    && git fetch --depth 1 origin "${SERVER_REV}" \
    && git checkout --detach FETCH_HEAD && git lfs pull
WORKDIR /src/server
RUN go build -o /out/fioserver ./cmd/server \
    && CGO_ENABLED=0 go build -tags nodb -o /out/fiocli ./cmd/cli
ARG COMPOSEAPP_REV=0af6d7702713f36848ae569dc7a6c7f05f1d2abe
RUN git init /src/composeapp && cd /src/composeapp \
    && git remote add origin https://github.com/foundriesio/composeapp.git \
    && git fetch --depth 1 origin "${COMPOSEAPP_REV}" \
    && git checkout --detach FETCH_HEAD
WORKDIR /src/composeapp
RUN CGO_ENABLED=0 go build -o /out/composectl ./cmd/composectl

FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*
ARG GUIDE_UID=1000
ARG GUIDE_GID=1000
RUN test "${GUIDE_UID}" -gt 0 && test "${GUIDE_GID}" -gt 0 \
    && (getent group "${GUIDE_GID}" || groupadd --gid "${GUIDE_GID}" guide) \
    && useradd --no-log-init --uid "${GUIDE_UID}" --gid "${GUIDE_GID}" \
        --create-home --shell /usr/sbin/nologin guide \
    && install -d -m 0700 -o guide -g "${GUIDE_GID}" /data /home/guide/.config \
    && install -d -m 0755 -o guide -g "${GUIDE_GID}" /work
COPY --from=build /out/fioserver /out/fiocli /out/composectl /usr/local/bin/
WORKDIR /work
USER guide
CMD ["fioserver", "--datadir=/data", "serve"]
