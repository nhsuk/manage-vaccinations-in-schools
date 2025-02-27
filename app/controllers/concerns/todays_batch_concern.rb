# frozen_string_literal: true

module TodaysBatchConcern
  extend ActiveSupport::Concern

  def todays_batch_id(programme:)
    if (todays_batch = session.dig(:todays_batch, programme.type))
      if todays_batch[:date] == Date.current.iso8601
        todays_batch[:id].to_i
      else
        unset_todays_batch(programme:)
        nil
      end
    end
  end

  def todays_batch=(batch)
    session[:todays_batch] ||= {}
    session[:todays_batch][batch.programme.type] = {
      id: batch.id,
      date: Date.current.iso8601
    }
  end

  def unset_todays_batch(programme:)
    session[:todays_batch]&.delete(programme.type)
  end
end
