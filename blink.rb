#  
#  Blink - a platformer that should be a bit fun
#
#     Author:     Devon Finninger
#     Init Date:  2014-06-04
#
# Notes: This is the main file that should be run to instantiate the game

require 'rubygems'
require 'bundler/setup'
require 'gosu'

require_relative 'lib/player'

def media_path(file); File.expand_path "media/#{file}", File.dirname(__FILE__) end

class GameWindow < Gosu::Window
   def initialize 
      super 640, 480, false
      self.caption = "Blink"

      @background_image = Gosu::Image.new(self, media_path("backgrounds/bluewood.jpg"), true)
      @player = Player.new(self)
      @player.warp(320,240)
   end

   def update
      if button_down? Gosu::KbLeft or button_down? Gosu::GpLeft then 
         @player.turn_left
      end
      if button_down? Gosu::KbRight or button_down? Gosu::GpRight then
         @player.turn_right
      end
      if button_down? Gosu::KbUp or button_down? Gosu::GpButton0 then
         @player.accelerate
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

