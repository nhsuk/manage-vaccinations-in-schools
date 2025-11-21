# frozen_string_literal: true

module TodaysBatchConcern
  extend ActiveSupport::Concern

  def todays_batch_id(programme:, vaccine_method:)
    if (
         todays_batch =
           session.dig(:todays_batch, programme.type, vaccine_method)
       )
      if todays_batch[:date] == Date.current.iso8601
        todays_batch[:id].to_i
      else
        unset_todays_batch(programme:, vaccine_method:)
        nil
      end
    end
  end

  def todays_batch=(batch)
    session[:todays_batch] ||= {}
    session[:todays_batch][batch.programme_type] ||= {}
    session[:todays_batch][batch.programme_type][batch.vaccine.method] = {
      id: batch.id,
      date: Date.current.iso8601
    }
  end

  def unset_todays_batch(programme:, vaccine_method:)
    session.dig(:todays_batch, programme.type)&.delete(vaccine_method)
  end
end
