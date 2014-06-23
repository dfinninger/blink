class Background
  attr_reader :image
  def initialize(window, x, y, image_filename, zorder = ZOrder::Background, type = :tracking)
    @window = window
    @image = Gosu::Image.new(window, "#{image_filename}", true)
    @second_image = Gosu::Image.new(window, "#{image_filename}", true)
    @pos = type == :tracking ? MyObj::Loc.new(x,0) : MyObj::Loc.new(x,y)
    @second_pos = MyObj::Loc.new(x,1080)
    @zorder = zorder
    @type = type
  end

  def draw(camera)
    case @type
      when :static
        @image.draw(*camera.world_to_screen(@pos).to_a, @zorder)
      when :tracking
        @image.draw_rot(@window.width/2, @window.height/2, @zorder, 0.0)
      when :falling
        @image.draw(@pos.x, @pos.y, @zorder)
        @second_image.draw(@second_pos.x, @second_pos.y, @zorder)
    end
  end

  def update
    if @type == :falling
      @pos.y -= 1
      @second_pos.y -= 1
      if @pos.y == -1080
        @pos.y = 1080
      end
      if @second_pos.y == -1080
        @second_pos.y = 1080
      end
    end
  end

  def to_a
    []
  end
end