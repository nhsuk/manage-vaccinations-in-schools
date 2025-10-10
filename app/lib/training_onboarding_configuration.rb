# frozen_string_literal: true

class TrainingOnboardingConfiguration
  def initialize(ods_code:, workgroup:)
    @ods_code = ods_code
    @workgroup = workgroup
  end

  def call
    { organisation:, team:, programmes:, subteams:, users:, schools:, clinics: }
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :ods_code, :workgroup

  def identifier = "#{ods_code} (#{workgroup})"

  def name = "#{identifier} training"

  def email = "#{workgroup}@example.com"

  def phone = "07700 900815"

  def organisation
    { ods_code: }
  end

  def team
    {
      workgroup:,
      name:,
      email:,
      phone:,
      careplus_venue_code: ods_code,
      privacy_notice_url: "https://example.com/privacy-notice-#{workgroup}",
      privacy_policy_url: "https://example.com/privacy-policy-#{workgroup}"
    }
  end

  def programmes
    %w[flu hpv menacwy td_ipv]
  end

  def subteams
    { generic: { name:, email:, phone: } }
  end

  def users
    User.fallback_roles.keys.map do |role|
      email_and_password = "#{role.dasherize}.#{workgroup}@example.com"

      {
        email: email_and_password,
        password: email_and_password,
        given_name: role.humanize,
        family_name: identifier
      }
    end
  end

  def schools
    {
      generic:
        Location
          .school
          .open
          .where(subteam_id: nil)
          .order("RANDOM()")
          .limit(20)
          .pluck(:urn)
    }
  end

  def clinics
    {
      generic: [
        {
          name: "Training #{identifier} clinic",
          address_line_1: "Training clinic way",
          address_town: "Training town",
          address_postcode: "SW1A 1AA"
        }
      ]
    }
  end
end
