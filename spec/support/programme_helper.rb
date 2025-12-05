# frozen_string_literal: true

class ProgrammeHelper
  def self.create_vaccines!
    FactoryBot.create(:vaccine, :cervarix, programme: Programme.hpv)
    FactoryBot.create(:vaccine, :gardasil, programme: Programme.hpv)
    FactoryBot.create(:vaccine, :gardasil_9, programme: Programme.hpv)

    FactoryBot.create(:vaccine, :fluenz, programme: Programme.flu)
    FactoryBot.create(:vaccine, :cell_based_trivalent, programme: Programme.flu)
    FactoryBot.create(:vaccine, :vaxigrip, programme: Programme.flu)
    FactoryBot.create(:vaccine, :viatris, programme: Programme.flu)

    FactoryBot.create(:vaccine, :menquadfi, programme: Programme.menacwy)
    FactoryBot.create(:vaccine, :menveo, programme: Programme.menacwy)
    FactoryBot.create(:vaccine, :nimenrix, programme: Programme.menacwy)

    FactoryBot.create(:vaccine, :priorix, programme: Programme.mmr)
    FactoryBot.create(:vaccine, :vaxpro, programme: Programme.mmr)

    FactoryBot.create(:vaccine, :pro_quad, programme: Programme.mmr)
    FactoryBot.create(:vaccine, :priorix_tetra, programme: Programme.mmr)

    FactoryBot.create(:vaccine, :revaxis, programme: Programme.td_ipv)
  end
end
