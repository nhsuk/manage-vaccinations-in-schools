# frozen_string_literal: true

class MakeConsentColumnsNotNull < ActiveRecord::Migration[7.2]
  def change
    change_table :consents, bulk: true do |t|
      t.change_null :health_answers, false, []
      t.change_null :response, false, 2 # not_provided
      t.change_null :route, false, 0 # website
    end
  end
end
