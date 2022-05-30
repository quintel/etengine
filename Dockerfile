FROM ruby:3.1-slim

LABEL maintainer="dev@quintel.com"

RUN apt-get update -yqq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yqq --no-install-recommends \
    automake \
    autoconf \
    build-essential \
    default-libmysqlclient-dev \
    default-mysql-client \
    git \
    gnupg \
    graphviz \
    less \
    libreadline-dev \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    nodejs \
    vim \
    zlib1g \
    zlib1g-dev

COPY Gemfile* /app/
WORKDIR /app
RUN bundle install --jobs=4 --retry=3

COPY . /app/

CMD [".docker/entrypoint.sh"]
