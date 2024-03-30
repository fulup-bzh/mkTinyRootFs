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
 - RUN  "./myTinyRootFs config=oci-sample.conf target=/tmp/myRootFs"
# during stage2
 - FROM gcr.io/distroless/static:nonroot AS final
 - COPY  --from=builder /tmp/myRootFs/* /



