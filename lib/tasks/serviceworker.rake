# frozen_string_literal: true

namespace :serviceworker do
  desc "Precompile serviceworker JS"
  # Copy how the assets:precompile task depends on yarn being installed.
  task precompile: %w[yarn:install] do
    sh "yarn build:serviceworker"
  end
end

# Note this invokes serviceworker:precompile after assets:precompile is run.
Rake::Task["assets:precompile"].enhance do
  Rake::Task["serviceworker:precompile"].invoke
end
