# frozen_string_literal: true

class AppProgrammeNavigationComponent < ViewComponent::Base
  def initialize(programme, active:)
    super

    @programme = programme
    @active = active
  end

  def call
    render AppSecondaryNavigationComponent.new do |nav|
      nav.with_item(
        href: programme_path(programme),
        text: "Overview",
        selected: active == :overview
      )

      SECTIONS.each do |section|
        nav.with_item(
          href: public_send("programme_#{section}_path", programme),
          text: I18n.t("title", scope: [:programmes, section, :index]),
          selected: active == session
        )
      end
    end
  end

  private

  attr_reader :programme, :active

  SECTIONS = %i[cohorts sessions patients vaccinations].freeze
end
