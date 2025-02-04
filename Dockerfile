# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t zdrofit_booker .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name zdrofit_booker zdrofit_booker

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.1
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update -qq && \
    apt-get install -y ca-certificates && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libjemalloc-dev \
    libgmp-dev \
    libvips \
    sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Build stage
FROM base AS build

# Install build dependencies
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update -qq && \
    apt-get install -y ca-certificates && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    pkg-config \
    ruby-dev \
    make \
    gcc \
    nodejs \
    libssl-dev \
    zlib1g-dev \
    clang \
    llvm \
    npm

# Install tailwindcss
# Set safe compiler flags
ENV CFLAGS="-O2 -march=x86-64-v2"
ENV CXXFLAGS="-O2 -march=x86-64-v2"
ENV LDFLAGS="-Wl,--no-as-needed" \
    CC="clang" \
    CXX="clang++"

# Configure bundler
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_BUILD__BCRYPT_PBKDF="--with-cflags='${CFLAGS}'" \
    BUNDLE_BUILD__ED25519="--with-cflags='${CFLAGS}'" \
    BUNDLE_WITHOUT="development test" \
    PORT=80

# Install gems
COPY Gemfile Gemfile.lock ./
COPY lib/zdrofit_client lib/zdrofit_client
RUN --mount=type=cache,target=/usr/local/bundle/cache \
    bundle config build.nokogiri --use-system-libraries && \
    bundle config set --local path '/usr/local/bundle' && \
    bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle config jobs 1 && \
    bundle config retry 3 && \
    bundle install && \
    rm -rf ~/.bundle/ /usr/local/bundle/ruby/*/cache /usr/local/bundle/ruby/*/bundler/gems/*/.git

# Copy application code
COPY --chown=1000:1000 . .
RUN rm -rf tmp

# Install tailwindcss
RUN npm install tailwindcss @tailwindcss/cli

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile 

# Copy built artifacts: gems, application
# COPY --from=build --chown=1000:1000 /usr/local/bundle /usr/local/bundle
# COPY --from=build --chown=1000:1000 /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p tmp db log storage && \
    chown -R rails:rails /usr/local/bundle tmp db log storage

USER 1000:1000

# Keep container running (testing)
# CMD ["tail", "-f", "/dev/null"]

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]


