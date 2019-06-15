FROM rhuan/ruby-freetds:2.5

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 14586
CMD [ "bundle", "exec", "ruby", "servercontract.rb" ]
