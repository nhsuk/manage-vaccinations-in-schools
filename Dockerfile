# syntax = docker/dockerfile:1.4
# check=error=true

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.3
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips libicu-dev postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    NODE_ENV="production" \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems and node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev \
      libyaml-dev node-gyp pkg-config python-is-python3 zlib1g-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install JavaScript dependencies
ARG NODE_VERSION=22.15.0
ARG YARN_VERSION=1.22.19
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL --ssl https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install --ignore-scripts -g yarn@"$YARN_VERSION" && \
    rm -rf /tmp/node-build-master

# Install application gems
COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install node modules
COPY package.json yarn.lock ./
RUN yarn install --ignore-scripts --frozen-lockfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
# CIS2 and Splunk need to be disabled because RAILS_ENV=production is used
RUN SECRET_KEY_BASE_DUMMY=1 \
    MAVIS__CIS2__ENABLED=false \
    MAVIS__SPLUNK__ENABLED=false \
    ./bin/rails assets:precompile

# Remove node modules to reduce image size
RUN rm -rf node_modules

# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start web server by default, this can be overwritten by environment variable
EXPOSE 4000
ENV HTTP_PORT=4000
ENV GOOD_JOB_PROBE_PORT=4000
ENV SERVER_TYPE=web
CMD ["./bin/docker-start"]
