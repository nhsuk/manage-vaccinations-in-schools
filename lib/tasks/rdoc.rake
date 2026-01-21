# frozen_string_literal: true

require "rdoc/task"

namespace :rdoc do
  RDoc::Task.new(:generate) do |rdoc|
    rdoc.title = "Mavis Documentation"
    rdoc.main = "README.md"
    rdoc.rdoc_dir = "docs/rdoc"
    rdoc.rdoc_files.include(
      "README.md",
      "docs/*.md",
      "lib/**/*.rb",
      "app/**/*.rb"
    )
  end
end
