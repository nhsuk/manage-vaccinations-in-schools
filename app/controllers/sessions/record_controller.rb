# frozen_string_literal: true

require "pagy/extras/array"

class Sessions::RecordController < ApplicationController
  include Pagy::Backend
  include SearchFormConcern
  include TodaysBatchConcern

  before_action :set_session
  before_action :set_search_form

  before_action :set_todays_batches, only: :show
  before_action :set_programme, except: :show
  before_action :set_batches, except: :show

  def show
    @programmes = @session.programmes

    scope =
      @session
        .patient_sessions
        .includes(
          :latest_note,
          patient: %i[consent_statuses triage_statuses vaccination_statuses]
        )
        .in_programmes(@session.programmes)
        .has_registration_status(%w[attending completed])

    scope = @form.apply(scope, programme: @programmes)

    patient_sessions =
      scope.select do |patient_session|
        patient_session.programmes.any? do |programme|
          patient_session.patient.consent_given_and_safe_to_vaccinate?(
            programme:
          )
        end
      end

    @pagy, @patient_sessions = pagy_array(patient_sessions)

    render layout: "full"
  end

  def edit_batch
    @todays_batch =
      authorize @batches.find_by(id: todays_batch_id(programme: @programme)),
                :edit?

    render :batch
  end

  def update_batch
    @todays_batch =
      authorize @batches.find_by(id: params.dig(:batch, :id)), :update?

    if @todays_batch
      self.todays_batch = @todays_batch

      redirect_to session_record_path(@session),
                  flash: {
                    success:
                      "The default batch for this session has been updated"
                  }
    else
      @todays_batch = Batch.new
      @todays_batch.errors.add(:id, "Select a default batch for this session")

      render :batch, status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(programmes: :vaccines).find_by!(
        slug: params[:session_slug]
      )
  end

  def set_todays_batches
    all_batches =
      @session.programmes.index_with do |programme|
        policy_scope(Batch)
          .where(vaccine: @session.vaccines)
          .not_archived
          .not_expired
          .find_by(id: todays_batch_id(programme:))
      end

    @todays_batches = all_batches.compact
  end

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end

  def set_batches
    @batches =
      policy_scope(Batch)
        .where(vaccine: @session.vaccines.where(programme: @programme))
        .not_archived
        .not_expired
        .order_by_name_and_expiration
  end
end
