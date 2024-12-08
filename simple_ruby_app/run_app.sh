#!/bin/bash
source /usr/share/rvm/scripts/rvm

for version in 2.3.8 2.4.10 2.5.9 2.6.10 2.7.8 3.0.7 3.1.6 3.2.6 3.3.6; do
  rvm use $version && echo "${version}" && bundle install && bundle exec ruby simple_app.rb;
done
