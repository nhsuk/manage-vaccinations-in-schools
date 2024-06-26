# frozen_string_literal: true

require "rake"
require "zlib"

Rake::Task["assets:precompile"].enhance do
  assembly = Rails.application.assets
  output_path = assembly.config.output_path

  assembly.load_path.assets.each do |asset|
    asset_path = output_path.join(asset.digested_path)
    compressed_path = output_path.join("#{asset.digested_path}.gz")

    next if compressed_path.exist?
    Propshaft.logger.info "Compressing #{asset.digested_path}"

    Zlib::GzipWriter.open(compressed_path, Zlib::BEST_COMPRESSION) do |gz|
      gz.mtime = File.mtime(asset_path)
      gz.orig_name = asset_path.to_s
      gz.write File.binread(asset_path)
    end
  end
end if Rake::Task.task_defined?("assets:precompile")
