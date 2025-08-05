# frozen_string_literal: true

class API::Testing::OnboardController < API::Testing::BaseController
  def create
    onboarding = Onboarding.new(params.to_unsafe_h)

    if onboarding.invalid?
      render json: onboarding.errors, status: :unprocessable_content
    else
      onboarding.save!(create_sessions_for_previous_academic_year: true)
      render status: :created
    end
  end
end
