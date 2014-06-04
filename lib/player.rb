#
#  player.rb - defines the player character
#
#     Author:     Devon Finninger
#     Init Date:  2014-06-04
#

def media_path(file); File.expand_path "../media/#{file}", File.dirname(__FILE__) end

class Player
   FOOTROOM = 54
   HEADROOM = 20
   def initialize(window)
      @window = window
      @image = Gosu::Image.new(window, media_path("characters/Character Boy.png"), false)
      @x = @y = @vel_x = @vel_y =  @angle = 0.0
   end

   def warp(x,y)
      @x, @y, = x, y
   end

   def move_left; @vel_x -= 5.0 end
   def move_right; @vel_x += 5.0 end

   def jump; @vel_y -= 10 end

   def can_jump?
     if @y == @window.height-FOOTROOM
        return true
     else
        return false
     end
   end

   def move
      @x += @vel_x
      @y += @vel_y
      @x %= @window.width
      if @y >= (@window.height-FOOTROOM)
         @y =  (@window.height-FOOTROOM)
         @vel_y = 0
      elsif @y <= HEADROOM
         @y =  HEADROOM
         @vel_y = 0
      end

      @vel_x *= 0.5
      @vel_y = @vel_y + 0.3
   end

   def draw
      @image.draw_rot(@x, @y, 1, @angle)
   end
end
