FROM registry.access.redhat.com/ubi9/nginx-126

ARG CONTENT

USER 0
RUN microdnf install -y jq && microdnf clean all -y
USER 1001

ENV CONTENT=${CONTENT:-content}
ENV NGINX_PORT=8080

COPY src/nginx/. /compliance_ssg/
COPY ${CONTENT}/. /content

ENTRYPOINT ["/compliance_ssg/entrypoint.sh"]
