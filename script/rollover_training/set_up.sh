set -eu

bin/rails vaccines:seed
bin/mavis gias import
bin/rails gp_practices:import
bin/mavis teams onboard config/onboarding/rollover-training.yaml

bin/mavis local_authorities download
bin/mavis local_authorities import
bin/mavis local_authorities download_gias_codes
bin/mavis local_authorities import_gias_codes
