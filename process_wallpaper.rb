#!/usr/bin/env ruby
# frozen_string_literal: true

require './classes/wallpaper'
require './classes/running_process'

wallpaper = Wallpaper.new
wallpaper.create_wallpaper

process = RunningProcess.new
process.collect_processes
process.shorten_length
process.sort_processes
process.filter_processes
process.normalize_processes(wallpaper.font_size[:max], wallpaper.font_size[:min])
process.randomize_rotation

wallpaper.annotate_words(process.processes)
wallpaper.export_wallpaper
