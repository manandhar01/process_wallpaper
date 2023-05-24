#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rmagick'

# Wallpaper class
class Wallpaper
  include Magick
  attr_reader :font_size

  def initialize(height = 1080, width = 1920)
    @ws = { height: height, width: width }
    @font_size = { max: 150, min: 20 }
  end

  def create_wallpaper
    @canvas = Image.new(@ws[:width], @ws[:height]) do |options|
      options.background_color = 'white'
    end
    @used_space = []
  end

  def check_collision(cenx, ceny, height, width)
    x_start = cenx - width / 2
    x_end = cenx + width / 2
    y_start = ceny - height / 2
    y_end = ceny + height / 2
    overlapped = false

    @used_space.each do |space|
      if (x_start < space[2]) && (x_end > space[0]) && (y_start < space[3]) && (y_end > space[1])
        overlapped = true
        break
      end
    end
    overlapped
  end

  # def make_text(word)
  #   text = Draw.new
  #   text.font_family = 'Delius'
  #   text.gravity = CenterGravity
  #   text.pointsize = word[1]
  #   text.rotation = word[2]
  #   text
  # end

  def annotate_words(words)
    words.each do |word|
      puts @used_space.inspect
      text = Draw.new
      text.font_family = 'Delius'
      text.gravity = CenterGravity
      text.pointsize = word[1]
      text.rotation = word[2]

      metrics = text.get_type_metrics(@canvas, word[0])

      x = word[2].zero? ? -@ws[:width] / 2 + metrics.width / 2 : -@ws[:width] / 2 + metrics.height / 2
      y = word[2].zero? ? -@ws[:height] / 2 + metrics.height / 2 : -@ws[:height] + metrics.width / 2

      collision = if word[2].zero?
                    check_collision(x, y, metrics.width,
                                    metrics.height)
                  else
                    check_collision(x, y, metrics.height, metrics.width)
                  end

      if collision
        if word[2].zero?
          while y < @ws[:height] / 2 - metrics.height / 2
            collision = check_collision(x, y, metrics.width, metrics.height)
            if collision
              x += 1
              if x > @ws[:width] / 2 - metrics.width / 2
                x = -@ws[:width] / 2 + metrics.width / 2
                y += 1
              end
            else
              text.annotate(@canvas, 0, 0, x, y, word[0]) { |options| options.fill = 'darkgreen' }
              break
            end
          end
        else
          while y < @ws[:width] / 2 - metrics.width / 2
            collision = check_collision(x, y, metrics.height, metrics.width)
            if collision
              x += 1
              if x > @ws[:width] / 2 - metrics.height / 2
                x = -@ws[:width] / 2 + metrics.height / 2
                y += 1
              end
            else
              text.annotate(@canvas, 0, 0, x, y, word[0]) { |options| options.fill = 'darkblue' }
              break
            end
          end
        end
      else
        text.annotate(@canvas, 0, 0, x, y, word[0]) { |options| options.fill = 'darkred' }
      end

      if word[2].zero?
        @used_space.push([x - metrics.width / 2, y - metrics.height / 2, x + metrics.width / 2,
                          y + metrics.height / 2])
      else
        @used_space.push([x - metrics.height / 2, y - metrics.width / 2, x + metrics.height / 2,
                          y + metrics.width / 2])
      end
    end
  end

  def export_wallpaper
    @canvas.write('output.png')
  end
end

# RunningProcess class
class RunningProcess
  attr_reader :processes

  def initialize
    @processes = []
  end

  def collect_processes
    processes = `ps -eo comm,%cpu --sort=-%cpu | tail -n +2`
    processes.each_line do |line|
      process_name, cpu_usage = line.split(' ')
      @processes.push([process_name, cpu_usage.to_f])
    end
  end

  def filter_processes
    @processes = @processes.take(10)
  end

  def normalize_processes(max, min)
    memory_usage = @processes.map { |process| process[1] }
    min_usage = memory_usage.min
    max_usage = memory_usage.max
    @processes.map! do |p|
      font_size = (((p[1] - min_usage).to_f / (max_usage - min_usage)) * (max - min) + min).to_i
      [p[0], font_size]
    end
  end

  def randomize_rotation
    @processes.map! do |p|
      rotation = rand(0..1).zero? ? 0 : -90
      [p[0], p[1], rotation]
    end
  end
end

wallpaper = Wallpaper.new
wallpaper.create_wallpaper

process = RunningProcess.new
process.collect_processes
process.filter_processes
process.normalize_processes(wallpaper.font_size[:max], wallpaper.font_size[:min])
process.randomize_rotation

wallpaper.annotate_words(process.processes)
wallpaper.export_wallpaper

puts process.processes.inspect

# ps_output = `ps -eo comm,%cpu --sort=-%cpu | tail -n +2`

# processes = []
# ps_output.each_line do |line|
#   process_name, cpu_usage = line.split(' ')
#   processes.push([process_name, cpu_usage.to_f])
# end

# def normalize(words)
#   normalized_words = []
#   frequencies = words.map { |word| word[1] }
#   min_frequency = frequencies.min
#   max_frequency = frequencies.max
#   words.each do |word|
#     font_size = (((word[1] - min_frequency).to_f / (max_frequency - min_frequency)) * (122 - 30) + 30).to_i
#     normalized_words.push([word[0], font_size])
#   end
#   normalized_words
# end

# def check_collision(cenx, ceny, width, height, used_space)
#   x_start = cenx - width / 2
#   x_end = cenx + width / 2
#   y_start = ceny - height / 2
#   y_end = ceny + height / 2
#   overlapped = false

#   used_space.each do |space|
#     if (x_start < space[2]) && (x_end > space[0]) && (y_start < space[3]) && (y_end > space[1])
#       overlapped = true
#       break
#     end
#   end
#   overlapped
# end

# words = [['this', 50], ['is', 40], ['a', 100], ['something', 190], ['okay', 21]]

# normalized_words = normalize(words)
# normalized_words.sort_by! { |word| word[1] }.reverse!
# puts normalized_words.inspect

# normalized_processes = normalize(processes)
# normalized_processes.sort_by! { |process| process[1] }.reverse!
# normalized_processes = normalized_processes.take(75)
# puts normalized_processes.inspect

# canvas = Magick::Image.new(800, 800) { |options| options.background_color = 'white' }

# used_space = []

# normalized_processes.each do |word|
#   text = Magick::Draw.new
#   text.font_family = 'Delius'
#   text.gravity = Magick::CenterGravity
#   text.pointsize = word[1]
#   rotation = rand(0..1).zero? ? 0 : -90
#   text.rotation = rotation
#   metrics = text.get_type_metrics(canvas, word[0])

#   x = rotation.zero? ? -400 + metrics.width / 2 : -400 + metrics.height / 2
#   y = rotation.zero? ? -400 + metrics.height / 2 : -400 + metrics.width / 2

#   # x = if rotation.zero?
#   #       rand((-400 + metrics.width / 2)..(400 - metrics.width / 2))
#   #     else
#   #       rand((-400 + metrics.height / 2)..(400 - metrics.height / 2))
#   #     end
#   # y = if rotation.zero?
#   #       rand((-400 + metrics.height / 2)..(400 - metrics.height / 2))
#   #     else
#   #       rand((-400 + metrics.width / 2)..(400 - metrics.width / 2))
#   #     end
#   collision = if rotation.zero?
#                 check_collision(x, y, metrics.width, metrics.height, used_space)
#               else
#                 check_collision(x, y, metrics.height, metrics.width, used_space)
#               end

#   puts word[0]
#   puts rotation
#   puts x
#   puts y
#   puts collision
#   puts used_space.inspect
#   puts ''

#   if collision
#     # x = rotation.zero? ? -400 + metrics.width / 2 : -400 + metrics.height / 2
#     # y = rotation.zero? ? -400 + metrics.height / 2 : -400 + metrics.width / 2

#     if rotation.zero?
#       while y < 400 - metrics.height / 2
#         collision = check_collision(x, y, metrics.width, metrics.height, used_space)
#         if collision
#           x += 1
#           if x > 400 - metrics.width / 2
#             x = -400 + metrics.width / 2
#             y += 1
#           end
#         else
#           text.annotate(canvas, 0, 0, x, y, word[0]) { |options| options.fill = 'darkgreen' }
#           puts 'breaking'
#           break
#         end
#       end
#     else
#       while y < 400 - metrics.width / 2
#         collision = check_collision(x, y, metrics.height, metrics.width, used_space)
#         if collision
#           x += 1
#           if x > 400 - metrics.height / 2
#             x = -400 + metrics.height / 2
#             y += 1
#           end
#         else
#           text.annotate(canvas, 0, 0, x, y, word[0]) { |options| options.fill = 'darkblue' }
#           puts 'breaking'
#           break
#         end
#       end
#     end
#   else
#     text.annotate(canvas, 0, 0, x, y, word[0]) { |options| options.fill = 'darkred' }
#   end

#   if rotation.zero?
#     used_space.push([x - metrics.width / 2, y - metrics.height / 2, x + metrics.width / 2, y + metrics.height / 2])
#   else
#     used_space.push([x - metrics.height / 2, y - metrics.width / 2, x + metrics.height / 2, y + metrics.width / 2])
#   end
# end

# canvas.write('output.png')

# cat = Magick::ImageList.new('output.png')
# cat.display
