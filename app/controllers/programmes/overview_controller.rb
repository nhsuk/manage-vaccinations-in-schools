# frozen_string_literal: true

class Programmes::OverviewController < Programmes::BaseController
  def show
    patients = policy_scope(Patient).in_programmes([@programme])

    @consents =
      policy_scope(Consent).where(patient: patients, programme: @programme)
  end
end
