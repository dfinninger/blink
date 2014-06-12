#
#  player.rb - defines the player character
#
#     Author:     Devon Finninger
#     Init Date:  2014-06-04
#

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class Player
  include BlinkUtils
  FOOTROOM = 54
  HEADROOM = 20
  SIDEROOM = 33
  WIDTH = SIDEROOM * 2
  HEIGHT = FOOTROOM + HEADROOM
  GRAVITY = 0.4
  SPEED = 7.0
  MAX_PERCENT = 100

  attr_accessor :loc, :health, :base_health, :recently_hit, :on_left_wall,
                :on_right_wall, :off_ground, :blink_charge, :config
  attr_reader :foot, :left, :right

  def initialize(window)
    # load config ---------------------------------------------------------------------
    @config = YAML.load_file('config/player.yml')
      log self, "Initializing object..."  if @config[:logging_enabled]

    # init window for player ----------------------------------------------------------
    @window = window
      log self, "Player knows about window: #{@window}"  if @config[:logging_enabled]
    @level = @window.level
    log self, "Player knows about level: #{@level}"  if @config[:logging_enabled]

    # load resources ------------------------------------------------------------------
    @image = Gosu::Image.new(window, media_path("characters/Character Boy.png"), false)
      log self, "Player Image (#{@image}) loaded"  if @config[:logging_enabled]

    # normalize angles and locations --------------------------------------------------
    @vel_x = @vel_y = @angle = 0.0
    @loc = MyObj::Loc.new(0,0)
    @jump_millis = @blink_millis = 0
    @foot = @right = @left = 0

    # set player variables ------------------------------------------------------------
    @health = @config[:current_health]
    @base_health = @config[:base_health]
    @blink_charge = MAX_PERCENT
    @blink_recharge_rate = @config[:blink_recharge_rate]

    # init state variables ------------------------------------------------------------
    @up_still_pressed = false
    @on_left_wall = false
    @on_right_wall = false
    @off_ground = true
    @already_walljumped = false
  end

  def warp(loc)
    @loc = loc
  end

  def hitbox
    hitbox_x = ((@loc.x - SIDEROOM).to_i..(@loc.x + SIDEROOM).to_i)
    hitbox_y = ((@loc.y - HEADROOM).to_i..(@loc.y + FOOTROOM).to_i)
    {:x => hitbox_x, :y => hitbox_y}
  end

  def update(left_pressed, right_pressed, up_pressed)
    # check for key presses -----------------------------------------------------------
    if left_pressed then
      @vel_x -= on_floor? ? @config[:speed] : @config[:speed]/10
    end
    if right_pressed then
      @vel_x += on_floor? ? @config[:speed] : @config[:speed]/10
    end
    if up_pressed then
      if (Gosu::milliseconds - @jump_millis) > 250 and not @up_still_pressed
        jump
        @jump_millis = Gosu::milliseconds
      end
      @up_still_pressed = true
    else
      @up_still_pressed = false
    end

    # make the player actually move ---------------------------------------------------
    @config[:noclip] ? move_noclip : move

    # check if player is on a wall ----------------------------------------------------
    check_wall_collisions

    # apply friction and gravity to movement ------------------------------------------
    @vel_x *= on_floor? ? 0.5 : 0.9
    @vel_x = 0 if (@vel_x >= -0.1) and (@vel_x <= 0.1)
    @vel_y = on_floor? ? 0 : @vel_y + @config[:gravity]
    @vel_y = 0 if on_floor?

    puts "#{on_floor?} :: #{@vel_y}"
  end

  def draw(camera)
    @image.draw_rot(*camera.world_to_screen(@loc).to_a, ZOrder::Player, @angle)
  end

  def save
    File.open('config/player.yml', 'w+') {  |f| f.write(@config.to_yaml) }
  end

  def keypress_handler(id)
    case id
      when Gosu::KbBacktick
        @config[:noclip] = !@config[:noclip]
    end
  end


  private

  def move
    @vel_x.floor.to_i.abs.times { @loc.x += would_fit_x? ? (@vel_x <=> 0) : 0 }
    @vel_y.floor.to_i.abs.times { @loc.y += would_fit_y? ? (@vel_y <=> 0) : 0 }
  end

  def move_noclip
    @vel_x.floor.to_i.abs.times { @loc.x += (@vel_x <=> 0) }
    @vel_y.floor.to_i.abs.times { @loc.y += (@vel_y <=> 0) }
  end

  def would_fit_x?
    not @level.solid?(@loc.x-@image.width/2, @loc.y+@image.height/2-1) and
        not @level.solid?(@loc.x-@image.width/2, @loc.y-@image.height/2+1) and
        not @level.solid?(@loc.x+@image.width/2, @loc.y+@image.height/2-1) and
        not @level.solid?(@loc.x+@image.width/2, @loc.y-@image.height/2+1)
  end

  def would_fit_y?
    not @level.solid?(@loc.x-@image.width/2, @loc.y+@image.height/2) and
        not @level.solid?(@loc.x-@image.width/2, @loc.y-@image.height/2) and
        not @level.solid?(@loc.x+@image.width/2, @loc.y+@image.height/2) and
        not @level.solid?(@loc.x+@image.width/2, @loc.y-@image.height/2)
  end

  def on_floor?
    ((@loc.x-@image.width/2).to_i..(@loc.x+@image.width/2).to_i).each do |x|
      if @level.solid?(x,@loc.y+@image.height/2) then return true end
    end
  end

  def jump
    if on_floor?
      if not on_floor?
        if @on_left_wall and not @already_walljumped
          @vel_y -= @config[:jumpheight] * 0.666
          @loc.x += 1
          @vel_x += @config[:speed]
          @already_walljumped = true
        elsif @on_right_wall and not @already_walljumped
          @vel_y -= @config[:jumpheight] * 0.666
          @loc.x -= 1
          @vel_x -= @config[:speed]
          @already_walljumped = true
        end
      else
        @vel_y -= @config[:jumpheight]
      end
    end
  end

  def update_stats(item, value)
    @config[item] = value
  end

  def check_wall_collisions
    if @loc.x >= @window.levelbox.right-@image.width/2
      @loc.x = @window.levelbox.right-@image.width/2
      @vel_x = 0
      @on_right_wall = true
    elsif @loc.x <= @window.levelbox.left+@image.width/2
      @loc.x = @window.levelbox.left+@image.width/2
      @vel_x = 0
      @on_left_wall = true
    else
      @on_left_wall = false
      @on_right_wall = false
    end
    if @loc.y >= @window.levelbox.bot-@image.height/2
      @loc.y = @window.levelbox.bot-@image.height/2
      @vel_y = 0
      @off_ground = false
      @already_walljumped = false
    elsif @loc.y <= @window.levelbox.top+@image.height/2
      @loc.y = @window.levelbox.top+@image.height/2
      @vel_y = 0
    end
  end
end
