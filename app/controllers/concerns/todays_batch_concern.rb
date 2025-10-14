# frozen_string_literal: true

module TodaysBatchConcern
  extend ActiveSupport::Concern

  def todays_batch_id(programme:, vaccine_method:, contains_gelatine:)
    if (
         todays_batch =
           session.dig(
             :todays_batch,
             programme.type,
             vaccine_method,
             contains_gelatine.to_s
           )
       )
      if todays_batch[:date] == Date.current.iso8601
        todays_batch[:id].to_i
      else
        unset_todays_batch(programme:, vaccine_method:, contains_gelatine:)
        nil
      end
    end
  end

  def todays_batch=(batch)
    programme_type = batch.programme.type
    vaccine_method = batch.vaccine.method
    contains_gelatine = batch.vaccine.contains_gelatine.to_s

    session[:todays_batch] ||= {}
    session[:todays_batch][programme_type] ||= {}
    session[:todays_batch][programme_type][vaccine_method] ||= {}
    session[:todays_batch][programme_type][vaccine_method][
      contains_gelatine
    ] = { id: batch.id, date: Date.current.iso8601 }
  end

  def unset_todays_batch(programme:, vaccine_method:, contains_gelatine:)
    session.dig(:todays_batch, programme.type, vaccine_method)&.delete(
      contains_gelatine.to_s
    )
  end
end
