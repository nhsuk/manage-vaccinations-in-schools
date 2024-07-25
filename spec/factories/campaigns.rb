# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :integer
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :campaign do
    transient { batch_count { 1 } }

    team
    hpv

    trait :hpv do
      name { "HPV" }
      vaccines { [create(:vaccine, :hpv, batch_count:)] }
    end

    trait :hpv_no_batches do
      transient { batch_count { 0 } }
      hpv
    end

    trait :flu do
      name { "Flu" }
      vaccines do
        [
          create(:vaccine, :flu, batch_count:),
          create(:vaccine, :quadrivalent_influenza, batch_count:)
        ]
      end
    end

    trait :flu_nasal_only do
      name { "Flu" }
      vaccines { [create(:vaccine, :flu, batch_count:)] }
    end
  end
end
