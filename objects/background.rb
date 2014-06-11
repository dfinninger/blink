class Background
  attr_reader :image
  def initialize(window, x, y, image_filename, zorder)
    @image = Gosu::Image.new(window, "#{image_filename}", true)
    @pos = MyObj::Loc.new(x,y)
    @zorder = zorder
  end

  def draw(camera)
    @image.draw(*camera.world_to_screen(@pos).to_a, @zorder)
  end

  def to_a
    []
  end
end