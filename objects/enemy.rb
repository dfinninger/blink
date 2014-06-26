# player class

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class Enemy
  include BlinkUtils
  FOOTROOM = 54
  HEADROOM = 20

  def initialize(window, level)
    @window = window
    @image = Gosu::Image.new(window, media_path("characters/Enemy Bug.png"), false)
    @level = level
    @loc = MyObj::Loc.new(0, 0)
    @angle = 0.0
    @move_dir = :left
    @vel_y = 0.0
    @x_factor = -1
  end

  def hitbox
    hitbox_x = ((@loc.x - @image.width/2).to_i..(@loc.x + @image.width/2))
    hitbox_y = ((@loc.y - @image.height/2).to_i..(@loc.y + @image.height/2))
    {:x => hitbox_x, :y => hitbox_y}
  end

  def move
    case @move_dir
      when :left
        @x_factor = -1
        if would_fit_left?
          @loc.x -= 2
        else
          @move_dir = :right
        end
      when :right
        @x_factor = 1
        if would_fit_right?
          @loc.x += 2
        else
          @move_dir = :left
        end
      else
        @move_dir = :left
    end

    if on_floor?
      @vel_y = 0
    else
      @vel_y += 2
    end

    @vel_y.to_i.times { @loc.y += 1 unless on_floor? }

    @angle = 5 * Math.sin(Gosu::milliseconds / 133.7)
  end

  def warp(x, y)
    @loc = MyObj::Loc.new(x, y)
  end

  def draw(camera)
    @image.draw_rot(*camera.world_to_screen(@loc).to_a, 1, @angle, 0.5, 0.5, @x_factor, 1, 0xffffffff, :default)
  end

  def would_fit_left?
    ((@loc.y-@image.height/2+5).to_i..(@loc.y+@image.height/2-5).to_i).each do |y|
      if @level.solid?(@loc.x+14,y)
        @on_left_wall = true
        return false
      end
    end
    true
  end

  def would_fit_right?
    ((@loc.y-@image.height/2+5).to_i..(@loc.y+@image.height/2-5).to_i).each do |y|
      if @level.solid?(@loc.x+@image.width-14,y)
        @on_right_wall = true
        return false
      end
    end
    true
  end

  def on_floor?
    ((@loc.x+@image.width/2-15).to_i..(@loc.x+@image.width/2+15).to_i).each do |x|
      if @level.solid?(x,@loc.y+@image.height/2)
        return true
      end
    end
    false
  end
end
