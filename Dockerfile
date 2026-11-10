FROM ubuntu:latest
LABEL authors="nshut"

ENTRYPOINT ["top", "-b"]