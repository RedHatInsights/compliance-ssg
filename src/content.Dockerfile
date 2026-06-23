FROM registry.access.redhat.com/ubi9-minimal as builder

ARG REPOSITORY
ARG REVISION
ARG RHEL_VERSIONS

ENV REPOSITORY=${REPOSITORY:-ComplianceAsCode/content}
ENV REVISION=${REVISION:-v0.1.81}
ENV RHEL_VERSIONS=${RHEL_VERSIONS:-"rhel8 rhel9 rhel10"}
ENV WORKDIR="/workdir"

RUN microdnf -y install jq tar gzip make cmake git python3 python3-pip python3-pyyaml python3-jinja2 libxml2 libxslt openscap openscap-scanner findutils && \
      pip3 install lxml && \
      microdnf clean all

WORKDIR $WORKDIR
COPY src/build_content.sh /compliance_ssg/build_content.sh

RUN /compliance_ssg/build_content.sh "$REPOSITORY" "$REVISION" "$RHEL_VERSIONS"
