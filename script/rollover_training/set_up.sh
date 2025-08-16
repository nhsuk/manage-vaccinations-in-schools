set -eu

bin/rails vaccines:seed
bin/mavis gias import
bin/mavis gp-practices import
bin/mavis teams onboard config/onboarding/rollover-training.yaml

bin/mavis local-authorities download
bin/mavis local-authorities import
bin/mavis local-authorities download_gias_codes
bin/mavis local-authorities import_gias_codes
