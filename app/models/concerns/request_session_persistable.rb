# frozen_string_literal: true

module RequestSessionPersistable
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Dirty
  include ActiveRecord::AttributeAssignment

  def initialize(request_session:, current_user:, **attributes)
    @request_session = request_session
    @current_user = current_user

    super(
      (@request_session[self.class.request_session_key] || {}).merge(attributes)
    )

    clear_changes_information
  end

  def save(context: :update)
    reset_unused_fields
    return false if invalid?(context)
    @request_session[self.class.request_session_key] = attributes
    true
  end

  def save!(context: :update)
    raise RecordInvalid unless save(context:)
  end

  def update(...)
    assign_attributes(...)
    save(context: :update) # rubocop:disable Rails/SaveBang
  end

  def [](attr)
    public_send(attr)
  end

  def []=(attr, value)
    public_send("#{attr}=", value)
  end

  def reset!
    attribute_names.each { |attribute| self[attribute] = nil }
    save!(context: :create)
  end

  class RecordInvalid < StandardError
  end
end
