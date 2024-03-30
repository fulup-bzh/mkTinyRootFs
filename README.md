# mkTinyRootFs
Create a tiny container rootfs

Author: Fulup Ar Foll (fulup@iod.bzh)
Date:   March 2024

Object: skim down phase-1 container runtime for minimal phase-2 runtime
Reference: https://github.com/fulup-bzh/mkTinyRootFs

Usage: From Dockerfile
-----------------------
# during stage-1
 - generate config file (cf: TargetSample.conf)
 - RUN  "./myTinyRootFs config=Samples/oci-sample.conf target=/tmp/myRootFs"
# during stage2
 - FROM scratch
 - COPY  --from=builder /tmp/myRootFs/* /

Sample: building afb-binder
----------------------------
  podman build -t tiny-rootfs -f Samples/Dockerfile
  podman run -p 1234:1234  -it localhost/tiny-rootfs
  firefox  http://localhost:134/devtools

