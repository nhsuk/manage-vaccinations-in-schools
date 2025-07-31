# frozen_string_literal: true

class DraftClassImportsController < ApplicationController
  before_action :set_draft_class_import
  before_action :set_location

  include WizardControllerConcern

  before_action :set_location_options,
                only: %i[show update],
                if: -> { current_step == :location }
  before_action :set_year_group_options,
                only: %i[show update],
                if: -> { current_step == :year_groups }

  skip_after_action :verify_policy_scoped, only: %i[show update]

  def new
    @draft_class_import.reset!

    if (location = policy_scope(Location).find_by(id: params[:location_id]))
      @draft_class_import.update!(location:)
      redirect_to draft_class_import_path("year-groups")
    else
      redirect_to draft_class_import_path(Wicked::FIRST_STEP)
    end
  end

  def show
    render_wizard
  end

  def update
    @draft_class_import.assign_attributes(update_params)

    render_wizard @draft_class_import
  end

  private

  def set_draft_class_import
    @draft_class_import =
      DraftClassImport.new(request_session: session, current_user:)
  end

  def set_location
    @location = @draft_class_import.location
  end

  def set_location_options
    @location_options = policy_scope(Location).school
  end

  def set_year_group_options
    year_groups =
      @location
        .programme_year_groups
        .where(programme: current_organisation.programmes)
        .pluck_year_groups

    @year_group_options =
      year_groups.map do |year_group|
        OpenStruct.new(
          value: year_group,
          label: helpers.format_year_group(year_group)
        )
      end
  end

  def set_steps
    self.steps = @draft_class_import.wizard_steps
  end

  def finish_wizard_path
    new_class_import_path
  end

  def update_params
    if current_step == :location
      {
        location_id: params.dig(:draft_class_import, :location_id),
        wizard_step: current_step
      }
    elsif current_step == :year_groups
      {
        year_groups:
          (params.dig(:draft_class_import, :year_groups) || []).compact_blank,
        wizard_step: current_step
      }
    end
  end
end
