#!/usr/bin/ruby

require 'io/wait'
require 'rubygems'
require 'mqtt'
require 'json'

Entry = Struct.new(:initials, :score, :combo)

$leaderboard = []

def render_leaderboard(message)
  parsed_message = JSON.parse(message)
  new_entry = Entry.new
  new_entry.initials = parsed_message["initials"]
  new_entry.score = parsed_message["score"]
  new_entry.combo = parsed_message["maxcombo"]
  $leaderboard.push(new_entry)
  $leaderboard.sort! { |x, y| y[:score] <=> x[:score] }
  $leaderboard = $leaderboard.first(10)

  s = "HIGH FIVE HERO LEADERBOARD"
  s << "\n\n\n"
  $leaderboard.each_with_index { |e, index| s << "%d. %d with max combo: %d, by %s\n" % [index+1, e.score, e.combo, e.initials] }

  s
end

MQTT::Client.connect(:remote_host => 'q.m2m.io', :keep_alive => 30, :client_id => "hfh%d" % Time.now.to_i) do |c|
  c.get('public/highfivehero/scores') do |topic,message|
    leaderboard_string = render_leaderboard(message)
    system "clear"
    puts leaderboard_string
  end
end