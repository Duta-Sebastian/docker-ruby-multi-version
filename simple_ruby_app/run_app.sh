#!/bin/bash
source /usr/share/rvm/scripts/rvm

versions=("2.3.8" "2.4.10" "2.5.9" "2.6.10" "2.7.8" "3.0.7" "3.1.6" "3.2.6" "3.3.6")

expected_output=$'Entry added: foo -> bar
Entry added: baz -> qux
Listing all entries:
foo: bar
baz: qux
Found entry: foo -> bar'

success=true

for version in "${versions[@]}"; do
  echo "Using /usr/share/rvm/gems/ruby-$version"
  if rvm use "$version" > /dev/null 2>&1; then
    bundle install
    ruby_output=$(bundle exec ruby simple_app.rb)
    echo -e "$ruby_output"

    if [ "$ruby_output" == "$expected_output" ]; then
      echo "Output matches expected values for Ruby $version"
    else
      echo "Error: Output does not match expected values for Ruby $version"
      echo -e "Expected:\n$expected_output"
      echo -e "Got:\n$ruby_output"
      success=false
      break
    fi
  else
    echo "Failed to switch to Ruby version $version."
    success=false
    break
  fi
  echo
done

if [ "$success" == true ]; then
    exit 0
else
    exit 1
fi