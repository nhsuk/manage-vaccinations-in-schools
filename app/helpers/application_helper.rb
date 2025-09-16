# frozen_string_literal: true

module ApplicationHelper
  def h1(text = nil, size: "l", **options, &block)
    title_text = options.delete(:page_title) { text }

    options[:class] = ["nhsuk-heading-#{size}", options[:class]].compact.join(
      " "
    )

    content_for(:page_title, title_text) unless content_for?(:page_title)

    if block_given?
      if title_text.blank?
        raise ArgumentError, "Must provide title option when using block"
      end
      content_tag(:h1, options, &block)
    else
      content_tag(:h1, text, **options)
    end
  end

  def page_title(service_name)
    title = content_for(:page_title)

    if title.blank?
      raise "No page title set. Either use the <%= h1 %> helper in your page, \
or set it with content_for(:page_title)."
    end

    title = "Error: #{title}" if response.status == 422

    safe_join([title, service_name], " – ")
  end

  def app_version
    return APP_VERSION if defined?(APP_VERSION) && APP_VERSION.present?

    if Rails.env.local?
      version = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
      return nil if version.blank? || version == "HEAD"
      return version
    end

    nil
  end

  def icon_link_tag(name, **options)
    tag.link(href: asset_path(name), **options)
  end

  def manifest_link_tag(name, **options)
    digest = Digest::SHA256.hexdigest(app_version.to_s)[0, 8]
    tag.link(href: manifest_path(name, digest), **options)
  end

  def opengraph_image_tag(service_url, name)
    tag.meta(property: "og:image", content: "#{service_url}#{asset_path(name)}")
  end

  def cached_counts = TeamCachedCounts.new(current_team)
end
