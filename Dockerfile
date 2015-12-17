FROM ruby:2.1

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY . /usr/src/app
RUN bundle install

CMD ["/usr/local/bundle/bin/bundle", "exec", "bin/synapse", "-c/usr/src/app/config/synapse.conf.apollo.json"]

