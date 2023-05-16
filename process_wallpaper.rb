#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rmagick'

ps_output = `ps -eo comm,%cpu --sort=-%cpu | tail -n +2`

processes = []
ps_output.each_line do |line|
  process_name, cpu_usage = line.split(' ')
  processes.push([process_name, cpu_usage.to_f])
end

def normalize(words)
  normalized_words = []
  frequencies = words.map { |word| word[1] }
  min_frequency = frequencies.min
  max_frequency = frequencies.max
  words.each do |word|
    font_size = (((word[1] - min_frequency).to_f / (max_frequency - min_frequency)) * (122 - 30) + 30).to_i
    normalized_words.push([word[0], font_size])
  end
  normalized_words
end

words = [['this', 50], ['is', 40], ['a', 100], ['something', 190], ['okay', 21]]

normalized_words = normalize(words)
normalized_words.sort_by! { |word| word[1] }.reverse!
puts normalized_words.inspect

normalized_processes = normalize(processes)
normalized_processes.sort_by! { |process| process[1] }.reverse!
puts normalized_processes.inspect

canvas = Magick::Image.new(800, 800) { |options| options.background_color = 'white' }

used_space = []

normalized_processes.each do |word|
  text = Magick::Draw.new
  text.font_family = 'Delius'
  text.pointsize = word[1]
  rotation = rand(0..1).zero? ? 0 : -90
  text.rotation = rotation
  metrics = text.get_type_metrics(canvas, word[0])
  x = rotation.zero? ? rand(0..800 - metrics.width) : rand(metrics.height..800)
  y = rotation.zero? ? rand(0..800 - metrics.height) : rand(metrics.width..800)
  if rotation.zero?
    used_space.push([x, y, x + metrics.width, y + metrics.height])
  else
    used_space.push([y - metrics.width, x - metrics.height, y, x])
  end
  puts word[0]
  puts rotation
  puts x
  puts y
  puts ''

  text.annotate(canvas, 0, 0, x, y, word[0]) { |options| options.fill = 'darkred' }
end

puts used_space.inspect

canvas.write('output.png')

cat = Magick::ImageList.new('output.png')
cat.display
