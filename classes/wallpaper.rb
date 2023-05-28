# frozen_string_literal: true

require 'rmagick'

# Wallpaper class
class Wallpaper
  include Magick
  attr_reader :font_size, :used_space

  def initialize(height = 1080, width = 1920)
    @ws = { height: height, width: width }
    @font_size = { max: 100, min: 30 }
  end

  def create_wallpaper
    @canvas = Image.new(@ws[:width], @ws[:height]) do |options|
      options.background_color = 'white'
    end
    @used_space = []
  end

  def check_collision(cenx, ceny, width, height)
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

  def annotate_words(words)
    words.each do |word|
      text = Draw.new
      text.font_family = 'Delius'
      text.gravity = CenterGravity
      text.pointsize = word[1]
      text.rotation = word[2]

      metrics = text.get_type_metrics(@canvas, word[0])

      x = word[2].zero? ? -@ws[:width] / 2 + metrics.width / 2 : -@ws[:width] / 2 + metrics.height / 2
      y = word[2].zero? ? -@ws[:height] / 2 + metrics.height / 2 : -@ws[:height] / 2 + metrics.width / 2

      collision = if word[2].zero?
                    check_collision(x, y, metrics.width, metrics.height)
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
          while y < @ws[:height] / 2 - metrics.width / 2
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
        @used_space.push([x - metrics.width / 2, y - metrics.height / 2, x + metrics.width / 2, y + metrics.height / 2])
      else
        @used_space.push([x - metrics.height / 2, y - metrics.width / 2, x + metrics.height / 2, y + metrics.width / 2])
      end
    end
  end

  def export_wallpaper
    @canvas.write('output.png')
  end
end
