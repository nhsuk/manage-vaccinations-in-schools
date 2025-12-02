# frozen_string_literal: true

class AppSearchInputComponent < ViewComponent::Base
  def initialize(name:, value: nil, placeholder: nil, label: {}, icon: {})
    @name = name.to_s
    @value = value
    @placeholder = placeholder
    @id = "#{name}-field"
    @label = build_label(label)
    @icon = build_icon(icon)
  end

  attr_reader :name, :value, :placeholder, :id, :label, :icon

  private

  def build_label(label)
    defaults = { text: "Search", hidden: false }
    OpenStruct.new(defaults.merge(label))
  end

  def build_icon(icon)
    defaults = { text: "Search" }
    OpenStruct.new(defaults.merge(icon))
  end

  def label_classes
    classes = ["nhsuk-label"]
    classes << "nhsuk-u-visually-hidden" if label.hidden
    classes.join(" ")
  end
end
