require "cadmium_language_detector"

class Utilibot < Tourmaline::Client
  help_item "langdetect", <<-MARKDOWN
  Try to determine the language of a text sample.

  `/langdetect hola, me llamo watzon`
  MARKDOWN

  @[Command(["langdetect"])]
  def langdetect_command(client, update)
    if message = update.message
      text = update.context["text"].as_s
      if reply = message.reply_message
        text = reply.text.to_s
      end

      if text.strip.empty?
        return message.reply("No text to operate on")
      end

      likely = Cadmium::LanguageDetector.new.detect_all(text).to_a
        .select { |_, v| v <= 1.0 && v >= 0.7 }[0, 5]

      response = String.build do |str|
        str << "The most likely languages (based on my training data):\n"
        likely.each_with_index do |(k, v), i|
          str << "`#{k}: #{v}`\n"
        end
      end

      message.reply(response, parse_mode: :markdown)
    end
  end
end
