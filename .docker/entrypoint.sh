#!/bin/bash

set -e

# When starting the application, cached versions of the datasets must first be built. This can be
# skipped when the PREBUILT_DATASETS environment variable is set. In that case, it is expected that
# you have already built the datasets and mounted them into tmp/atlas via Docker.

if [[ -z "${PREBUILT_DATASETS}" && ( "${RAILS_ENV}" == "production" || "${RAILS_ENV}" == "staging" )]]; then
  echo "Building datasets..."
  bundle exec rake deploy:load_etsource deploy:calculate_datasets --trace

  echo "Starting server..."
fi

bundle exec rails db:migrate
bundle exec --keep-file-descriptors puma -C config/puma.rb
