FROM registry.access.redhat.com/ubi8-minimal as builder

ARG REPOSITORY
ARG REVISION
ARG RHEL_VERSIONS

ENV REPOSITORY=${REPOSITORY:-ComplianceAsCode/content}
ENV REVISION=${REVISION:-v0.1.53}
ENV RHEL_VERSIONS=${RHEL_VERSIONS:-"rhel6 rhel7 rhel8"}
ENV WORKDIR="/workdir"

RUN microdnf update && microdnf install jq tar gzip make cmake python3 python3-pyyaml python3-jinja2 openscap-utils && microdnf clean all

WORKDIR $WORKDIR
COPY src/generate_playbooks.sh /compliance_ssg/generate_playbooks.sh

RUN /compliance_ssg/generate_playbooks.sh "$REPOSITORY" "$REVISION" "$RHEL_VERSIONS"

FROM registry.access.redhat.com/ubi8/nginx-118

USER 0

RUN dnf install -y jq && dnf clean all

USER 1001

ENV REVISION=${REVISION:-v0.1.53}

COPY --from=builder "/workdir/playbooks" playbooks

COPY src/clowder-config-common /compliance_ssg/
COPY src/nginx /compliance_ssg/

RUN /compliance_ssg/generate_nginx_conf.sh /compliance_ssg/nginx_conf_template "${REVISION}" > "${NGINX_DEFAULT_CONF_PATH}/default.conf"

# Run script uses standard ways to run the application
CMD /compliance_ssg/entrypoint.sh
