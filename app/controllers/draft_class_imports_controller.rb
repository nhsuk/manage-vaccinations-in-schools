# frozen_string_literal: true

class DraftClassImportsController < ApplicationController
  before_action :set_draft_class_import
  before_action :set_session

  include WizardControllerConcern

  before_action :set_year_group_options,
                only: %i[show update],
                if: -> { current_step == :year_groups }

  skip_after_action :verify_policy_scoped, only: %i[show update]

  def new
    session = policy_scope(Session).find_by!(slug: params[:session_slug])

    @draft_class_import.reset!
    @draft_class_import.update!(session:)

    redirect_to draft_class_import_path(Wicked::FIRST_STEP)
  end

  def show
    if current_step == :year_groups &&
         !Flipper.enabled?(:class_import_year_groups)
      @draft_class_import.update!(year_groups: @session.year_groups)
      skip_step
    end

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

  def set_session
    @session = @draft_class_import.session
  end

  def set_steps
    self.steps = @draft_class_import.wizard_steps
  end

  def set_year_group_options
    @year_group_options =
      (@session.year_groups & @session.location.year_groups).map do |year_group|
        OpenStruct.new(
          value: year_group,
          label: helpers.format_year_group(year_group)
        )
      end
  end

  def finish_wizard_path
    new_class_import_path
  end

  def update_params
    {
      year_groups:
        (params.dig(:draft_class_import, :year_groups) || []).compact_blank,
      wizard_step: current_step
    }
  end
end
