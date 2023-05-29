# frozen_string_literal: true

# RunningProcess class
class RunningProcess
  attr_reader :processes

  def initialize
    @processes = []
  end

  def collect_processes
    processes = `ps -eo comm,%cpu --sort=-%cpu | tail -n +2`
    # processes = `ps -eo comm,%mem --sort=-%mem | tail -n +2`
    processes.each_line do |line|
      process_name, cpu_usage = line.split(' ')
      @processes.push([process_name, cpu_usage.to_f])
    end
  end

  def filter_processes
    processes = {}
    @processes.each do |p|
      if processes[p[0]]
        processes[p[0]] += p[1]
      else
        processes[p[0]] = p[1]
      end
    end
    @processes = processes.map { |x, y| [x, y] }
    @processes = @processes.take(100)
  end

  def shorten_length
    @processes.map! do |p|
      if p[0].length > 8
        new_name = "#{p[0].slice(0, 7)}+"
        [new_name, p[1]]
      else
        p
      end
    end
  end

  def sort_processes
    @processes.sort_by! { |p| -p[1] }
  end

  def normalize(min, max, processes)
    usage = processes.map { |p| p[1] }
    min_usage = usage.min
    max_usage = usage.max
    normalized_processes = []
    processes.each do |p|
      font_size = (((p[1] - min_usage).to_f / (max_usage - min_usage)) * (max - min) + min).to_i
      normalized_processes.push([p[0], font_size])
    rescue StandardError => e
      normalized_processes.push([p[0], min])
    end
    normalized_processes
  end

  def normalize_processes(max, min)
    normalized_major_processes = normalize((max / 3).to_i, max, @processes.slice(0, 40))
    normalized_inbetween_processes = normalize((max / 5).to_i, (max / 3).to_i, @processes.slice(40, 70))
    normalized_minor_processes = normalize(min, (max / 3).to_i, @processes.slice(70, 100))
    @processes = normalized_major_processes + normalized_inbetween_processes + normalized_minor_processes
    puts @processes.inspect
  end

  def randomize_rotation
    @processes.map! do |p|
      rotation = rand(0..1).zero? ? 0 : -90
      [p[0], p[1], rotation]
    end
  end
end
