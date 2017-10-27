FROM ruby:2.1.9
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs mysql-client
RUN mkdir /etengine
WORKDIR /etengine
ADD Gemfile /etengine/Gemfile
ADD Gemfile.lock /etengine/Gemfile.lock
RUN bundle install
ADD . /etengine
ADD ../etsource /etsource
WORKDIR /etengine
ENV RAILS_ENV production
RUN bundle exec rake assets:precompile
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
