#!/bin/sh

set -e

echo "Environment: $RAILS_ENV"

# Then run any passed command
${@}
