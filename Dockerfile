FROM ubuntu:24.04 AS ruby-builder

RUN apt-get update && apt-get remove -y --purge openssl libssl-dev

RUN apt-get update && apt-get install -y wget gcc perl make

RUN wget https://www.openssl.org/source/openssl-1.0.2.tar.gz && \
    tar -xvzf openssl-1.0.2.tar.gz && \
    cd openssl-1.0.2 && \
    ./config --prefix=/usr/local/ssl1.0 --openssldir=/usr/local/ssl1.0 no-tests -shared && \
    make && \
    make install & \
    wget https://www.openssl.org/source/openssl-1.1.1.tar.gz && \
    tar -xvzf openssl-1.1.1.tar.gz && \
    cd openssl-1.1.1 && \
    ./config --prefix=/usr/local/ssl1.1 --openssldir=/usr/local/ssl1.1 no-tests && \
    make && \
    make install & \
    wget https://www.openssl.org/source/openssl-3.0.0.tar.gz && \
    tar -xvzf openssl-3.0.0.tar.gz && \
    cd openssl-3.0.0 && \
    ./config --prefix=/usr/local/ssl3.0 --openssldir=/usr/local/ssl3.0 no-tests && \
    make && \
    make install & \
    wait

RUN apt-get remove -y wget gcc perl make && \
    rm openssl-1.0.2.tar.gz openssl-1.1.1.tar.gz openssl-3.0.0.tar.gz && \
    rm -rf openssl-1.0.2 openssl-1.1.1 openssl-3.0.0

RUN apt-get update && apt-get install -y software-properties-common && \
    apt-add-repository -y ppa:rael-gc/rvm && \
    apt-get update && \
    apt-get install -y rvm && \
    echo 'source /usr/share/rvm/scripts/rvm' >> /etc/bash.bashrc && \
    echo 'source /usr/share/rvm/scripts/rvm' >> /etc/profile.d/rvm.sh

SHELL ["/bin/bash", "--login", "-c"]

RUN apt-get update && \
    apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev \
                             libyaml-dev libffi-dev libgdbm-dev libxslt-dev \
                             libjemalloc-dev libncurses-dev libncurses5-dev libgmp-dev

RUN source /usr/share/rvm/scripts/rvm && \
    for version in 2.3.8 2.4.10 2.5.9 2.6.10 2.7.8 3.0.7 3.1.6 3.2.6 3.3.6; do \
        sleep 3 && \
        if [[ "${version}" == "2.3.8" ]]; then \
            ( \
            export PATH=/usr/local/ssl1.0/bin:$PATH && \
            rvm autolibs disable && \
            rvm install $version --with-openssl-dir=/usr/local/ssl1.0 --without-libssl1.0-dev; \
            ) & \
        elif [[ "${version}" == "2.4.10" || "${version}" == "2.5.9" || "${version}" == "2.6.10" || "${version}" == "2.7.8" || "${version}" == "3.0.7" ]]; then \
            ( \
            export PATH=/usr/local/ssl1.1/bin:$PATH && \
            rvm autolibs disable && \
            rvm install $version --with-openssl-dir=/usr/local/ssl1.1; \
            ) & \
        else \
            ( \
            export PATH=/usr/local/ssl3.0/bin:$PATH && \
            rvm autolibs disable && \
            rvm install $version; \
            ) & \
        fi \
    done && wait

RUN source /usr/share/rvm/scripts/rvm && \
    for version in 2.3.8 2.4.10 2.5.9 2.6.10 2.7.8 3.0.7 3.1.6 3.2.6 3.3.6; do \
        sleep 3 && \
        if [[ "${version}" == "2.3.8" ]]; then \
            ( \
            export PATH=/usr/local/ssl1.0/bin:$PATH && \
            rvm use $version && \
            gem install bundler -v 2.3.27 && \
            gem update --system 3.2.3; \
            ) & \
        elif [[ "${version}" == "2.4.10" || "${version}" == "2.5.9" || "${version}" == "2.6.10" || "${version}" == "2.7.8" || "${version}" == "3.0.7" ]]; then \
            ( \
            export PATH=/usr/local/ssl1.1/bin:$PATH && \
            rvm use $version && \
            if [[ "${version}" == "3.0.7" ]]; then \
                gem install bundler; \
            elif [[ "${version}" == "2.6.10" || "${version}" == "2.7.8" ]]; then\
                gem install bundler -v "2.4.22" && \
                gem update --system 3.2.3; \
            else \
                gem install bundler -v "2.3.27" && \
                gem update --system 3.2.3; \
            fi \
            ) & \
        else \
            ( \
            rvm use $version && \
            gem install bundler; \
            ) & \
        fi \
    done && wait

RUN mkdir -p ruby_tests && cd ruby_tests

COPY ./verify_ruby_builder.sh ./ruby_tests

COPY ./print_ruby_version.rb ./ruby_tests

RUN cd ./ruby_tests && chmod +x ./verify_ruby_builder.sh && ./verify_ruby_builder.sh

RUN cd ./ruby_tests && mkdir simple_ruby_app

COPY ./simple_ruby_app/ ./ruby_tests/simple_ruby_app

RUN cd ./ruby_tests/simple_ruby_app && chmod +x ./run_app.sh && ./run_app.sh

ENTRYPOINT ["/bin/bash"]