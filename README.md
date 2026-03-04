# devops-task

Simple HTTP backend service deployed locally in Kubernetes.

## Stack
- C++ with cpp-httplib (header-only)
- Docker (multi-stage, distroless final image)
- Kubernetes via kind
- Helm for deployment templating
- Trivy for vulnerability scanning
- Makefile for automation

## Quick Start
\```bash
make setup
make all
make port-forward
\```

## Full documentation
See [ARCHITECTURE.md](./ARCHITECTURE.md)