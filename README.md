# mkTinyRootFs
Create a minimal OCI (Docker/Podman) container rootfs

* Author: Fulup Ar Foll (fulup@iod.bzh)
* Date:   March 2024
* Object: skim down container runtime

Usage: From Dockerfile
-----------------------
# during stage-1
 - generate/wget rootfs config (cf: oci-sample.conf)
 - run./myTinyRootFs config=my-project-config.conf target=/tmp/myRootFs"
# during stage2
 - FROM scratch
 - COPY  --from=builder /tmp/myRootFs/* /

Sample: building afb-binder
----------------------------
  * podman build -t tiny-rootfs -f Samples/Dockerfile
  * podman run -p 1234:1234  -it localhost/tiny-rootfs
  * firefox  http://localhost:134/devtools

