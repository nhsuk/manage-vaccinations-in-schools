# frozen_string_literal: true

module HasDiseaseTypes
  extend ActiveSupport::Concern

  included do
    extend ArrayEnum

    array_enum disease_types: {
                 influenza: 0,
                 human_papillomavirus: 1,
                 meningitis_a: 2,
                 meningitis_c: 3,
                 meningitis_w: 4,
                 meningitis_y: 5,
                 polio: 6,
                 tetanus: 7,
                 diphtheria: 8,
                 measles: 9,
                 mumps: 10,
                 rubella: 11,
                 varicella: 12
               }

    validates :disease_types, subset: disease_types.keys
  end
end
