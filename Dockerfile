FROM ubuntu:24.04 AS ruby-builder

RUN apt-get update && apt-get remove -y --purge openssl libssl-dev

RUN apt-get update && apt-get install -y wget gcc perl make && \
    wget https://www.openssl.org/source/openssl-1.0.2.tar.gz && \
    wget https://www.openssl.org/source/openssl-1.1.1.tar.gz && \
    wget https://www.openssl.org/source/openssl-3.0.0.tar.gz && \
    tar -xvzf openssl-1.0.2.tar.gz && \
    tar -xvzf openssl-1.1.1.tar.gz && \
    tar -xvzf openssl-3.0.0.tar.gz && \
    cd openssl-1.0.2 && \
    ./config --prefix=/usr/local/ssl1.0 --openssldir=/usr/local/ssl1.0 no-tests -shared && \
    make && \
    make install && \
    cd ../openssl-1.1.1 && \
    ./config --prefix=/usr/local/ssl1.1 --openssldir=/usr/local/ssl1.1 no-tests && \
    make && \
    make install && \
    cd ../openssl-3.0.0 && \
    ./config --prefix=/usr/local/ssl3.0 --openssldir=/usr/local/ssl3.0 no-tests && \
    make && \
    make install

RUN rm openssl-1.0.2.tar.gz openssl-1.1.1.tar.gz openssl-3.0.0.tar.gz && \
    rm -rf openssl-1.0.2 openssl-1.1.1 openssl-3.0.0 && \
    apt-get remove -y wget gcc perl make

ENV PATH=/usr/local/ssl1.0/bin:$PATH

RUN apt-get update && apt-get install -y software-properties-common && \
    apt-add-repository -y ppa:rael-gc/rvm && \
    apt-get update && \
    apt-get install -y rvm && \
    echo 'source /usr/share/rvm/scripts/rvm' >> /etc/bash.bashrc && \
    echo 'source /usr/share/rvm/scripts/rvm' >> /etc/profile.d/rvm.sh && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get remove -y software-properties-common

ENV PATH=/usr/share/rvm/bin:$PATH

SHELL ["/bin/bash", "--login", "-c"]

RUN PATH=/usr/local/ssl1.0/bin:$PATH && \
    rvm install 2.3.8 --with-openssl-dir=/usr/local/ssl1.0 --without-libssl1.0-dev && \
    rvm use 2.3.8 && \
    gem install bundler -v 2.3.27 && \
    gem update --system 3.2.3

ENV PATH=/usr/local/ssl1.1/bin:$PATH

RUN for version in 2.4.10 2.5.9 2.6.10 2.7.8 3.0.7; do \
      rvm autolibs disable && \
      rvm install $version --with-openssl-dir=/usr/local/ssl1.1 && \
      rvm use $version && \
      if [[ "${version}" == "3.0.7" ]]; then \
        gem install bundler; \
      elif [[ "${version}" == "2.6.10" || "${version}" = "2.7.8" ]]; then \
        gem install bundler -v "2.4.22" && gem update --system 3.2.3; \
      else \
        gem install bundler -v "2.3.27" && gem update --system 3.2.3; \
      fi \
    done

ENV PATH=/usr/local/ssl3.0/bin:$PATH

RUN for version in 3.1.6 3.2.6 3.3.6; do \
      rvm install $version && \
      rvm use $version && \
      gem install bundler; \
    done

RUN mkdir -p ruby_tests && cd ruby_tests

COPY ./verify_ruby_builder.sh ./ruby_tests

COPY ./print_ruby_version.rb ./ruby_tests

RUN cd ./ruby_tests && ls -al && chmod +x ./verify_ruby_builder.sh && ./verify_ruby_builder.sh

COPY ./simple_ruby_app/ ./ruby_tests/

RUN ls -al && cd ./ruby_tests/simple_ruby_app && ls -al && chmod +x ./run_app.sh && ./run_app.sh

ENTRYPOINT ["/bin/bash"]