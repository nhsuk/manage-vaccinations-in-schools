ARG BASE_IMAGE_TAG=latest

FROM 393416225559.dkr.ecr.eu-west-2.amazonaws.com/mavis/webapp:${BASE_IMAGE_TAG}

USER root
RUN mkdir /var/lib/apt/lists && apt-get update && \
    apt-get install -y --no-install-recommends zip unzip vim emacs screen tmux && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

USER 1000:1000

ENV SERVER_TYPE=none
CMD ["./bin/docker-start"]
