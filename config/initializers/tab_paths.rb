#!/usr/bin/env ruby
# frozen_string_literal: true

TAB_PATHS = {
  consents: {
    "no-consent" => :no_consent,
    "given" => :consent_given,
    "refused" => :consent_refused,
    "conflicts" => :conflicting_consent
  },
  triage: {
    "needed" => :needs_triage,
    "completed" => :triage_complete,
    "not-needed" => :no_triage_needed
  },
  vaccinations: {
    "vaccinate" => :vaccinate,
    "vaccinated" => :vaccinated,
    "could-not" => :could_not_vaccinate
  }
}.with_indifferent_access
