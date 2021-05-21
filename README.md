# compliance-ssg

Image that builds and serves RHEL ssg playbooks from an NGINX HTTP server.

### Build

```
podman build -f . compliance-ssg:latest
```

### Run

```
podman run -d --name compliance-ssg-playbooks -p 8080:8080 compliance-ssg
```

