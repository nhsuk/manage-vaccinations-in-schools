# frozen_string_literal: true

module AuthorisationHelper
  def stub_authorization(allowed:)
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Pundit::Authorization).to receive(:policy).and_return(
      instance_double(
        ApplicationPolicy,
        create?: allowed,
        new?: allowed,
        edit?: allowed
      )
    )
    # rubocop:enable RSpec/AnyInstance
  end
end
