FROM registry.access.redhat.com/ubi9/nginx-126

ARG CONTENT

ENV CONTENT=${CONTENT:-content}
ENV NGINX_PORT=8080

COPY src/nginx/. /compliance_ssg/
COPY ${CONTENT}/. /content

ENTRYPOINT ["/compliance_ssg/entrypoint.sh"]
