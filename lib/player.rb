#
#  player.rb - defines the player character
#
#     Author:     Devon Finninger
#     Init Date:  2014-06-04
#

require_relative 'blinkutils'
def media_path(file); File.expand_path "../media/#{file}", File.dirname(__FILE__) end

class Player
include BlinkUtils
   FOOTROOM = 54
   HEADROOM = 20
   SIDEROOM = 33
   WIDTH    = SIDEROOM * 2
   HEIGHT   = FOOTROOM + HEADROOM
   attr_accessor :jumps_left
   def initialize(window)
      log self, "Initializing object..."
      @window = window
      @image = Gosu::Image.new(window, media_path("characters/Character Boy.png"), false)
      log self, "Image loaded"
      @x = @y = @vel_x = @vel_y =  @angle = 0.0
      @jumps_left = 2
      @x_dir = 0
      @flipping = false
      @flip_complete = false
   end

   def warp(x,y)
      @x, @y, = @window.height/2, @window.width/2
   end

   def move_left; @vel_x -= 5.0 end
   def move_right; @vel_x += 5.0 end

   def jump
     @vel_y -= (5 * @jumps_left)
     @x_dir = 0 <=> @vel_x
   end

   def can_jump?
     if @jumps_left >= 1
       return true
     else
       return false
     end
   end

   def move
      @x += @vel_x
      @y += @vel_y
      if @x >= @window.width-SIDEROOM
         @x =  @window.width-SIDEROOM
         @vel_x = 0
      elsif @x <= SIDEROOM
         @x = SIDEROOM
         @vel_x = 0
      end
      if @y >= @window.height-FOOTROOM
         @y =  @window.height-FOOTROOM
         @vel_y = 0
         @jumps_left = 2
         @flip_complete = false
      elsif @y <= HEADROOM
         @y =  HEADROOM
         @vel_y = 0
      end

      log self, "Angle = #{@angle}"

      if @y <= (@window.height-FOOTROOM-50) and @jumps_left == 0 and not @flip_complete
        if @angle <= 360.0 and @angle >= -360.0
          @angle += 14.99*@x_dir
          @flipping = true
        else
          @angle = 0
          @flipping = false
          @flip_complete = true
        end
      else
        @angle = 0
      end

      @vel_x *= 0.5
      if @vel_x >= -0.1 and @vel_x <= 0.1 then @vel_x = 0 end
      @vel_y = @vel_y + 0.3
   end

   def draw
      @image.draw_rot(@x, @y, 1, @angle)
   end
end
