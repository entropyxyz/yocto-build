FROM docker.io/crops/poky@sha256:f51ae3279f98768514273061336421e686e13d0a42fdb056c0b88c9afeec8c56 as builder

USER root
RUN apt install -y repo

ADD build.sh /usr/bin/build
RUN chmod +x /usr/bin/build

ARG MANIFEST
ENV MANIFEST_FILE=${MANIFEST}

ARG REVISION=main
ENV REVISION=${REVISION}

ARG CVM_SERVICE_SRC_REV
ENV CVM_SERVICE_SRC_REV=${CVM_SERVICE_SRC_REV}

ARG CVM_SERVICE_SRC_BRANCH
ENV CVM_SERVICE_SRC_BRANCH=${CVM_SERVICE_SRC_BRANCH}

CMD /usr/bin/build
