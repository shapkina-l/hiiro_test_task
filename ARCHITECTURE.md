# Architecture

## Solution Overview

A minimal HTTP service written in C++, containerized with a multi-stage
Dockerfile, and deployed locally in Kubernetes using kind.

**Key choices:**

| Decision | Choice | Reason |
|---|---|---|
| Language | C++ | Familiar language; static binary fits perfectly into distroless image |
| HTTP library | cpp-httplib | Header-only, no runtime dependencies, vendored into repo |
| Base image | distroless/static:nonroot | No shell or package manager, minimal attack surface, 0 CVEs |
| Build system | Makefile | Simple, sufficient for a single-file project, no extra tooling needed |
| Local k8s | kind | Lightweight, no VM required, scriptable |
| Image delivery | kind load | Reliable for local dev, no registry infrastructure needed |
| Vulnerability scanner | Trivy | Industry standard, open-source, easy CLI integration |

## What to Change for Production

- Replace `kind load` with a proper private registry (ECR, GCR, or Harbor)
- Add HorizontalPodAutoscaler to handle traffic spikes
- Add PodDisruptionBudget to ensure availability during node maintenance
- Use Ingress with TLS termination instead of port-forwarding
- Implement proper secrets management (HashiCorp Vault or Sealed Secrets)
- Set Trivy `--exit-code 1` to block builds on CRITICAL CVEs
- Cache Docker build layers in CI to speed up C++ compilation
- Add `/metrics` endpoint and instrument with Prometheus client

## Potential Risks

| Risk | Impact | Mitigation |
|---|---|---|
| `latest` tag | Image drift between environments | Pin to immutable digest or git SHA tag |
| No HPA | Downtime under load spikes | Add HPA with CPU-based scaling |
| Static binary | Security patches in libc require full rebuild | Automate nightly rebuilds |
| Single replica during rollout | Brief unavailability | Add PodDisruptionBudget |
| No resource quotas on namespace | One app can starve others | Add LimitRange and ResourceQuota |

## Metrics for Monitoring

| Metric | Why |
|---|---|
| HTTP request rate | Core traffic signal |
| HTTP latency p50/p99 | SLA and user experience |
| HTTP 5xx error rate | Detects failures and regressions |
| Pod restart count | Detects crashlooping |
| CPU/memory usage vs limits | Capacity planning, detects OOMKill risk |
| Readiness probe failure rate | Detects dependency or startup issues |

Recommended stack: Prometheus + Grafana + Alertmanager.

## GitOps Approach

1. **Two repositories**: `app-code` (source) and `infra-config` (manifests/Helm values)
2. **CI pipeline** on `app-code`: test → build → Trivy scan → push → update image tag in `infra-config`
3. **ArgoCD or Flux** watches `infra-config` and syncs desired state to the cluster
4. **Pull-based model**: cluster pulls state from Git — no push credentials needed in CI
5. **PR-based promotion**: staging → production via merged PRs with image tag bumps
6. **Audit trail**: every change to the cluster is a Git commit with author and timestamp