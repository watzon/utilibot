require "identicon"

class Utilibot < Tourmaline::Client
  help_item "identicon", <<-MARKDOWN
  Generate an identicon using the supplied text.

  `/identicon watzon`
  MARKDOWN

  @[Command(["identicon"])]
  def identicon_command(client, update)
    if message = update.message
      text = update.context["text"].as_s

      if text.strip.empty?
        return message.reply("No text to operate on")
      end

      File.tempfile(suffix: ".png") do |file|
        identicon = Identicon.create(text)
        file.write(identicon.rewind.to_slice)

        message.reply_with_photo(file.rewind)
      end
    end
  end
end
