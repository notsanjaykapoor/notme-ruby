FROM ruby:3.1.0

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/app/src

ENV RACK_ENV production

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

COPY Gemfile /usr/app/src/
COPY Gemfile.lock /usr/app/src/

RUN bundle install

# Add app

COPY . /usr/app/src
COPY .irbrc /usr/app/src/.irbrc

CMD bash

#
# example command to run image/container with entrypoint:
#   - docker run --rm -it --entrypoint bash <image or container name>
#
