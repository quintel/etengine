FROM ruby:2.7.4-slim-buster

LABEL maintainer="dev@quintel.com"

RUN apt-get update -yqq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yqq --no-install-recommends \
    automake \
    autoconf \
    build-essential \
    default-libmysqlclient-dev \
    git \
    gnupg \
    less \
    libreadline-dev \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    nodejs \
    vim \
    zlib1g \
    zlib1g-dev

RUN gem install bundler:1.17.3

COPY Gemfile* /app/
WORKDIR /app
RUN bundle install --jobs=4 --retry=3

COPY . /app/

CMD [".docker/entrypoint.sh"]
