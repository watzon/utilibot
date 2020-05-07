class Utilibot < Tourmaline::Client
  HELP_MESSAGE = <<-MARKDOWN
  Utilibot is a simple collection of useful utility functions. For each listed command below \
  use `/help command` to get more specific usage information. For instance `/help random`.
  MARKDOWN

  @[Command("help")]
  def help_command(client, update)
    message = update.message.not_nil!
    command = update.context["text"].as_s.strip.downcase
    if command.empty?
      commands = HELP_ITEMS.keys.map { |k| "`/#{k}`" }.join("\n")
      content = HELP_MESSAGE + "\n\n" + commands
      message.reply(content, parse_mode: :markdown)
    elsif help_text = HELP_ITEMS[command]?
      message.reply(help_text, parse_mode: :markdown)
    else
      message.reply("Unrecognized command `#{command}`", parse_mode: :markdown)
    end
  end
end
