# frozen_string_literal: true

class AppProgrammeNavigationComponent < ViewComponent::Base
  def initialize(programme, active:)
    super

    @programme = programme
    @active = active
  end

  def call
    render AppSecondaryNavigationComponent.new do |nav|
      SECTIONS.each do |section|
        action = section == :overview ? :show : :index

        nav.with_item(
          href: public_send("programme_#{section}_path", programme),
          text: I18n.t("title", scope: [:programmes, section, action]),
          selected: active == section
        )
      end
    end
  end

  private

  attr_reader :programme, :active

  SECTIONS = %i[overview cohorts sessions patients vaccinations].freeze
end
