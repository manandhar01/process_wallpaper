# frozen_string_literal: true

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
    # @processes = @processes.take(100)
    puts @processes.length
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
