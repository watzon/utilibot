require "tourmaline"
require "./utils"

class Utilibot < Tourmaline::Client
  HELP_ITEMS = {} of String => String

  macro help_item(command, help_text)
    HELP_ITEMS[{{ command }}.to_s] = {{ help_text }}
  end
end

require "./commands/*"

bot = Utilibot.new(ENV["API_KEY"])
bot.poll
