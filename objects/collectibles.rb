# a module that contains collectibles strewn in levels
 module Collectibles
   class Gem
     attr_reader :loc

     def initialize(image, x, y)
       @image = image
       @loc = MyObj::Loc.new(x, y)
     end

     def draw(camera)
       # Draw, slowly rotating
       @image.draw_rot(*camera.world_to_screen(loc).to_a, ZOrder::Terrain, 25 * Math.sin(Gosu::milliseconds / 133.7))
     end
   end
 end