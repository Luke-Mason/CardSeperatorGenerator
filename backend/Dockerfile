FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum* ./
RUN go mod download

# Copy source code
COPY src/ ./src/

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./src/main.go

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/server .

# Create cache directory
RUN mkdir -p /root/cache

EXPOSE 8080

CMD ["./server"]