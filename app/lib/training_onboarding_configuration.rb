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
        family_name: identifier,
        fallback_role: role
      }
    end
  end

  def schools
    scope =
      Location.school.open.where(subteam_id: nil).order("RANDOM()").limit(10)

    # Make sure we get a good mix of primary and secondary schools.
    primary_schools = scope.has_year_groups([1, 2, 3, 4, 5, 6]).pluck(:urn)
    secondary_schools = scope.has_year_groups([7, 8, 9, 10, 11]).pluck(:urn)

    { generic: primary_schools + secondary_schools }
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
