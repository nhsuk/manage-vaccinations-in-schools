class AppTabComponent < GovukComponent::Base
  using HTMLAttributesUtils

  renders_many :tabs, "Tab"

  attr_reader :title, :id

  def initialize(title:, id: nil, classes: [], html_attributes: {})
    @title = title
    @id = id

    super(classes:, html_attributes:)
  end

  private

  def default_attributes
    { id:, class: "#{brand}-tabs", data: { module: "#{brand}-tabs" } }
  end

  class Tab < GovukComponent::Base
    attr_reader :label, :text

    def initialize(label:, text: nil, id: nil, classes: [], html_attributes: {})
      @label = label
      @text = text
      @id = id || label.parameterize

      super(classes:, html_attributes:)
    end

    def id(prefix: nil)
      [prefix, @id].join
    end

    def hidden_class(tab_index = nil)
      return [] if tab_index&.zero?

      ["#{brand}-tabs__panel--hidden"]
    end

    def li_classes(tab_index = nil)
      class_names(
        "#{brand}-tabs__list-item",
        "#{brand}-tabs__list-item--selected" => tab_index&.zero?
      ).split
    end

    def li_link
      link_to(label, id(prefix: "#"), class: "#{brand}-tabs__tab")
    end

    def default_attributes
      { id:, class: "#{brand}-tabs__panel" }
    end

    def combined_attributes(tab_index)
      html_attributes.deep_merge_html_attributes(
        { class: hidden_class(tab_index) }
      ).deep_tidy_html_attributes
    end

    def call
      content || text.html_safe || raise(ArgumentError, "no text or content")
    end
  end
end
