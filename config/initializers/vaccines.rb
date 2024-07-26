# frozen_string_literal: true

VACCINES = YAML.load_file(Rails.root.join("config/vaccines.yml"))
