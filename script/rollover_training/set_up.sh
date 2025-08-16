set -eu

bin/rails vaccines:seed
bin/mavis gias import
bin/mavis gp-practices import
bin/mavis teams onboard config/onboarding/rollover-training.yaml
