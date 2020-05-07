require "json"
require "http/client"

class Utilibot < Tourmaline::Client
  RANDOM_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890".chars

  help_item "random", <<-MARKDOWN
  Provides various random utilitiy functions.

  *Usage:* `/random <command> [args...]`

  *Commands:*
  `number(s) [min] [max] [count]` - Returns `count` random numbers between `min` and `max`. If `max` is not provided, \
  min will be max. `count` defaults to 1.

  `word(s) [count]` - Returns `count` random words. `count` defaults to 1.

  `string [length] [characters]` - Returns a random string of size `length` containing only the characters in the \
  given `characters` string. `length` defaults to 16 and `characters` defaults to base64 compatible characters.

  `line(s) [count]` - Returns `count` random lines from the replied to text file. `count` defaults to 1.

  `picture [width] [height]` - Returns a random picture of size `[width]x[height]` from picsum.photos. `width` and \
  `height` both default to 300.
  MARKDOWN

  @[Command("random")]
  def random_command(client, update)
    message = update.message.not_nil!
    text = update.context["text"].as_s

    parts = text.split(/\s+/).reject(&.empty?)
    if parts.empty?
      return message.reply("No random command provided. Use `/help random` for usage information.")
    end

    command = parts[0].downcase
    params = parts.size > 1 ? parts[1..] : [] of String

    case command
    when "number", "numbers"
      min, max, count = params[0], params[1]?, (params[2]? || 1).to_i
      max, min = min, max unless max
      float = max.includes?('.') || min && min.includes?('.')

      response = String.build do |str|
        count.times do
          if float
            str.puts min && max ? rand(min.to_f..max.to_f) : rand(max.to_f)
          else
            str.puts min && max ? rand(min.to_i..max.to_i) : rand(max.to_i)
          end
        end
      end

      return message.reply(response)
    when "word", "words"
      count = (params[0]? || 1).to_i
      res = HTTP::Client.get("https://random-word-api.herokuapp.com/word?number=#{count}")
      words = Array(String).from_json(res.body)

      response = String.build do |str|
        words.each do |word|
          str.puts word
        end
      end

      return message.reply(response)
    when "string"
      length = (params[0]? || 16).to_i
      characters = params[1]?.try &.chars || RANDOM_CHARS

      response = String.build do |str|
        length.times do
          str << characters.sample(1)[0]
        end
      end

      return message.reply(response)
    when "line", "lines"
      count = (params[0]? || 1).to_i
      if (reply_message = message.reply_message) && (document = reply_message.document)
        file = get_file(document.file_id)
        link = get_file_link(file)
        res = HTTP::Client.get(link.to_s)
        lines = res.body.split('\n')

        response = String.build do |str|
          count.times do
            str.puts lines[rand(lines.size - 1)]
          end
        end

        return message.reply(response)
      else
        return message.reply("Please reply to the text file you want to gets lines from")
      end
    when "picture", "image"
      width = params[0]? || 300
      height = params[1]? || 300
      url = "https://picsum.photos/#{width}/#{height}?rand=#{rand(Int32::MAX)}"
      return message.reply_with_photo(url)
    else
      return message.reply("Unrecognized random command '#{command}'. Use `/help random` for usage information.")
    end
  end
end
