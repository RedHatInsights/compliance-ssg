FROM registry.access.redhat.com/ubi8-minimal as builder

ARG REPOSITORY
ARG REVISION
ARG RHEL_VERSIONS

ENV REPOSITORY=${REPOSITORY:-ComplianceAsCode/content}
ENV REVISION=${REVISION:-v0.1.53}
ENV RHEL_VERSIONS=${RHEL_VERSIONS:-"rhel7 rhel8 rhel9"}
ENV WORKDIR="/workdir"

RUN microdnf update && microdnf install jq tar gzip make cmake python3 python3-pyyaml python3-jinja2 openscap-utils && microdnf clean all

WORKDIR $WORKDIR
COPY src /compliance_ssg

RUN /compliance_ssg/generate_playbooks.sh "$REPOSITORY" "$REVISION" "$RHEL_VERSIONS"
RUN /compliance_ssg/generate_nginx_conf.sh /compliance_ssg/data/nginx_conf_template ${REVISION} > default.conf

FROM registry.access.redhat.com/ubi8/nginx-118

COPY --from=builder "/workdir/default.conf" "${NGINX_DEFAULT_CONF_PATH}"
COPY --from=builder "/workdir/playbooks" playbooks

# Run script uses standard ways to run the application
CMD nginx -g "daemon off;"
