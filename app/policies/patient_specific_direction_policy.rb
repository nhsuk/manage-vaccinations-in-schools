# frozen_string_literal: true

class PatientSpecificDirectionPolicy < ApplicationPolicy
  def create?
    user.can_add_psd?
  end
end
