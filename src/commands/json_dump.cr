class Utilibot < Tourmaline::Client
  help_item "jsondump", <<-MARKDOWN
  Returns a message formatted as JSON. If you responded to a message with this command the \
  message will be the one you responded to, otherwise it will be the current message.
  MARKDOWN

  @[Command("jsondump")]
  def jsondump_command(client, update)
    if message = update.message
      if reply_message = message.reply_message
        json = reply_message.to_pretty_json
      else
        json = message.to_pretty_json
      end

      return message.reply("```\n#{json}\n```", parse_mode: :markdown)
    end
  end
end
