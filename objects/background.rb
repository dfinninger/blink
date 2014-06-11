class Background
  attr_reader :image
  def initialize(window, x, y, image_filename, zorder = ZOrder::Background, type = :tracking)
    @window = window
    @image = Gosu::Image.new(window, "#{image_filename}", true)
    @pos = MyObj::Loc.new(x,y)
    @zorder = zorder
    @type = type
  end

  def draw(camera)
    case @type
      when :static
        @image.draw(*camera.world_to_screen(@pos).to_a, @zorder)
      when :tracking
        @image.draw_rot(@window.width/2, @window.height/2, @zorder, 0.0)
    end

  end

  def to_a
    []
  end
end