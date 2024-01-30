FROM ruby:3.3.0

ARG APP_VERSION=version

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /app

ENV RACK_ENV prd
ENV APP_VERSION=$APP_VERSION

RUN apt-get update && apt-get install -qq -yq --no-install-recommends \
  busybox \
  curl \
  file \
  gnupg \
  libgs-dev \
  nginx \
  nodejs \
  supervisor \
  tmux \
  && mkdir -p /var/log/supervisor \
  && mkdir -p /usr/app/src/log \
  && mkdir -p /usr/app/src/tmp \
  && apt-get autoremove -y \
  && apt-get clean all \
  && rm -rf /var/cache/apt /var/lib/apt/lists/*

# Add Gemfile and install gems using bundler

COPY Gemfile /app
COPY Gemfile.lock /app

RUN bundle install

# Add app

COPY . /app
COPY .irbrc /app/.irbrc

CMD bash

#
# example command to run image/container with entrypoint:
#   - docker run --rm -it --entrypoint bash <image or container name>
#
