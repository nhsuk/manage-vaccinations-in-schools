# frozen_string_literal: true

require "pagy/extras/array"
require "pagy/extras/jsonapi"
require "pagy/extras/overflow"

Pagy::DEFAULT[:jsonapi] = false
Pagy::DEFAULT[:limit] = 50
Pagy::DEFAULT[:overflow] = :last_page
