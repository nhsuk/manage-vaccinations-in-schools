# frozen_string_literal: true

# == Schema Information
#
# Table name: programmes
#
#  id            :bigint           not null, primary key
#  academic_year :integer
#  end_date      :date
#  name          :string
#  start_date    :date
#  type          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  team_id       :integer          not null
#
# Indexes
#
#  idx_on_name_type_academic_year_team_id_f5cd28cbec  (name,type,academic_year,team_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :programme do
    transient { batch_count { 1 } }

    team

    name { "Programme" }
    type { %w[flu hpv].sample }
    academic_year { Time.zone.today.year }
    start_date { Date.new(academic_year, 9, 1) }
    end_date { Date.new(academic_year + 1, 7, 31) }

    vaccines { [association(:vaccine, type:, batch_count:)] }

    trait :hpv do
      name { "HPV" }
      type { "hpv" }
      vaccines { [association(:vaccine, :gardasil_9, batch_count:)] }
    end

    trait :hpv_all_vaccines do
      hpv
      vaccines do
        [
          association(:vaccine, :cervarix, batch_count:),
          association(:vaccine, :gardasil, batch_count:),
          association(:vaccine, :gardasil_9, batch_count:)
        ]
      end
    end

    trait :hpv_no_batches do
      batch_count { 0 }
      hpv
    end

    trait :flu do
      name { "Flu" }
      type { "flu" }
      vaccines do
        [
          association(:vaccine, :adjuvanted_quadrivalent, batch_count:),
          association(:vaccine, :cell_quadrivalent, batch_count:),
          association(:vaccine, :fluenz_tetra, batch_count:),
          association(:vaccine, :quadrivalent_influenza, batch_count:),
          association(:vaccine, :quadrivalent_influvac_tetra, batch_count:),
          association(:vaccine, :supemtek, batch_count:)
        ]
      end
    end

    trait :flu_all_vaccines do
      flu
      vaccines do
        [
          association(:vaccine, :adjuvanted_quadrivalent, batch_count:),
          association(:vaccine, :cell_quadrivalent, batch_count:),
          association(:vaccine, :fluad_tetra, batch_count:),
          association(:vaccine, :flucelvax_tetra, batch_count:),
          association(:vaccine, :fluenz_tetra, batch_count:),
          association(:vaccine, :quadrivalent_influenza, batch_count:),
          association(:vaccine, :quadrivalent_influvac_tetra, batch_count:),
          association(:vaccine, :supemtek, batch_count:)
        ]
      end
    end

    trait :flu_nasal_only do
      name { "Flu" }
      vaccines { [association(:vaccine, :fluenz_tetra, batch_count:)] }
    end
  end
end
