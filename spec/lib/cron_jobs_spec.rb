# frozen_string_literal: true

require Rails.application.root.join("config/cron_jobs")

describe "Cron jobs" do
  CRON_JOBS.each do |key, config|
    context "for #{key} job" do
      it "references a valid class" do
        expect(Object.const_defined?(config[:class])).to be(true)
      end
    end
  end
end
