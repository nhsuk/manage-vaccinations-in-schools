# frozen_string_literal: true

class DraftConsent
  include RequestSessionPersistable
  include EditableWrapper
  include WizardStepConcern

  include ActiveRecord::AttributeMethods::Serialization
  include HasHealthAnswers

  attr_reader :new_or_existing_contact
  attr_accessor :triage_form_valid

  attribute :health_answers, array: true, default: []
  attribute :notes, :string
  attribute :notify_parents, :boolean
  attribute :parent_email, :string
  attribute :parent_full_name, :string
  attribute :parent_id, :integer
  attribute :parent_phone, :string
  attribute :parent_phone_receive_updates, :boolean
  attribute :parent_relationship_other_name, :string
  attribute :parent_relationship_type, :string
  attribute :parent_responsibility, :boolean
  attribute :patient_session_id, :integer
  attribute :programme_id, :integer
  attribute :reason_for_refusal, :string
  attribute :recorded_by_user_id, :integer
  attribute :response, :string
  attribute :route, :string
  attribute :triage_notes, :string
  attribute :triage_status_and_vaccine_method, :string
  attribute :vaccine_methods, array: true, default: []
  attribute :injection_alternative, :boolean

  FLU_RESPONSES = %w[given_nasal given_injection].freeze

  def wizard_steps
    [
      :who,
      (:parent_details unless via_self_consent?),
      (:route unless via_self_consent?),
      :agree,
      (:notify_parents if response_given? && via_self_consent?),
      (:questions if response_given?),
      (:triage if triage_allowed? && response_given?),
      (:reason if response_refused?),
      (:notes if notes_required?),
      :confirm
    ].compact
  end

  on_wizard_step :who, exact: true do
    validates :new_or_existing_contact, presence: true
  end

  on_wizard_step :parent_details, exact: true do
    validates :parent_phone_receive_updates, inclusion: { in: [true, false] }
  end

  validates :parent_email,
            notify_safe_email: {
              allow_blank: true
            },
            presence: {
              if: -> do
                required_for_step?(:parent_details, exact: true) &&
                  parent_phone.blank?
              end
            }
  validates :parent_phone,
            phone: {
              allow_blank: true
            },
            presence: {
              if: -> do
                required_for_step?(:parent_details, exact: true) &&
                  (parent_email.blank? || parent_phone_receive_updates)
              end
            }

  with_options if: -> { required_for_step?(:parent_details, exact: true) } do
    validates :parent_full_name, presence: true
    validates :parent_relationship_type,
              inclusion: {
                in: ParentRelationship.types.keys
              }
  end

  with_options if: -> do
                 parent_relationship_type == "other" &&
                   required_for_step?(:parent_details, exact: true)
               end do
    validates :parent_relationship_other_name,
              presence: true,
              length: {
                maximum: 300
              }
    validates :parent_responsibility, inclusion: [true]
  end

  on_wizard_step :route, exact: true do
    validates :route, inclusion: { in: Consent.routes.keys }
  end

  on_wizard_step :agree, exact: true do
    validates :response,
              inclusion: {
                in: Consent.responses.keys + FLU_RESPONSES
              }
    validates :injection_alternative,
              inclusion: {
                in: [true, false]
              },
              if: -> { response == "given_nasal" }
  end

  on_wizard_step :notify_parents, exact: true do
    validates :notify_parents, inclusion: { in: [true, false] }
  end

  on_wizard_step :reason, exact: true do
    validates :reason_for_refusal,
              inclusion: {
                in: Consent.reason_for_refusals.keys
              }
  end

  on_wizard_step :questions, exact: true do
    validate :health_answers_are_valid
  end

  on_wizard_step :triage, exact: true do
    validates :triage_form_valid, presence: true
  end

  on_wizard_step :notes, exact: true do
    validates :notes, presence: true, length: { maximum: 1000 }
  end

  on_wizard_step :confirm, exact: true do
    validates :outcome, presence: true
  end

  def new_or_existing_contact=(value)
    @new_or_existing_contact = value

    if value == "new"
      self.route = nil
      self.parent = nil
    elsif value == "patient"
      self.route = "self_consent"
      self.parent = nil
    else
      self.route = nil
      self.parent =
        patient.parents.find_by(id: value) ||
          Parent.where(consents: patient.consents.where(programme:)).find_by(
            id: value
          )
    end
  end

  def consent
    ConsentPolicy::Scope
      .new(@current_user, Consent)
      .resolve
      .find_by(id: editing_id)
  end

  def consent=(value)
    self.editing_id = value.id
  end

  def update_vaccine_methods
    if flu_response?
      if response == "given_nasal"
        self.vaccine_methods = ["nasal"]
        vaccine_methods << "injection" if injection_alternative
      elsif response == "given_injection"
        self.vaccine_methods = ["injection"]
        self.injection_alternative = nil
      end
    elsif response_given?
      self.vaccine_methods = ["injection"]
      self.injection_alternative = nil
    else
      self.vaccine_methods = []
      self.injection_alternative = nil
    end
  end

  def parent
    return nil if via_self_consent?

    parent = Parent.find_by(id: parent_id) || Parent.new

    parent.email = parent_email
    parent.full_name = parent_full_name
    parent.phone = parent_phone
    parent.phone_receive_updates = parent_phone_receive_updates

    # We can't use find_or_initialize_by here because we need the object to
    # remain attached to the parent so we can save the parent with its
    # relationships.

    parent_relationship =
      parent.parent_relationships.find { it.patient_id == patient_id } ||
        parent.parent_relationships.build(patient_id:)

    parent_relationship.assign_attributes(
      patient:, # acts as preload
      type: parent_relationship_type,
      other_name: parent_relationship_other_name
    )

    if parent_relationship.new_record?
      parent.parent_relationships << parent_relationship
    end

    parent
  end

  def parent=(value)
    self.parent_id = value&.id

    parent_relationship = value&.parent_relationships&.find_by(patient_id:)

    self.parent_email = patient.restricted? ? "" : value&.email
    self.parent_full_name = value&.full_name
    self.parent_phone = patient.restricted? ? "" : value&.phone
    self.parent_phone_receive_updates = value&.phone_receive_updates
    self.parent_relationship_type = parent_relationship&.type
    self.parent_relationship_other_name = parent_relationship&.other_name
    self.parent_responsibility = true # if consent was submitted this must've been true
  end

  def patient_session
    return nil if patient_session_id.nil?

    PatientSessionPolicy::Scope
      .new(@current_user, PatientSession)
      .resolve
      .find(patient_session_id)
  end

  def patient_session=(value)
    self.patient_session_id = value.id
  end

  delegate :location,
           :organisation,
           :patient,
           :session,
           to: :patient_session,
           allow_nil: true

  def patient_id
    patient&.id
  end

  def organisation_id
    organisation&.id
  end

  def recorded_by
    return nil if recorded_by_user_id.nil?

    User.find(recorded_by_user_id)
  end

  def recorded_by=(value)
    self.recorded_by_user_id = value.id
  end

  def programme
    return nil if programme_id.nil?

    ProgrammePolicy::Scope
      .new(@current_user, Programme)
      .resolve
      .find(programme_id)
  end

  def programme=(value)
    self.programme_id = value.id
  end

  def write_to!(consent, triage_form:)
    self.response = "given" if flu_response?
    super(consent)

    consent.parent = parent
    consent.submitted_at ||= Time.current

    if triage_allowed? && response_given?
      triage_form.notes = triage_notes || ""
      triage_form.current_user = recorded_by
      triage_form.status_and_vaccine_method = triage_status_and_vaccine_method
    end
  end

  def via_self_consent?
    route == "self_consent"
  end

  def flu_response?
    FLU_RESPONSES.include?(response)
  end

  def response_given?
    response == "given" || FLU_RESPONSES.include?(response)
  end

  def response_refused?
    response == "refused"
  end

  def responded_at
    Time.current
  end

  def invalidated?
    false
  end

  def withdrawn?
    false
  end

  def consent_form
    nil
  end

  def parent_relationship
    parent
      &.parent_relationships
      &.find { it.patient_id == patient_id }
      &.tap do
        it.patient = patient # acts as preload
        it.type = parent_relationship_type
        it.other_name = parent_relationship_other_name
      end
  end

  def human_enum_name(attribute)
    Consent.human_enum_name(attribute, send(attribute))
  end

  def vaccine_method_injection? = vaccine_methods.include?("injection")

  def vaccine_method_nasal? = vaccine_methods.include?("nasal")

  def seed_health_questions
    return unless response_given?

    # If the health answers change due to the chosen vaccines changing, we
    # want to try and keep as much as what the parents already wrote intact.
    # We do this be saving the answers to the question title (as the IDs
    # and ordering can change).

    existing_health_answers =
      health_answers.each_with_object({}) do |health_answer, memo|
        memo[health_answer.question] = {
          response: health_answer.response,
          notes: health_answer.notes
        }
      end

    vaccines = programme.vaccines.where(method: vaccine_methods)

    self.health_answers =
      HealthAnswersDeduplicator
        .call(vaccines:)
        .map do |health_answer|
          if (
               existing_health_answer =
                 existing_health_answers[health_answer.question]
             )
            health_answer.response = existing_health_answer[:response]
            health_answer.notes = existing_health_answer[:notes]
          end

          health_answer
        end
  end

  private

  def readable_attribute_names
    writable_attribute_names + %w[parent]
  end

  def writable_attribute_names
    %w[
      health_answers
      notes
      notify_parents
      patient_id
      programme_id
      reason_for_refusal
      recorded_by_user_id
      response
      route
      organisation_id
      vaccine_methods
    ]
  end

  def notes_required?
    response_refused? && reason_for_refusal != "personal_choice"
  end

  def triage_allowed?
    TriagePolicy.new(@current_user, Triage).new?
  end

  def triage_status_and_vaccine_method_options
    Triage.new(patient:, programme:).status_and_vaccine_method_options
  end

  def health_answers_are_valid
    return if health_answers.map(&:valid?).all?

    health_answers.each_with_index do |health_answer, index|
      next unless health_answer.requires_notes?

      health_answer.errors.messages.each do |field, messages|
        messages.each do |message|
          errors.add("question-#{index}-#{field}", message)
        end
      end
    end
  end

  def request_session_key = "consent"

  def reset_unused_fields
    update_vaccine_methods

    self.reason_for_refusal = nil unless response_refused?
    self.notes = "" unless notes_required?

    if response_given?
      seed_health_questions if health_answers.empty?
    else
      self.health_answers = []
    end
  end
end
