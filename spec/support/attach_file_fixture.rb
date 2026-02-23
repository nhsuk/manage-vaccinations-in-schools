# frozen_string_literal: true

module AttachFileFixture
  def attach_file_fixture(selector, path)
    attach_file(selector, file_fixture(path))
  end
end

RSpec.configure { |config| config.include AttachFileFixture }
