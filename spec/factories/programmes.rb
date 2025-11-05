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
    vaccines { [association(:vaccine, programme: instance)] }

    trait :hpv do
      type { "hpv" }
      vaccines do
        [
          association(:vaccine, :cervarix, programme: instance),
          association(:vaccine, :gardasil, programme: instance),
          association(:vaccine, :gardasil_9, programme: instance)
        ]
      end
    end

    trait :flu do
      type { "flu" }
      vaccines do
        [
          association(:vaccine, :fluenz, programme: instance),
          association(:vaccine, :cell_based_trivalent, programme: instance),
          association(:vaccine, :vaxigrip, programme: instance),
          association(:vaccine, :viatris, programme: instance)
        ]
      end
    end

    trait :menacwy do
      type { "menacwy" }
      vaccines do
        [
          association(:vaccine, :menquadfi, programme: instance),
          association(:vaccine, :menveo, programme: instance),
          association(:vaccine, :nimenrix, programme: instance)
        ]
      end
    end

    trait :mmr do
      type { "mmr" }
      vaccines do
        [
          association(:vaccine, :priorix, programme: instance),
          association(:vaccine, :vaxpro, programme: instance)
        ]
      end
    end

    trait :td_ipv do
      type { "td_ipv" }
      vaccines { [association(:vaccine, :revaxis, programme: instance)] }
    end
  end
end
