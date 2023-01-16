require "forwardable"

class Processor
  extend Forwardable

  def_delegators "ActionController::Base.helpers", :asset_path

  def initialize(erb)
    @erb = erb
  end

  def result
    @erb.result(binding)
  end
end

desc "Process javascript assets through ERB."
task process_assets: :environment do
  javascripts_path = Rails.root.join("app/javascript")
  processed_path = javascripts_path.join("processed")
  javascripts_path
    .glob("*.erb")
    .each do |erb_file|
      erb = ERB.new(File.read(erb_file))
      processed_file = processed_path.join(File.basename(erb_file, ".erb"))

      processor = Processor.new(erb)
      File.write(processed_file, processor.result)
    end
end
