require "rails_helper"

RSpec.describe ConsentFormMailer, type: :mailer do
  let(:team_email) { "england.mavis@nhs.net" }
  let(:team_phone) { "01900 705 045" }

  def consent_form(overrides = {})
    @consent_form ||=
      build(
        :consent_form,
        parent_email: "harry@hogwarts.edu",
        parent_name: "Harry Potter",
        first_name: "Albus",
        last_name: "Potter",
        common_name: "Severus",
        **overrides
      )
  end

  before do
    allow_any_instance_of(Mail::Notify::Mailer).to receive(:template_mail).with(
      notify_template_id,
      ->(options) { @template_options = options }
    )
  end

  describe "#confirmation" do
    let(:notify_template_id) { "7cda7ae5-99a2-4c40-9a3e-1863e23f7a73" }

    it "calls template_mail with correct personalisation" do
      described_class.confirmation(consent_form).deliver_now

      expect(@template_options).to include(
        personalisation: {
          full_and_preferred_patient_name: "Albus Potter (known as Severus)",
          location_name: consent_form.session.location.name,
          long_date: consent_form.session.date.strftime("%A %-d %B"),
          short_date: consent_form.session.date.strftime("%-d %B"),
          parent_name: "Harry Potter",
          short_patient_name: "Severus",
          short_patient_name_apos: "Severus'",
          team_email:,
          team_phone:
        },
        to: "harry@hogwarts.edu"
      )
    end

    it "calls template_mail correctly when common_name is nil" do
      described_class.confirmation(consent_form(common_name: nil)).deliver_now

      expect(@template_options[:personalisation]).to include(
        full_and_preferred_patient_name: "Albus Potter",
        short_patient_name: "Albus",
        short_patient_name_apos: "Albus'"
      )
    end

    it "calls template_mail correctly when first_name does not end in an s" do
      described_class.confirmation(
        consent_form(common_name: nil, first_name: "Harry")
      ).deliver_now

      expect(@template_options[:personalisation]).to include(
        short_patient_name: "Harry",
        short_patient_name_apos: "Harry's"
      )
    end
  end

  describe "#confirmation_needs_triage" do
    let(:notify_template_id) { "604ee667-c996-471e-b986-79ab98d0767c" }

    it "calls template_mail with correct personalisation" do
      described_class.confirmation_needs_triage(consent_form).deliver_now

      expect(@template_options).to include(
        personalisation: {
          full_and_preferred_patient_name: "Albus Potter (known as Severus)",
          location_name: consent_form.session.location.name,
          long_date: consent_form.session.date.strftime("%A %-d %B"),
          short_date: consent_form.session.date.strftime("%-d %B"),
          parent_name: "Harry Potter",
          short_patient_name: "Severus"
        },
        to: "harry@hogwarts.edu"
      )
    end
  end

  describe "#confirmation_injection" do
    let(:notify_template_id) { "4d09483a-8181-4acb-8ba3-7abd6c8644cd" }

    it "calls template_mail with correct personalisation" do
      described_class.confirmation_injection(
        consent_form(reason: :contains_gelatine)
      ).deliver_now

      expect(@template_options).to include(
        personalisation: {
          full_and_preferred_patient_name: "Albus Potter (known as Severus)",
          location_name: consent_form.session.location.name,
          long_date: consent_form.session.date.strftime("%A %-d %B"),
          short_date: consent_form.session.date.strftime("%-d %B"),
          parent_name: "Harry Potter",
          reason_for_refusal: "of the gelatine in the nasal spray"
        },
        to: "harry@hogwarts.edu"
      )
    end
  end

  describe "#confirmation_refused" do
    let(:notify_template_id) { "5a676dac-3385-49e4-98c2-fc6b45b5a851" }

    it "calls template_mail with correct personalisation" do
      described_class.confirmation_refused(consent_form).deliver_now

      expect(@template_options).to include(
        personalisation: {
          full_and_preferred_patient_name: "Albus Potter (known as Severus)",
          location_name: consent_form.session.location.name,
          long_date: consent_form.session.date.strftime("%A %-d %B"),
          short_date: consent_form.session.date.strftime("%-d %B"),
          parent_name: "Harry Potter",
          short_patient_name: "Severus",
          team_email:,
          team_phone:
        },
        to: "harry@hogwarts.edu"
      )
    end
  end
end
