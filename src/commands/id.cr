class Utilibot < Tourmaline::Client
  help_item "id", "Return the id of the current chat or the replied to message's user."

  @[Command("id")]
  def id_command(client, update)
    if message = update.message
      if reply_message = message.reply_message
        if from = reply_message.from
          return message.reply("#{from.full_name}: `#{from.id}`", parse_mode: :markdown)
        end
      end

      return message.reply("`#{message.chat.id}`", parse_mode: :markdown)
    end
  end
end
