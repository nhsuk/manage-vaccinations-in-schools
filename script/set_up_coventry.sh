set -eux

bin/rails db:schema:load

bin/rails vaccines:seed[hpv]
bin/rails gp_practices:import
bin/rails schools:import
bin/rails onboard[config/onboarding/coventry-model-office.yaml]
