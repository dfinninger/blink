# this file defines platforms that the player can interact with

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class Platform
  attr_reader :top, :left, :right
  def initialize(window, x, y, image_name)
    @loc = MyObj::Loc.new(x, y)
    @image = Gosu::Image.new(window, media_path("blocks/#{image_name}"), false)
    @angle = 0.0
    @top = @loc.y.to_i
    @right = (@loc.x + @image.width/2).to_i
    @left = (@loc.x - @image.width/2).to_i
  end

  def hitbox
    hitbox_x = ((@loc.x - @image.width/2).to_i..(@loc.x + @image.width/2).to_i)
    hitbox_y = ((@loc.y).to_i..(@loc.y + @image.height/2).to_i)
    {:x => hitbox_x, :y => hitbox_y}
  end

  def draw(camera)
    @image.draw_rot(*camera.world_to_screen(@loc).to_a, ZOrder::Terrain, @angle)
  end
end