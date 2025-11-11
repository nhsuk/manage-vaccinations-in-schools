ARG IMAGE_TAG=latest
ARG REPOSITORY=mavis-webapp

FROM ${REPOSITORY}:${IMAGE_TAG}

USER root
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      postgresql postgresql-contrib postgresql-client \
      redis-server supervisor sudo build-essential && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN gem install foreman

ENV RAILS_ENV="development" \
    NODE_ENV="development" \
    BUNDLE_WITHOUT="test" \
    RAILS_MASTER_KEY="intentionally-insecure-dev-key00" \
    SKIP_TEST_DATABASE="true"

RUN bundle install


RUN service postgresql start && \
    sudo -u postgres psql --command "CREATE USER $(whoami); ALTER USER $(whoami) WITH SUPERUSER;" && \
    bin/rails db:reset && \
    service postgresql stop

ENTRYPOINT ["/rails/bin/docker-entrypoint-regression.sh"]
