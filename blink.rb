#  
#  Blink - a platformer that should be a bit fun
#
#     Author:     Devon Finninger
#     Init Date:  2014-06-04
#
# Note: This is the main file that should be run to play the game

require 'rubygems'
require 'bundler/setup'
require 'gosu'
require 'yaml'

require_relative 'lib/player'

def media_path(file); File.expand_path "media/#{file}", File.dirname(__FILE__) end

class GameWindow < Gosu::Window
   def initialize
      config = YAML.load_file('config/window.yml')
      super config[:width], config[:height], false
      self.caption = "Blink"

      @background_image = Gosu::Image.new(self, media_path("backgrounds/bluewood.jpg"), true)
      @player = Player.new(self)
      @player.warp(320,240)
   end

   def update
      puts Gosu.fps
      if button_down? Gosu::KbLeft or button_down? Gosu::GpLeft then 
         @player.move_left
      end
      if button_down? Gosu::KbRight or button_down? Gosu::GpRight then
         @player.move_right
      end
      if button_down? Gosu::KbUp or button_down? Gosu::GpButton0
         if @player.can_jump? and not @up_pressed
            @player.jump
         end 
         @up_pressed = true
      else
         @up_pressed = false
      end
      @player.move
   end

   def draw
      @player.draw
      @background_image.draw(-200,-200,0)
   end

   def button_down(id)
      if id == Gosu::KbEscape
         close
      end
   end
end

window = GameWindow.new
window.show

