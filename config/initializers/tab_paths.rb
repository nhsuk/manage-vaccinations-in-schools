#!/usr/bin/env ruby

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
  }
}.with_indifferent_access
