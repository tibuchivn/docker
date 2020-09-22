FROM circleci/ruby:2.6.6-stretch-browsers

RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - &&\
  sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'

RUN sudo apt-get update && sudo apt-get install -yq build-essential openssl libreadline7 libreadline6-dev curl git-core \
  zlib1g zlib1g-dev libssl-dev libssl1.1 libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev \
  autoconf libc6-dev ncurses-dev automake libtool bison subversion default-libmysqlclient-dev \
  git libpq-dev apt-transport-https\
  libmagickcore-6.q16-3 imagemagick libmagickcore-dev libmagickwand-dev \
  libjemalloc-dev cmake\
  google-chrome-stable=85.\* --no-install-recommends

RUN cd /tmp && wget https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.6.tar.gz && tar -xvzf ruby-2.6.6.tar.gz && cd ruby-2.6.6 && ./configure --with-jemalloc && make && sudo make install
RUN cd /tmp && wget https://nodejs.org/dist/v6.11.5/node-v6.11.5-linux-x64.tar.gz && sudo tar -xf node-v6.11.5-linux-x64.tar.gz --directory /usr/local --strip-components 1

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
RUN sudo apt-get update && sudo apt-get install yarn --no-install-recommends

# Install code climate test report
RUN cd /tmp &&\
  curl -L https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 > cc-test-reporter &&\
  sudo mv cc-test-reporter /usr/local/bin/ &&\
  sudo chmod +x /usr/local/bin/cc-test-reporter

# Set env variables
ENV BUNDLER_VERSION=2.1.4 \
    RAILS_VERSION=5.1.7

# Install pronto gems
RUN sudo rm -rf /usr/local/bin/bundle \
    && sudo gem install bundler:${BUNDLER_VERSION} activesupport:${RAILS_VERSION} \
    && sudo gem install --conservative --minimal-deps \
       rubocop:0.81.0 rubocop-performance rubocop-rails rubocop-rspec \
       pronto pronto-rubocop pronto-rails_best_practices pronto-haml pronto-fasterer pronto-brakeman \
    && cd /tmp \
      && git clone https://github.com/anvox/pronto-reek \
      && cd pronto-reek \
      && git checkout v0.10.1-reek6 \
      && bundle && rake build \
      && gem install pkg/pronto-reek-0.10.1.pre.reek6.gem

# workaround for node-gyp https://github.com/yarnpkg/yarn/issues/2828
# RUN sudo yarn global add node-gyp
RUN sudo npm install -g node-gyp
RUN sudo npm install -g gulp

RUN cd /tmp && wget https://chromedriver.storage.googleapis.com/85.0.4183.38/chromedriver_linux64.zip && unzip chromedriver_linux64.zip && sudo mv chromedriver /usr/local/bin/
#
# Cleanup
RUN sudo rm -rf /usr/local/lib/ruby/gems/${RUBY_MAJOR}.0/cache/* \
    && sudo apt-get clean \
    && sudo apt-get autoremove
