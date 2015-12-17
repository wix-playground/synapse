FROM ruby:2.1

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY . /usr/src/app
RUN bundle install

CMD ["bundle exec bin/synapse -c config/synapse.conf.apollo.json"]

