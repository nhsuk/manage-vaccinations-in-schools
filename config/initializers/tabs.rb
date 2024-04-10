#!/usr/bin/env ruby

TAB_PATHS = {
  triage: {
    "needed" => :needs_triage,
    "completed" => :triage_complete,
    "not-needed" => :no_triage_needed
  }
}.with_indifferent_access
