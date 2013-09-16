high-five-hero
==============

a guitar-hero style game for 2 players using a [Makey Makey](http://www.makeymakey.com/)

## Requirements

* 2 people
* a [Makey Makey](http://www.makeymakey.com/)
* Ruby 1.8.7+
* rubygems with ('mqtt', 'json') installed
* a valid Internet connection

## How to play

First, hook up your Makey to your computer with alligator clips on the Space and Ground.

Second, open a terminal window and run the main file (first and second parameters are the initials of the two players):

`$ ruby hi5.rb rmb jsw`

Player One holds the end of the Space clip. Player Two holds the end of the Ground clip.

In Guitar Hero fashion, you'll see a fretboard moving icons from right-to-left. When a || icon is about to reach the left end, HIGH FIVE your partner to score it. 

## Leaderboard

To monitor incoming high scores coming in via MQTT and the 2lemetry platform, open another terminal window and run:

`$ ruby leaderboard.rb`

