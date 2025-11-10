# frozen_string_literal: true

# == Schema Information
#
# Table name: programmes
#
#  id         :bigint           not null, primary key
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_programmes_on_type  (type) UNIQUE
#
FactoryBot.define do
  factory :programme do
    type { Programme.types.keys.sample }

    trait :hpv do
      type { "hpv" }

      after(:create) do |programme|
        create(:vaccine, :cervarix, programme:)
        create(:vaccine, :gardasil, programme:)
        create(:vaccine, :gardasil_9, programme:)
      end
    end

    trait :flu do
      type { "flu" }

      after(:create) do |programme|
        create(:vaccine, :fluenz, programme:)
        create(:vaccine, :cell_based_trivalent, programme:)
        create(:vaccine, :vaxigrip, programme:)
        create(:vaccine, :viatris, programme:)
      end
    end

    trait :menacwy do
      type { "menacwy" }

      after(:create) do |programme|
        create(:vaccine, :menquadfi, programme:)
        create(:vaccine, :menveo, programme:)
        create(:vaccine, :nimenrix, programme:)
      end
    end

    trait :mmr do
      type { "mmr" }

      after(:create) do |programme|
        create(:vaccine, :priorix, programme:)
        create(:vaccine, :vaxpro, programme:)
      end
    end

    trait :td_ipv do
      type { "td_ipv" }

      after(:create) { |programme| create(:vaccine, :revaxis, programme:) }
    end
  end
end
