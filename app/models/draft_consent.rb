# frozen_string_literal: true

class DraftConsent
  include RequestSessionPersistable
  include EditableWrapper
  include WizardStepConcern

  include ActiveRecord::AttributeMethods::Serialization

  def self.request_session_key
    "consent"
  end

  attr_reader :new_or_existing_contact

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
  attribute :triage_status, :string

  serialize :health_answers, coder: HealthAnswer::ArraySerializer

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
    validates :parent_email, notify_safe_email: true
    validates :parent_phone,
              presence: {
                if: :parent_phone_receive_updates
              },
              phone: {
                allow_blank: true
              }
  end

  with_options if: -> do
                 parent_id.nil? &&
                   required_for_step?(:parent_details, exact: true)
               end do
    validates :parent_full_name, presence: true
    validates :parent_relationship_type,
              inclusion: {
                in: ParentRelationship.types.keys
              }
  end

  with_options if: -> do
                 parent_id.nil? && parent_relationship_type == "other" &&
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
    validates :response, inclusion: { in: Consent.responses.keys }
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
    validates :triage_status, inclusion: { in: Triage.statuses.keys }
    validates :triage_notes, length: { maximum: 1000 }
  end

  on_wizard_step :confirm, exact: true do
    validates :outcome, presence: true
  end

  def new_or_existing_contact=(value)
    @new_or_existing_contact = value

    if value == "new"
      self.parent = nil
    elsif value == "patient"
      self.route = "self_consent"
      self.parent = nil
    else
      self.parent =
        patient.parents.find_by(id: value) ||
          Parent.where(consents: patient_session.consents).find_by(id: value)
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

  def parent
    return nil if via_self_consent?

    parent = Parent.find_by(id: parent_id) || Parent.new

    parent.email = parent_email
    parent.full_name = parent_full_name
    parent.phone = parent_phone
    parent.phone_receive_updates = parent_phone_receive_updates

    parent
      .parent_relationships
      .find_or_initialize_by(patient:)
      .assign_attributes(
        type: parent_relationship_type,
        other_name: parent_relationship_other_name
      )

    parent
  end

  def parent=(value)
    self.parent_id = value&.id

    parent_relationship = value&.relationship_to(patient:)

    self.parent_email = patient.restricted? ? "" : value&.email
    self.parent_full_name = value&.full_name
    self.parent_phone = patient.restricted? ? "" : value&.phone
    self.parent_phone_receive_updates = value&.phone_receive_updates
    self.parent_relationship_type = parent_relationship&.type
    self.parent_relationship_other_name = parent_relationship&.other_name
  end

  def patient_session
    PatientSessionPolicy::Scope
      .new(@current_user, PatientSession)
      .resolve
      .find_by(id: patient_session_id)
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
    User.find_by(id: recorded_by_user_id)
  end

  def recorded_by=(value)
    self.recorded_by_user_id = value.id
  end

  def programme
    ProgrammePolicy::Scope
      .new(@current_user, Programme)
      .resolve
      .find_by(id: programme_id)
  end

  def programme=(value)
    self.programme_id = value.id
  end

  def editable_attribute_names
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
    ]
  end

  def write_to!(consent, triage:)
    super(consent)

    consent.parent = parent
    consent.recorded_at = Time.current

    if triage_allowed? && response_given?
      triage.notes = triage_notes || ""
      triage.organisation = organisation
      triage.patient = patient
      triage.performed_by_user_id = recorded_by_user_id
      triage.programme = programme
      triage.status = triage_status
    end
  end

  def notes_required?
    response_refused? && reason_for_refusal != "personal_choice"
  end

  def via_self_consent?
    route == "self_consent"
  end

  def response_given?
    response == "given"
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

  delegate :restricted?, to: :patient

  def consent_form
    nil
  end

  def parent_relationship
    parent&.relationship_to(patient:)
  end

  def who_responded
    via_self_consent? ? "Child (Gillick competent)" : parent_relationship.label
  end

  private

  def triage_allowed?
    TriagePolicy.new(@current_user, Triage).new?
  end

  def health_answers_are_valid
    return if health_answers.map(&:valid?).all?

    health_answers.each_with_index do |health_answer, index|
      health_answer.errors.messages.each do |field, messages|
        messages.each do |message|
          errors.add("question-#{index}-#{field}", message)
        end
      end
    end
  end

  def reset_unused_fields
    self.reason_for_refusal = nil unless response_refused?

    if response_given?
      self.notes = ""

      if health_answers.empty?
        vaccine = programme.vaccines.first # assumes all vaccines in the programme have the same questions
        self.health_answers = vaccine.health_questions.to_health_answers
      end
    else
      self.health_answers = []
    end
  end
end
