# frozen_string_literal: true

namespace :data_migration do
  desc "Update HPV health questions."
  task update_hpv_health_questions: :environment do
    ActiveRecord::Base.transaction do
      Programme.hpv.vaccines.find_each do |vaccine|
        vaccine.health_questions.in_order.each(&:destroy!)
        Rake::Task["vaccines:seed"].execute(type: "hpv")
      end
    end
  end
end
