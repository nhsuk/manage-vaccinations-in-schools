# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += %i[
  passw
  secret
  token
  _key
  crypt
  salt
  certificate
  otp
  ssn
]

# Encrypted attributes on our models are automatically added to the filter parameters:
#  https://guides.rubyonrails.org/active_record_encryption.html#filtering-params-named-as-encrypted-columns
# Some of the attributes contain PII but are not encrypted and therefore need to be added to this list
# explicitly.

FILTER_STARTING_WITH = %w[
  address
  date_of_birth
  identity_check_confirmed_by
  parent
].freeze

Rails.application.config.filter_parameters +=
  FILTER_STARTING_WITH.map { /\A#{it}/ }

FILTER_ENDING_WITH = %w[delay_vaccination_until notes].freeze

Rails.application.config.filter_parameters +=
  FILTER_ENDING_WITH.map { /#{it}\z/ }

FILTER_EXACTLY_MATCHING = %w[
  address-postalcode
  birthdate
  body
  diagnostics
  family
  given
  health_answers
  location_name
  other_details
  q
  to
].freeze

Rails.application.config.filter_parameters += FILTER_EXACTLY_MATCHING
