#!/usr/bin/env ruby

require 'timers'
require 'srt'

def parse_timestamp(timestamp)
  parts = timestamp.split(":")
  offset = 0
  parts.reverse.each_with_index do |part,index|
    offset += (60 ** index) * Integer(part)
  end
  offset
end

def normalize_offset(offset)
  offset ||= 0

  case offset
  when Integer, Float
    offset
  when String
    parse_timestamp(offset)
  else
    raise "Unknown offset: #{offset.inspect}"
  end
end

path = ARGV.shift || raise("Provide the path to the .srt file")
offset = ARGV.shift
offset = normalize_offset(offset)
fudge = ARGV.shift || 2
fudge = Float(fudge)

contents = File.read(path, mode: "r", encoding: "ISO-8859-1")
contents.encode!("UTF-8")
srt = SRT::File.parse(contents)

puts "reading from path #{path.inspect}"
puts "starting at offset #{offset.inspect}"

timers = Timers.new
visible = Set.new
srt.lines.each do |line|
  timers.after(line.start_time - offset - fudge) do
    visible.add(line)
  end
  timers.after(line.end_time - offset + fudge) do
    visible.delete(line)
  end
end

loop do
  timers.wait

  puts "\e[H\e[2J"

  visible.each do |line|
    puts line.text
  end
end
