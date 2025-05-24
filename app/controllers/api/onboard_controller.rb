# frozen_string_literal: true

class API::OnboardController < ActionController::API
  def create
    onboarding = Onboarding.new(params.to_unsafe_h)

    if onboarding.invalid?
      render json: onboarding.errors, status: :unprocessable_entity
    else
      onboarding.save!
      render status: :created
    end
  end
end
