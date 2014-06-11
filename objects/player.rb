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
      @vel_x -= @off_ground ? @config[:speed]/10 : @config[:speed]
    end
    if right_pressed then
      @vel_x += @off_ground ? @config[:speed]/10 : @config[:speed]
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
    @vel_x *= @off_ground ? 0.9 : 0.5
    @vel_x = 0 if (@vel_x >= -0.1) and (@vel_x <= 0.1)
    @vel_y = @off_ground ? @vel_y + @config[:gravity] : 0

    # find out where the player's feet are --------------------------------------------
    @foot = (@loc.y + FOOTROOM).to_i
    @right = (@loc.x - SIDEROOM).to_i
    @left = (@loc.x + SIDEROOM).to_i


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
    @vel_x.floor.to_i.times{ @loc.x += would_fit? ? 1 : 0}
    @loc.y += @vel_y
  end

  def move_noclip
    @loc.x += @vel_x
    @loc.y += @vel_y
  end

  def would_fit?
    not @level.solid?(*@loc.to_a) and
        not @level.solid?(@loc.x, @loc.y-45)
  end

  def jump
    if @off_ground
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

  def update_stats(item, value)
    @config[item] = value
  end

  def check_wall_collisions
    @off_ground = true if ((0 <=> @vel_y) == 1) and (!@off_ground)
    if @loc.x >= @window.levelbox.right-SIDEROOM
      @loc.x = @window.levelbox.right-SIDEROOM
      @vel_x = 0
      @on_right_wall = true
    elsif @loc.x <= @window.levelbox.left+SIDEROOM
      @loc.x = @window.levelbox.left+SIDEROOM
      @vel_x = 0
      @on_left_wall = true
    else
      @on_left_wall = false
      @on_right_wall = false
    end
    if @loc.y >= @window.levelbox.bot-FOOTROOM
      @loc.y = @window.levelbox.bot-FOOTROOM
      @vel_y = 0
      @off_ground = false
      @already_walljumped = false
    elsif @loc.y <= @window.levelbox.top+HEADROOM
      @loc.y = @window.levelbox.top+HEADROOM
      @vel_y = 0
    end
  end
end
