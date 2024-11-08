# frozen_string_literal: true

module EditableWrapper
  extend ActiveSupport::Concern

  included { attribute :editing_id, :integer }

  def editing?
    editing_id != nil
  end

  def read_from!(instance)
    self.editing_id = instance.id

    attribute_names
      .excluding("editing_id")
      .each do |attribute|
        public_send("#{attribute}=", instance.public_send(attribute))
      end

    save!(context: :create)
  end

  def write_to!(instance)
    if !editing? && instance.persisted?
      raise CannotWritePersistedRecord
    elsif editing? && editing_id != instance.id
      raise CannotWriteDifferentRecord
    end

    attribute_names
      .excluding("editing_id")
      .each do |attribute|
        instance.public_send("#{attribute}=", public_send(attribute))
      end
  end

  class CannotWriteDifferentRecord < StandardError
  end

  class CannotWritePersistedRecord < StandardError
  end
end
