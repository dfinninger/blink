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
require_relative 'lib/enemy'
require_relative 'lib/blinkutils'

def media_path(file); File.expand_path "media/#{file}", File.dirname(__FILE__) end

class GameWindow < Gosu::Window
include BlinkUtils
   def initialize 
      super 640, 480, false
      self.caption = "Blink"

      @background_image = Gosu::Image.new(self, media_path("backgrounds/bluewood.jpg"), true)
      log self, "Background Loaded"
      @player = Player.new(self)
      log self, "Player Loaded"
      @player.warp(320,240)
      log self, "Player Warped"
      @enemy = Enemy.new(self)
      log self, "Enemy Loaded"
      @enemy.warp(320,240)
      log self, "Enemy Warped"
   end

   def update
      #player
      if button_down? Gosu::KbLeft or button_down? Gosu::GpLeft then 
         @player.move_left
      end
      if button_down? Gosu::KbRight or button_down? Gosu::GpRight then
         @player.move_right
      end
      if button_down? Gosu::KbUp or button_down? Gosu::GpButton0
         if @player.can_jump? and not @player_up_pressed
            @player.jump
            @player.jumps_left -= 1
            log self, "player jumped"
         end 
         @player_up_pressed = true
      else
         @player_up_pressed = false
      end
      @player.move
      #enemy
      if button_down? Gosu::KbA
         @enemy.move_left
      end
      if button_down? Gosu::KbD
         @enemy.move_right
      end
      if button_down? Gosu::KbW
         if @enemy.can_jump? and not @enemy_up_pressed
            @enemy.jump
            log self, "enemy jumped"
         end 
         @enemy_up_pressed = true
      else
         @enemy_up_pressed = false
      end
      @enemy.move
   end

   def draw
      @player.draw
      @enemy.draw
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

