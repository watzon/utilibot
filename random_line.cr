FILENAME = ARGV[0]
lines = File.read_lines(FILENAME)
puts lines[rand(lines.size - 1)]
