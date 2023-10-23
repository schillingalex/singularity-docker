FROM golang:1.21.3-alpine as builder

################################################################################
#
# Copyright (C) 2019-2022 Vanessa Sochat.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
################################################################################

# alpine image with the go tools

RUN apk update && \
    apk add --virtual .build-deps autoconf automake build-base linux-headers libffi-dev
RUN apk add --no-cache bash git openssh gcc squashfs-tools sudo libtool gawk cryptsetup glib-dev tzdata bash glib-dev
RUN apk add --no-cache linux-headers build-base openssl-dev util-linux util-linux-dev shadow-uidmap libseccomp-dev fuse3-dev

ENV SINGULARITY_VERSION=4.0.0
LABEL Maintainer @vsoch
RUN mkdir -p /usr/local/var/singularity/mnt && \
    mkdir -p $GOPATH/src/github.com/sylabs && \
    cd $GOPATH/src/github.com/sylabs && \
    wget -qO- https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}.tar.gz | \
    tar xzv && \
    cd singularity-ce-${SINGULARITY_VERSION} && \
    ./mconfig -p /usr/local/singularity && \
    make -C builddir && \
    make -C builddir install

# See https://docs.docker.com/develop/develop-images/multistage-build/
# for more information on multi-stage builds.
FROM alpine:3.10
LABEL Maintainer @vsoch
COPY --from=builder /usr/local/singularity /usr/local/singularity
RUN apk add --no-cache ca-certificates libseccomp squashfs-tools tzdata bash && \
    cp /usr/share/zoneinfo/UTC /etc/localtime
ENV PATH="/usr/local/singularity/bin:$PATH"
ENTRYPOINT ["/usr/local/singularity/bin/singularity"]
