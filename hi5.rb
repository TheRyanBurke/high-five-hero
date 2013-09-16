#!/usr/bin/ruby

require 'io/wait'
require 'rubygems'
require 'mqtt'

if ARGV.length != 2
  puts "Please start the app with two player initials: ruby hi5.rb rmb jsw"
  exit
end

STATE_START = 0
STATE_GAME = 1
STATE_OVER = 2

STATE_HIGH_FIVING = 1
STATE_NOT_HIGH_FIVING = 0

TIMING_WINDOW = 1.5

FRET_EMPTY = "=="
FRET_HIGH_FIVE = "||"

$game_state = STATE_START
$high_fiving_state = STATE_NOT_HIGH_FIVING
$score = 0
$misses = 0
$combo = 0
$best_combo = 0
$last_high_five_timestamp = 0
$fretboard = ""

$initials = "%s && %s" % ARGV

def char_if_pressed
  begin
    system("stty raw -echo") # turn raw input on
    c = nil
    if $stdin.ready?
      c = $stdin.getc
    end
    c.chr if c
  ensure
    system "stty -raw echo" # turn raw input off
  end
end

def draw_fretboard()
  s = "| "
  $fretboard.each { |fret| s << "%s " % fret }
  s
end

def tui_buffer(console_input)
  s = "HIGH FIVE HERO\n"
  
  # fix nil input
  console_input = console_input || ""

  if console_input == 'q'
    s << "Exiting game..."    
  else  
    case $game_state
    when STATE_START
      s << "Welcome to High Five Hero!\n\n\n"
      s << "HIGH FIVE to begin!\n\n\n"
      s << "INSTRUCTIONS\n\n\n"
      s << "This is a two-player game. Hook up a Makey Makey to your computer"
      s << " with alligator clips on [Space] and Ground. Player One holds the Ground end"
      s << " of one clip and Player Two holds the [Space] end of the other"
      s << " alligator clip. When you see a Guitar Hero style prompt approach"
      s << " the left side of the screen, high five your partner to score it!"
    when STATE_GAME
      # show fret board
      current_fretboard = draw_fretboard()
      5.times { 
        s << current_fretboard + "\n"
      }
      
      # show score
      s << "\nSCORE: %d" % $score

      # show combo
      s << "\nCOMBO: %d" % $combo

      # show number of misses remaining before loss
      s << "\nMISSES: "
      $misses.times { s << "* " } 

      # debug: show high five state
      s << "\n\nHigh Five State: "
      if $high_fiving_state == STATE_HIGH_FIVING
        s << "HIGH FIVE"
      else
        s << "not high fiving :("
      end

    when STATE_OVER
      s << "Final Score: %d!!!!\n\n\n\nHIGH FIVE to reset!" % $score
    else
      s << "ERROR! Unrecognized game state!"
    end  
    
    # debug: show input
    s << "\n\ninput: "
    s << console_input

  end

  s
end

def game_init()
  $high_fiving_state = STATE_NOT_HIGH_FIVING
  $score = 0
  $misses = 3
  $combo = 0
  $best_combo = 0
  $last_high_five_timestamp = 0
  $fretboard = []
  24.times { $fretboard << FRET_EMPTY }
end

def update_game_state(console_input)
  case $game_state
  when STATE_START
    case console_input
    when ' '
      $game_state = STATE_GAME
    else
    end

  when STATE_GAME
    # update high fiving state
    case console_input
    when ' '
      if $high_fiving_state == STATE_HIGH_FIVING
        $combo = 0
      end
      $last_high_five_timestamp = Time.now.to_f
      $high_fiving_state = STATE_HIGH_FIVING
    else
      timestamp = Time.now.to_f
      if (timestamp - $last_high_five_timestamp) > TIMING_WINDOW && $high_fiving_state == STATE_HIGH_FIVING
        $high_fiving_state = STATE_NOT_HIGH_FIVING
        $misses -= 1
      end
    end

    # update fret board
    # one in six chance to push a High Five, no adjacent High Fives
    current_fret = $fretboard.shift()
    if rand(6) == 0 && $fretboard.last != FRET_HIGH_FIVE
      $fretboard.push(FRET_HIGH_FIVE)
    else
      $fretboard.push(FRET_EMPTY)
    end

    # check current fret for miss
    if current_fret == FRET_HIGH_FIVE
      if $high_fiving_state == STATE_NOT_HIGH_FIVING
        $misses -= 1
        $combo = 0
      else
        $combo += 1
        if $combo > $best_combo
          $best_combo = $combo
        end
        $score += $combo * 100
        $high_fiving_state = STATE_NOT_HIGH_FIVING
      end
    end 
      


    # check game over
    if $misses < 1
      $game_state = STATE_OVER
      MQTT::Client.connect(:remote_host => 'q.m2m.io', :keep_alive => 30, :client_id => "hfh%d" % Time.now.to_i) do |c|
        c.publish('public/highfivehero/scores', '{ "score":%d, "maxcombo":%d, "initials":"%s"}' % [$score, $best_combo, $initials])
      end
    end

  when STATE_OVER
    case console_input
    when ' '
      # reset game
      $game_state = STATE_START
    else
    end
  else
    puts "Unrecognized game state!"
  end
end

def game_loop()
  begin
    system "clear"
    c = char_if_pressed

    if $game_state == STATE_START
      game_init()
    end

    update_game_state(c)

    puts (tui_buffer c)

    sleep (1.0/12.0)
  end while (true && c != 'q')
end

game_loop()