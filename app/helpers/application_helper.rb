module ApplicationHelper
  def h1(text = nil, **options, &block)
    title_text = options[:page_title] || text
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

  def session_patient_consents_path(*args, **kwargs)
    session_patient_path(*args, **kwargs.merge(route: "consents"))
  end

  def session_patient_triage_path(*args, **kwargs)
    session_patient_path(*args, **kwargs.merge(route: "triage"))
  end

  def session_patient_vaccinations_path(*args, **kwargs)
    session_patient_path(*args, **kwargs.merge(route: "vaccinations"))
  end
end
