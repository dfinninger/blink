# An NPC that is part of a cutscene and can be pushed around with an API

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class NPC
  attr_accessor :floor, :ceiling, :left_wall, :right_wall
  attr_reader :loc
  def initialize(window, image, x = 0, y = 0)
    @window = window
    @image = Gosu::Image.new(window, image, false)
    @loc = MyObj::Loc.new(x, y)

    @vel_x = 0
    @vel_y = 0

    @lock_speed_x = false
    @lock_speed_y = false

    @floor = @window.height
    @right_wall = @window.width
    @ceiling = @left_wall = 0
  end

  def update
    @loc.x += @vel_x
    @loc.y += @vel_y
    if @loc.y >= @floor-@image.height
      @loc.y = @floor-@image.height
    end

    # x friction -------------------------------------------------
    unless @lock_speed_x
      @vel_x = 10.0 if @vel_x > 10.0
      @vel_x = -10.0 if @vel_x < -10.0
      @vel_x *= 0.5
      @vel_x = 0 if (@vel_x >= -0.1) and (@vel_x <= 0.1)
    end

    # gravity ----------------------------------------------------
    unless @lock_speed_y or @loc.y == @floor-@image.height
      @vel_y = (@loc.y + @image.height) == @floor ? 0 : @vel_y + 0.6
      @vel_y = 50 if @vel_y > 50
    end
  end

  def draw
    @image.draw(*@loc.to_a, ZOrder::NPC)
  end

  def warp(x, y)
    @loc.x = x
    @loc.y = y
  end

  def left
    @vel_x -= 5
  end

  def right
    @vel_x += 5
  end

  def jump
    @loc.y += 1
    @vel_y -= 15
  end

  def stop
    @vel_x = 0
    @vel_y = 0
  end

  def lock_x(val)
    @lock_speed_x = true
    @vel_x = val
  end
  def unlock_x; @lock_speed_x = false end

  def lock_y(val)
    @lock_speed_y = true
    @vel_y = val
  end
  def unlock_y; @lock_speed_x = false end
end