# frozen_string_literal: true

module ServicePattern
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval { private_class_method(:new) }
  end

  def call
    raise(NotImplementedError("#call must be implemented"))
  end

  module ClassMethods
    def call(...)
      new(...).call
    end
  end
end
