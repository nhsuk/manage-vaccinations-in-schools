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
    transient { batch_count { 1 } }

    type { %w[flu hpv].sample }
    vaccines { [association(:vaccine, batch_count:, programme: instance)] }

    trait :hpv do
      type { "hpv" }
      vaccines do
        [association(:vaccine, :gardasil_9, batch_count:, programme: instance)]
      end
    end

    trait :hpv_all_vaccines do
      hpv
      vaccines do
        [
          association(:vaccine, :cervarix, batch_count:, programme: instance),
          association(:vaccine, :gardasil, batch_count:, programme: instance),
          association(:vaccine, :gardasil_9, batch_count:, programme: instance)
        ]
      end
    end

    trait :hpv_no_batches do
      batch_count { 0 }
      hpv
    end

    trait :flu do
      type { "flu" }
      vaccines do
        [
          association(
            :vaccine,
            :adjuvanted_quadrivalent,
            batch_count:,
            programme: instance
          ),
          association(
            :vaccine,
            :cell_quadrivalent,
            batch_count:,
            programme: instance
          ),
          association(
            :vaccine,
            :fluenz_tetra,
            batch_count:,
            programme: instance
          ),
          association(
            :vaccine,
            :quadrivalent_influenza,
            batch_count:,
            programme: instance
          ),
          association(
            :vaccine,
            :quadrivalent_influvac_tetra,
            batch_count:,
            programme: instance
          ),
          association(:vaccine, :supemtek, batch_count:, programme: instance)
        ]
      end
    end

    trait :flu_all_vaccines do
      flu
      vaccines do
        [
          association(
            :vaccine,
            :adjuvanted_quadrivalent,
            batch_count:,
            programme: instance
          ),
          association(
            :vaccine,
            :cell_quadrivalent,
            batch_count:,
            programme: instance
          ),
          association(
            :vaccine,
            :fluad_tetra,
            batch_count:,
            programme: instance
          ),
          association(
            :vaccine,
            :flucelvax_tetra,
            batch_count:,
            programme: instance
          ),
          association(
            :vaccine,
            :fluenz_tetra,
            batch_count:,
            programme: instance
          ),
          association(
            :vaccine,
            :quadrivalent_influenza,
            batch_count:,
            programme: instance
          ),
          association(
            :vaccine,
            :quadrivalent_influvac_tetra,
            batch_count:,
            programme: instance
          ),
          association(:vaccine, :supemtek, batch_count:, programme: instance)
        ]
      end
    end

    trait :flu_nasal_only do
      flu
      vaccines do
        [
          association(
            :vaccine,
            :fluenz_tetra,
            batch_count:,
            programme: instance
          )
        ]
      end
    end
  end
end
