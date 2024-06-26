# frozen_string_literal: true

class MakeConsentRouteOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :consents, :route, true
  end
end
