# frozen_string_literal: true

class Imports::IssuesController < ApplicationController
  before_action :set_import_issues
  before_action :set_record, only: %i[show update]
  before_action :set_vaccination_record, only: %i[show update]
  before_action :set_patient, only: %i[show update]
  before_action :set_form, only: %i[show update]

  layout "full"

  def index
  end

  def show
  end

  def update
    if @form.save
      redirect_to imports_issues_path, flash: { success: "Record updated" }
    else
      render :show, status: :unprocessable_entity and return
    end
  end

  private

  def set_import_issues
    @vaccination_records =
      policy_scope(VaccinationRecord).with_pending_changes.distinct.includes(
        :batch,
        :location,
        :performed_by_user,
        session: :location,
        patient: %i[gp_practice school],
        vaccine: :programme
      )

    @patients =
      policy_scope(Patient)
        .with_pending_changes
        .distinct
        .eager_load(:gp_practice, :school)
        .preload(:school_moves, :sessions_for_current_academic_year)

    @import_issues =
      (@vaccination_records + @patients).uniq do |record|
        record.is_a?(VaccinationRecord) ? record.patient : record
      end
  end

  def set_record
    @record =
      (
        if params[:type] == "vaccination-record"
          @vaccination_records.find(params[:id])
        else
          @patients.find(params[:id])
        end
      )
  end

  def set_vaccination_record
    @vaccination_record = @record if @record.is_a?(VaccinationRecord)
  end

  def set_patient
    @patient = @record.is_a?(VaccinationRecord) ? @record.patient : @record
  end

  def set_form
    apply_changes = params.dig(:import_duplicate_form, :apply_changes)

    @form = ImportDuplicateForm.new(object: @record, apply_changes:)
  end
end
