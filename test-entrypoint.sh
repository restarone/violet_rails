#!/bin/sh

set -e

echo "Environment: $RAILS_ENV"

# Check if we need to install new gems
bundle check || bundle install --jobs 20 --retry 5

# Unset empty ENV vars
if [ ! -n "$TEST" ]; then
  unset TEST
fi
if [ ! -n "$TESTOPTS" ]; then
  unset TESTOPTS
fi
if [ ! -n "$SEED" ]; then
  unset SEED
fi
if [ ! -n "$COVERAGE" ]; then
  unset COVERAGE
fi
if [ ! -n "$RUBYOPT" ]; then
  unset RUBYOPT
fi

echo "ENV VARS:"
echo "- TEST: $TEST"
echo "- TESTOPTS: $TESTOPTS"
echo "- SEED: $SEED"
echo "- COVERAGE: $COVERAGE"
echo "- RUBYOPT: $RUBYOPT"

# Then run any passed command
bundle exec ${@}
