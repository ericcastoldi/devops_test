FROM golang:1.19-alpine

WORKDIR /app

COPY main.go ./

RUN go mod init get-ninjas-api && go mod tidy
RUN go build -o /get-ninjas-api

EXPOSE 8000

CMD [ "/get-ninjas-api" ]
