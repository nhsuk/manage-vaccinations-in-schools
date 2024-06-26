# frozen_string_literal: true

module TodaysBatchConcern
  extend ActiveSupport::Concern

  def todays_batch_id
    if session.key?(:todays_batch_id) && session.key?(:todays_batch_date)
      if session[:todays_batch_date] == Time.zone.today.iso8601
        session[:todays_batch_id].to_i
      else
        unset_todays_batch
        nil
      end
    end
  end

  def todays_batch_id=(batch_id)
    session[:todays_batch_id] = batch_id
    session[:todays_batch_date] = Time.zone.today.iso8601
  end

  def unset_todays_batch
    session.delete(:todays_batch_id)
    session.delete(:todays_batch_date)
  end
end
