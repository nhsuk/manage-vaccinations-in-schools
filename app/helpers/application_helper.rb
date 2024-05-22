module ApplicationHelper
  def h1(text = nil, size: "l", **options, &block)
    title_text = options.fetch(:page_title, text)

    options[:class] = "nhsuk-heading-#{size}"
    options.delete(:page_title)

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

    [title, service_name].join(" - ")
  end

  def session_patient_sort_link(text, sort)
    link_to text,
            session_section_tab_path(
              session_id: params[:session_id],
              section: params[:section],
              tab: params[:tab],
              sort:,
              direction:
                (
                  if params[:sort] == sort.to_s && params[:direction] == "asc"
                    "desc"
                  else
                    "asc"
                  end
                )
            ),
            data: {
              turbo: "true",
              turbo_action: "replace"
            }
  end
end
