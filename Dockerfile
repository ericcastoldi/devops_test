# Build
FROM golang:1.19-alpine AS build

RUN apk add build-base

WORKDIR /app

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./

RUN go test --cover -v
RUN go build -v -o get-ninjas-api

# Run
FROM alpine:3.16.2

WORKDIR /

COPY --from=build /app/get-ninjas-api /get-ninjas-api

ENTRYPOINT ["/get-ninjas-api"]
