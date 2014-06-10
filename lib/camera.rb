# Camera: Pans with the character and provides the main viewport

class Camera
  attr_accessor :x, :y
  def initialize(x,y)
    @x = x.to_f
    @y = y.to_f
  end

  def world_to_screen(world_coordinates)
  end
end
