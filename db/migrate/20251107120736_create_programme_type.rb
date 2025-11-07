# frozen_string_literal: true

class CreateProgrammeType < ActiveRecord::Migration[8.1]
  def change
    create_enum :programme_type, %w[flu hpv menacwy mmr td_ipv]
  end
end
