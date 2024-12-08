#!/bin/bash

source /usr/share/rvm/scripts/rvm

versions=("2.3.8" "2.4.10" "2.5.9" "2.6.10" "2.7.8" "3.0.7" "3.1.6" "3.2.6" "3.3.6")

declare -A expected_outputs
expected_outputs["2.3.8"]=$'Ruby version: 2.3.8\nBundler version: 2.3.27'
expected_outputs["2.4.10"]=$'Ruby version: 2.4.10\nBundler version: 2.3.27'
expected_outputs["2.5.9"]=$'Ruby version: 2.5.9\nBundler version: 2.3.27'
expected_outputs["2.6.10"]=$'Ruby version: 2.6.10\nBundler version: 2.4.22'
expected_outputs["2.7.8"]=$'Ruby version: 2.7.8\nBundler version: 2.4.22'
expected_outputs["3.0.7"]=$'Ruby version: 3.0.7\nBundler version: 2.5.23'
expected_outputs["3.1.6"]=$'Ruby version: 3.1.6\nBundler version: 2.3.27'
expected_outputs["3.2.6"]=$'Ruby version: 3.2.6\nBundler version: 2.5.23'
expected_outputs["3.3.6"]=$'Ruby version: 3.3.6\nBundler version: 2.5.23'

# Success flag
success=true

for version in "${versions[@]}"; do
    echo "Using /usr/share/rvm/gems/ruby-$version"

    if rvm use "$version" > /dev/null 2>&1; then
        ruby_output=$(ruby print_ruby_version.rb)
        echo -e "$ruby_output"

        expected_output=${expected_outputs[$version]}

        if [ "$ruby_output" == "$expected_output" ]; then
            echo "Output matches expected values for Ruby $version."
        else
            echo "Error: Output does not match expected values for Ruby $version."
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
