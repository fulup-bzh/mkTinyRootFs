# syntax=docker/dockerfile:1.2
# podman build -t iso15118 -f Dockerfile
# podman create --name afb-iso15118 --replace -p 1234:1234 -t localhost/iso15118 bash
# podman start afb-iso15118
# podman exec -it afb-iso15118 bash
# podman stop afb-iso15118

# STAGE 1: build the executable
FROM alpine:latest AS builder
RUN apk add --no-cache bash git gcc cmake make musl-dev json-c-dev yaml-dev libmicrohttpd-dev gnutls-dev linux-headers argp-standalone musl-fts-dev rpm2cpio wget busybox

ENV LD_LIBRARY_PATH=/usr/local/lib64
ENV PATH=/usr/local/bin:$PATH
WORKDIR /src

RUN <<EOF
    # clone afb source repositories
    git clone https://github.com/redpesk-core/afb-binding
    git clone https://github.com/redpesk-core/afb-libafb
    git clone https://github.com/redpesk-core/afb-binder
    git clone https://github.com/redpesk-core/rp-lib-utils

    # build afb-binder + dependencies
    (mkdir -p afb-binding/build && cd afb-binding/build && cmake .. && make -j install)
    (mkdir -p rp-lib-utils/build && cd rp-lib-utils/build && cmake .. && make -j install)
    (mkdir -p afb-libafb/build && cd afb-libafb/build && cmake -DWITH_SYSTEMD=0 -DWITH_LIBUUID=0 \
       -DWITHOUT_CYNAGORA=1 -DWITHOUT_TESTS=1 -DWITH_LIBMAGIC=0  -DWITH_FNMATCH=0 \
       -DWITH_SIG_MONITOR_DUMPSTACK=0 .. && make -j install)
    (mkdir -p afb-binder/build && cd afb-binder/build && cmake .. && make -j install)

    # extract devtools from no-archRPM
    wget https://download.redpesk.bzh/redpesk-lts/arz-1.1-update/packages/middleware/x86_64/os/Packages/a/afb-ui-devtools-1.0.4-2.redpesk.devtools.rparz_1.noarch.rpm
    (mkdir -p afb-ui-devtools && cd afb-ui-devtools && rpm2cpio ../afb-ui-devtools-1.0.4-2.redpesk.devtools.rparz_1.noarch.rpm \
       | cpio -idmv && mkdir -p /usr/local/share/afb-ui-devtools && mv usr/share/afb-ui-devtools/binder/* /usr/local/share/afb-ui-devtools/. \
    )

    # prepare tiny-root-fs with afb and minimal dependencies
    ( git clone https://github.com/fulup-bzh/mkTinyRootFs &&\
       cd mkTinyRootFs && wget https://raw.githubusercontent.com/fulup-bzh/mkTinyRootFs/master/Samples/oci-sample.conf &&\
       ./mkTinyRootFs.bash config=oci-sample.conf target=/tmp/stage2-rootfs \
    )

    # prepare stage 2 tmp directory
    mkdir -p /var/tmp/tmp

    echo "podman start afb-iso15118 && podman exec -it afb-iso15118 bash"
EOF
CMD ["/bin/bash"]


# # STAGE 2: build the container
FROM scratch As final
COPY --from=builder /tmp/stage2-rootfs/ /
COPY --from=builder /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
COPY --from=builder --chown=1000:1000 --chmod=0777 /var/tmp/tmp /
WORKDIR /tmp

# Busybox for debug
#COPY --from=builder /bin/busybox /bin/busybox

ENV LD_LIBRARY_PATH=/usr/local/lib64
ENV PATH=/usr/local/bin:$PATH
USER 10000:10000
CMD ["/usr/local/bin/afb-binder","--alias=/devtools:/usr/local/share/afb-ui-devtools","-vvv"]