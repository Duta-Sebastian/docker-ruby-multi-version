source /usr/share/rvm/scripts/rvm

for version in 2.3.8 2.4.10 2.5.9 2.6.10 2.7.8 3.0.7 3.1.6 3.2.6 3.3.6; do
    rvm use $version && bundler -v && ruby print_ruby_version.rb
    ruby -ropenssl -e "puts OpenSSL::OPENSSL_VERSION"
done

