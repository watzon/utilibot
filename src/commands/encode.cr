require "base64"
require "rot26"
require "uri"
require "mime"

class Utilibot < Tourmaline::Client
  help_item "encode", <<-MARKDOWN
  Encode a string using one of the available commands.

  - `base64` for base64 encoding
  - `rot(n)` for rotational encoding, for example `rot32`
  - `uri` for uri encoding
  - `binary` for binary encodind
  - `hex` for hex encodind
  - `data` for encoding a document to a data URI
  MARKDOWN

  help_item "decode", <<-MARKDOWN
  Decode a string using one of the available commands.

  - `base64` for base64 decoding
  - `rot(n)` for rotational decoding, for example `rot32`
  - `uri` for uri decoding
  - `binary` for binary decoding
  - `hex` for hex decoding
  - `data` for decoding a document from a data URI
  MARKDOWN

  @[Command(["encode", "decode"])]
  def encode_command(client, update)
    if message = update.message
      encode = update.context["command"].as_s == "encode"
      text = update.context["text"].as_s

      parts = text.split(/\s+/, 2)
      command = parts[0].downcase

      case command
      when "base64"
        response = encode ? Base64.encode(parts[1]) : String.new(Base64.decode(parts[1]))
        return message.reply(response)
      when /rot(\d+)/
        amount = command.match(/rot(\d+)/).not_nil![1].to_i
        response = encode ? ROT26.encrypt_any(parts[1], amount) : ROT26.decrypt_any(parts[1], amount)
        return message.reply(response)
      when "url", "uri"
        response = encode ? URI.encode(parts[1]) : URI.decode(parts[1])
        return message.reply(response)
      when "binary"
        if encode
          bytes = parts[1].bytes
          response = String.build do |str|
            bytes.each do |byte|
              str << byte.to_s(2).rjust(8, '0')
              str << " "
            end
          end
        else
          str = parts[1].gsub(/\s+/, "")
          io = IO::Memory.new(parts[1].size // 8)
          str.chars.in_groups_of(8).each do |chunk|
            chunk = chunk.compact
            io.write_byte(chunk.join.to_u8(2))
          end
          response = io.rewind.gets_to_end
        end
        return message.reply(response)
      when "hex"
        begin
          response = encode ? parts[1].to_slice.hexstring : String.new(parts[1].hexbytes)
          return message.reply(response)
        rescue
          return message.reply("Improperly formatted string.")
        end
      when "data"
        if encode
          response = String.build do |str|
            str << "data:"
            if reply = message.reply_message
              if doc = reply.document
                file = get_file(doc.file_id)
                link = get_file_link(file)

                response = HTTP::Client.get(link.not_nil!)
                data = Base64.encode(response.body)

                if mime = doc.mime_type
                  str << mime << ";"
                end

                str << "base64,"
                str << data
              elsif reply.photo.size > 0
                photo = reply.photo[0]
                file = get_file(photo.file_id)
                link = get_file_link(file)

                response = HTTP::Client.get(link.not_nil!)
                data = Base64.encode(response.body)

                str << "image/webp;base64,"
                str << data
              elsif sticker = reply.sticker
                puts "sticker"
                file = get_file(sticker.file_id)
                link = get_file_link(file)

                puts link
                response = HTTP::Client.get(link.not_nil!)
                pp response
                data = Base64.encode(response.body)

                if sticker.animated?
                  str << "application/x-gzip;"
                else
                  str << "image/png;"
                end

                str << "base64,"
                str << data
              elsif (text = reply.text) || (text = parts[1]?)
                str << "text/plain;charset=UTF-8,"
                str << text
              end
            end
          end

          if response.size >= 4096
            tmp_file = File.tempfile(suffix: ".txt")
            tmp_file.write(response.to_slice)

            message.reply_with_document(tmp_file.rewind)
            return tmp_file.delete
          else
            return message.reply(response)
          end
        else # decode
          if data = parts[1]?
            return decode_data(message, data)
          elsif (reply = message.reply_message) && (doc = reply.document)
            file = get_file(doc.file_id)
            link = get_file_link(file)

            response = HTTP::Client.get(link.not_nil!)
            data = response.body

            return decode_data(message, data)
          end
        end
      else
        return message.reply("Unrecognized #{encode ? "encode" : "decode"} command '#{command}'. Use `/help #{encode ? "encode" : "decode"}` for usage information.")
      end
    end
  end

  def decode_data(message, data)
    unless data.starts_with?("data:")
      return message.reply("Invalid data URI")
    end

    _, rest = data.split(':', 2)
    meta, data = rest.split(',', 2)
    media_types = meta.split(';')

    if media_types.includes?("base64")
      data = Base64.decode(data.gsub(/\s+/, ""))
    end

    exts = media_types.reduce([] of Array(String)) { |a, t| a << MIME.extensions(t).to_a }
    exts = exts.flatten.compact

    if ext = exts[0]?
      tmp_file = File.tempfile(suffix: ext)
      tmp_file.write(data.to_slice)

      message.reply_with_document(tmp_file.rewind)
      return tmp_file.delete
    else
      if data.size >= 4096
        tmp_file = File.tempfile(suffix: ".txt")
        tmp_file.write(data.to_slice)

        message.reply_with_document(tmp_file.rewind)
        return tmp_file.delete
      else
        return message.reply(String.new(data.to_slice))
      end
    end
  end
end
