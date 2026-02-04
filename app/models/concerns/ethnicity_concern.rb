# frozen_string_literal: true

module EthnicityConcern
  extend ActiveSupport::Concern

  ETHNIC_GROUPS = {
    white: 0,
    mixed_or_multiple_ethnic_groups: 1,
    asian_or_asian_british: 2,
    black_african_caribbean_or_black_british: 3,
    other_ethnic_group: 4,
    prefer_not_to_say: 5
  }.freeze

  ETHNIC_BACKGROUNDS = {
    # White
    white_english_welsh_scottish_northern_irish_or_british: 0,
    white_irish: 1,
    white_gypsy_or_irish_traveller: 2,
    white_any_other_white_background: 3,
    # Mixed or multiple ethnic groups
    mixed_white_and_black_caribbean: 10,
    mixed_white_and_black_african: 11,
    mixed_white_and_asian: 12,
    mixed_any_other_mixed_or_multiple_ethnic_background: 13,
    # Asian or Asian British
    asian_indian: 20,
    asian_pakistani: 21,
    asian_bangladeshi: 22,
    asian_chinese: 23,
    asian_any_other_asian_background: 24,
    # Black, African, Caribbean or Black British
    black_african: 30,
    black_caribbean: 31,
    black_any_other_black_african_or_caribbean_background: 32,
    # Other ethnic group
    other_arab: 40,
    other_any_other_ethnic_group: 41,
    # Leaf option on background pages
    prefer_not_to_say: 99
  }.freeze

  ETHNIC_BACKGROUNDS_BY_GROUP = {
    white: %i[
      white_english_welsh_scottish_northern_irish_or_british
      white_irish
      white_gypsy_or_irish_traveller
      white_any_other_white_background
    ],
    mixed_or_multiple_ethnic_groups: %i[
      mixed_white_and_black_caribbean
      mixed_white_and_black_african
      mixed_white_and_asian
      mixed_any_other_mixed_or_multiple_ethnic_background
    ],
    asian_or_asian_british: %i[
      asian_indian
      asian_pakistani
      asian_bangladeshi
      asian_chinese
      asian_any_other_asian_background
    ],
    black_african_caribbean_or_black_british: %i[
      black_african
      black_caribbean
      black_any_other_black_african_or_caribbean_background
    ],
    other_ethnic_group: %i[other_arab other_any_other_ethnic_group]
  }.freeze

  ANY_OTHER_ETHNIC_BACKGROUNDS = %i[
    white_any_other_white_background
    mixed_any_other_mixed_or_multiple_ethnic_background
    asian_any_other_asian_background
    black_any_other_black_african_or_caribbean_background
    other_any_other_ethnic_group
  ].freeze

  included do
    enum :ethnic_group,
         ETHNIC_GROUPS,
         prefix: true,
         validate: {
           allow_nil: true
         }

    enum :ethnic_background,
         ETHNIC_BACKGROUNDS,
         prefix: true,
         validate: {
           allow_nil: true
         }

    validates :additional_ethnic_background,
              presence: true,
              if: :ethnic_background_requires_additional_details?

    validates :additional_ethnic_background,
              absence: true,
              unless: :ethnic_background_requires_additional_details?
  end

  class_methods do
    def ethnic_groups_enum = ETHNIC_GROUPS
    def ethnic_backgrounds_enum = ETHNIC_BACKGROUNDS
    def ethnic_backgrounds_by_group = ETHNIC_BACKGROUNDS_BY_GROUP
    def any_other_ethnic_backgrounds = ANY_OTHER_ETHNIC_BACKGROUNDS

    def ethnic_backgrounds_for_group(group)
      ethnic_backgrounds_by_group.fetch(group.to_sym)
    end
  end

  private

  def ethnic_background_requires_additional_details?
    return false if ethnic_background.blank?

    self.class.any_other_ethnic_backgrounds.include?(ethnic_background.to_sym)
  end
end
