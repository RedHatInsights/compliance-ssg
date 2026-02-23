# compliance-ssg

Image to serve SCAP compliance content (datastreams and Ansible playbooks) from an NGINX HTTP server. Content is generated from the upstream [ComplianceAsCode/content](https://github.com/ComplianceAsCode/content) repository.

### Generating content

Run the generation script to download and build content from ComplianceAsCode/content into the local `content` directory:

```
./src/generate_content.sh
```

#### Building the HTTP server and bundling the content to serve

If you need to manually bundle the content to serve, simply use the Dockerfile.
This build essentially copies the `content` directory into the image and
configures nginx to serve it.

```
podman build -t compliance-ssg .
```

There are several build arguments available, which can be specified with `--build-arg`.

- `CONTENT` The directory to be copied and served by nginx (default: `content`)
- `REVISION` The upstream git reference (default: `''`)

### Run

To run locally:

```
podman run -d --name compliance-ssg-playbooks -p 8080:8080 compliance-ssg
```
