# frozen_string_literal: true

class CreateDiseaseType < ActiveRecord::Migration[8.1]
  def change
    create_enum :disease_type,
                %w[
                  diphtheria
                  human_papillomavirus
                  influenza
                  measles
                  meningitis_a
                  meningitis_c
                  meningitis_w
                  meningitis_y
                  mumps
                  polio
                  rubella
                  tetanus
                  varicella
                ]
  end
end
