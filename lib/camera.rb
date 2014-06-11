# Camera: Pans with the character and provides the main viewport

class Camera
  attr_accessor :x, :y
  attr_reader :type

  def initialize(x, y, type = :stop_at_wall)
    @x = x.to_f
    @y = y.to_f
    @type = type
  end

  #handle converting the location vectors
  def world_to_screen(world_coordinates)
    world_coordinates - self.to_loc
  end
  def screen_to_world(screen_coordinates)
    self.to_loc + screen_coordinates
  end

  #different return modes
  def to_loc
    MyObj::Loc.new(@x, @y)
  end
  def to_a
    [@x, @y]
  end
end
