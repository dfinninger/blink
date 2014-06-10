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

require_relative 'zorder'
require_relative 'blinkutils'

require_relative '../objects/enemy'
require_relative '../objects/player'

def media_path(file); File.expand_path "../media/#{file}", File.dirname(__FILE__) end

class GameWindow < Gosu::Window
include BlinkUtils
   def initialize 
      config = YAML.load_file('config/window.yml')
      super config[:width], config[:height], false
      self.caption = "Blink"

      @background_image = Gosu::Image.new(self, media_path("backgrounds/bluewood.jpg"), true)
      log self, "Background Loaded"
      @player = Player.new(self)
      log self, "Player Loaded"
      @player.warp(200,240)
      log self, "Player Warped"
      @enemy = Enemy.new(self)
      log self, "Enemy Loaded"
      @enemy.warp(400,240)
      log self, "Enemy Warped"

      @font = Gosu::Font.new(self, Gosu::default_font_name, 18)
   end

   def collision?(object_1, object_2)
     hitbox_1, hitbox_2 = object_1.hitbox, object_2.hitbox
     common_x = hitbox_1[:x].to_a & hitbox_2[:x].to_a
     common_y = hitbox_1[:y].to_a & hitbox_2[:y].to_a
     common_x.size > 0 && common_y.size > 0
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

      if collision?(@player, @enemy)
        unless @player.recently_hit
          @player.health -= 10
          @player.recently_hit = true
        end
      else
        @player.recently_hit = false
        @player.hit_timer = 0
      end

      if @player.recently_hit
        @player.hit_timer += 1
        @player.hit_timer %= 25
        if @player.hit_timer == 0
          @player.recently_hit
        end
      end
   end

   def draw
      @player.draw
      @enemy.draw
      @background_image.draw(-200,-200,0)
      @font.draw("Player HP: <c=ff0000>#{@player.health}</c>", 10, 10, 1.0, 1.0, 1.0)
   end

   def button_down(id)
      if id == Gosu::KbEscape
         close
      end
   end

   private

   def update_camera
     @camera.x = @player.x
     @camera.y = @player.y
   end
end

