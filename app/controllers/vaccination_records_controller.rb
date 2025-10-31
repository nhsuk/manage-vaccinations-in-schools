# frozen_string_literal: true

class VaccinationRecordsController < ApplicationController
  include VaccinationMailerConcern

  before_action :set_vaccination_record

  include PatientLoggingConcern

  before_action :set_breadcrumb_items, only: :show
  before_action :set_return_to, only: %i[confirm_destroy destroy]

  def show
  end

  def update
    DraftVaccinationRecord.new(
      request_session: session,
      current_user:
    ).read_from!(@vaccination_record)

    redirect_to draft_vaccination_record_path("confirm")
  end

  def confirm_destroy
    authorize @vaccination_record, :destroy?
    render :destroy
  end

  def destroy
    authorize @vaccination_record

    @vaccination_record.discard!

    StatusUpdater.call(patient: @vaccination_record.patient)

    if @vaccination_record.confirmation_sent?
      send_vaccination_deletion(@vaccination_record)
    end

    StatusUpdater.call(patient: @vaccination_record.patient)

    redirect_to @return_to, flash: { success: "Vaccination record archived" }
  end

  private

  def set_vaccination_record
    @vaccination_record =
      policy_scope(VaccinationRecord).includes(
        :batch,
        :immunisation_imports,
        :location,
        :performed_by_user,
        :programme,
        patient: [
          :gp_practice,
          :school,
          { parent_relationships: :parent, vaccination_records: :programme }
        ],
        session: %i[session_dates],
        vaccine: :programme
      ).find(params[:id])

    @patient = @vaccination_record.patient
    @programme = @vaccination_record.programme
    @session = @vaccination_record.session
  end

  def set_breadcrumb_items
    @breadcrumb_items = [
      { text: t("dashboard.index.title"), href: dashboard_path }
    ]

    if @session
      @breadcrumb_items << {
        text: t("sessions.index.title"),
        href: sessions_path
      }
      @breadcrumb_items << {
        text: @session.location.name,
        href: session_path(@session)
      }
      @breadcrumb_items << {
        text: t("sessions.tabs.patients"),
        href: session_patients_path(@session)
      }
      @breadcrumb_items << {
        text: @patient.full_name,
        href:
          session_patient_programme_path(
            @session,
            @patient,
            @programme,
            return_to: "outcome"
          )
      }
    else
      @breadcrumb_items << {
        text: t("patients.index.title"),
        href: patients_path
      }
      @breadcrumb_items << {
        text: @patient.full_name,
        href: patient_path(@patient)
      }
    end
  end

  def set_return_to
    @return_to = params[:return_to] || patient_path(@patient)
  end

  def patient_id_for_logging
    @patient.id
  end
end
