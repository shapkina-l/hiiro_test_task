FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY app/ .

RUN make build


FROM gcr.io/distroless/static:nonroot

COPY --from=builder /app/server /server

EXPOSE 8080
USER nonroot:nonroot

ENTRYPOINT ["/server"]