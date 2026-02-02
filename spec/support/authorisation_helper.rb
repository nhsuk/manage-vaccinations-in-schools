# frozen_string_literal: true

module AuthorisationHelper
  def stub_authorization(
    allowed:,
    klass: ApplicationPolicy,
    methods: %i[create? new? edit?]
  )
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Pundit::Authorization).to receive(:policy).and_return(
      instance_double(klass, methods.index_with { allowed })
    )
    # rubocop:enable RSpec/AnyInstance
  end
end
