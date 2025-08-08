# frozen_string_literal: true

class SearchForm
  include RequestSessionPersistable

  def initialize(request_path:, request_session:, **attributes)
    @request_path = request_path

    # An empty string represents the "Any" option.
    has_query_parameters =
      attributes.any? { it.present? || it == "" || it == [] }

    request_session[request_session_key] = {} if has_query_parameters

    super(request_session:, **attributes.except("_clear"))

    save! if has_query_parameters
  end

  private

  def request_session_key = "search_form_#{path_key}"

  def path_key
    @path_key ||= Digest::MD5.hexdigest(@request_path).first(8)
  end

  def reset_unused_attributes
  end
end
