ARG IMAGE_TAG=latest
ARG REPOSITORY=mavis-webapp

FROM ${REPOSITORY}:${IMAGE_TAG}

USER root
RUN mkdir /var/lib/apt/lists && apt-get update && \
    apt-get install -y --no-install-recommends zip unzip vim emacs screen tmux awscli && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

USER 1000:1000

ENV SERVER_TYPE=none
CMD ["./bin/docker-start"]
