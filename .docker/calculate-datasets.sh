#!/bin/bash

# This script allows us to calculate the datasets for a deployment, saving the cache files into a
# temporary directory (so as not to interrupt existing containers from reading the existing files).
# When it completes, the new cache files are written into the shared volume mounted at
# /app/tmp/atlas.
#
# This should be used as part of a deploy process. For example:
#
#     docker-compose pull
#
#     docker-compose run --rm web .docker/calculate-datasets.sh &&
#       docker-compose down &&
#       docker-compose up -d
#
# Optionally provide the ETSource revision:
#
#     docker-compose run -e 'ETSOURCE_REF=abcdef01' --rm web .docker/calculate-datasets.sh
#
# If no ETSOURCE_REF is provided, the RAILS_ENV will be used to determine which branch to import:
#
#  * RAILS_ENV=production: production ETSource branch
#  * Anything else: master ETSource branch

set -e

mkdir -p /tmp/atlas

CACHED_DATASETS_PATH=/tmp/atlas bundle exec rake deploy:load_etsource deploy:calculate_datasets

rm -rf /app/tmp/atlas/*.pack
cp -R /tmp/atlas/*.pack /app/tmp/atlas

rm -rf /tmp/atlas
