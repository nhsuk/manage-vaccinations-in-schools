# frozen_string_literal: true

require "readline"

module TaskHelpers
  def prompt_user_for(prompt, required: false)
    response = nil
    loop do
      response = Readline.readline "#{prompt} ", true
      if required && response.blank?
        puts "#{prompt} cannot be blank"
      else
        break
      end
    end
    response
  end
end
