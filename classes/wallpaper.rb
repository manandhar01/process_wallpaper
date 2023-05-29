# frozen_string_literal: true

require 'rmagick'

# Wallpaper class
class Wallpaper
  include Magick
  attr_reader :font_size, :used_space

  def initialize(height = 1080, width = 1920)
    @ws = { height: height, width: width }
    @font_size = { max: 250, min: 30 }
    @colors = ['#FFFFFF', '#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF', '#FFA500', '#008000',
               '#800080']
  end

  def create_wallpaper
    @canvas = Image.new(@ws[:width], @ws[:height]) do |options|
      options.background_color = 'black'
    end
    @buffer_canvas = Image.new(@ws[:width], @ws[:height]) do |options|
      options.background_color = 'white'
    end
    # @used_space = []
  end

  def check_collision
    overlapped = false
    if @current_rotation.zero?
      x_start = (@x - @metrics.width / 2) + @ws[:width] / 2
      x_end = (@x + @metrics.width / 2) + @ws[:width] / 2
      y_start = (@y - @metrics.height / 2) + @ws[:height] / 2
      y_end = (@y + @metrics.height / 2) + @ws[:height] / 2
    else
      x_start = (@x - @metrics.height / 2) + @ws[:width] / 2
      x_end = (@x + @metrics.height / 2) + @ws[:width] / 2
      y_start = (@y - @metrics.width / 2) + @ws[:height] / 2
      y_end = (@y + @metrics.width / 2) + @ws[:height] / 2
    end

    # puts "::: #{x_start}, #{y_start}, #{x_end}, #{y_end}"

    cropped_buffer_canvas = @buffer_canvas.crop(x_start, y_start, x_end - x_start, y_end - y_start)
    # cropped_buffer_canvas = @buffer_canvas.crop(0, 0, 500, 500)

    crop_width = cropped_buffer_canvas.columns
    crop_height = cropped_buffer_canvas.rows

    # puts "::: #{@current_word}, #{crop_width}, #{crop_height}"
    @text.annotate(cropped_buffer_canvas, 0, 0, @x, @y, @current_word) { |options| options.fill = 'red' }

    # cropped_buffer_canvas.write("#{@current_word}.png")

    crop_height.times do |y|
      crop_width.times do |x|
        pixel = cropped_buffer_canvas.pixel_color(x, y)
        red = pixel.red
        green = pixel.green
        blue = pixel.blue
        next if green == blue || red == blue

        overlapped = true
      end
      break if overlapped
    end
    overlapped

    # @used_space.each do |space|
    #   if (x_start < space[2]) && (x_end > space[0]) && (y_start < space[3]) && (y_end > space[1])
    #     overlapped = true
    #     break
    #   end
    # end
  end

  def make_text
    @text = Draw.new
    # @text.font_family = 'Delius'
    @text.gravity = CenterGravity
  end

  def annotate_words(words)
    words.each do |word|
      make_text
      # text = Draw.new
      # text.font_family = 'Delius'
      # text.gravity = CenterGravity
      @text.pointsize = word[1]
      @text.rotation = word[2]
      @current_rotation = word[2]
      @current_word = word[0]

      @metrics = @text.get_type_metrics(@canvas, word[0])

      @x = word[2].zero? ? -@ws[:width] / 2 + @metrics.width / 2 : -@ws[:width] / 2 + @metrics.height / 2
      @y = word[2].zero? ? -@ws[:height] / 2 + @metrics.height / 2 : -@ws[:height] / 2 + @metrics.width / 2

      collision = check_collision

      if collision
        if word[2].zero?
          while @y < @ws[:height] / 2 - @metrics.height / 2
            collision = check_collision
            if collision
              @x += @metrics.width / 2
              if @x > @ws[:width] / 2 - @metrics.width / 2
                @x = -@ws[:width] / 2 + @metrics.width / 2
                @y += @metrics.height / 2
              end
            else
              @text.annotate(@canvas, 0, 0, @x, @y, word[0]) { |options| options.fill = @colors[rand(10)] }
              @text.annotate(@buffer_canvas, 0, 0, @x, @y, word[0]) { |options| options.fill = 'green' }
              break
            end
          end
        else
          while @y < @ws[:height] / 2 - @metrics.width / 2
            collision = check_collision
            if collision
              @x += @metrics.height / 2
              if @x > @ws[:width] / 2 - @metrics.height / 2
                @x = -@ws[:width] / 2 + @metrics.height / 2
                @y += @metrics.width / 2
              end
            else
              @text.annotate(@canvas, 0, 0, @x, @y, word[0]) { |options| options.fill = @colors[rand(10)] }
              @text.annotate(@buffer_canvas, 0, 0, @x, @y, word[0]) { |options| options.fill = 'green' }
              break
            end
          end
        end
      else
        @text.annotate(@canvas, 0, 0, @x, @y, word[0]) { |options| options.fill = @colors[rand(10)] }
        @text.annotate(@buffer_canvas, 0, 0, @x, @y, word[0]) { |options| options.fill = 'green' }
      end

      # if word[2].zero?
      #   @used_space.push([x - metrics.width / 2, y - metrics.height / 2, x + metrics.width / 2, y + metrics.height / 2])
      # else
      #   @used_space.push([x - metrics.height / 2, y - metrics.width / 2, x + metrics.height / 2, y + metrics.width / 2])
      # end
    end
  end

  def export_wallpaper
    @canvas.write('output.png')
  end
end
