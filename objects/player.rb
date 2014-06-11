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

  attr_accessor :health, :base_health, :recently_hit, :on_left_wall, :on_right_wall, :blink_charge
  attr_reader :loc

  def initialize(window)
    # init window for player ----------------------------------------------------------
    @window = window

    # load resources
    @config = YAML.load_file('config/player.yml')
      log self, "Initializing object..."  if @config[:logging_enabled]
    @image = Gosu::Image.new(window, media_path("characters/Character Boy.png"), false)
      log self, "Image loaded"  if @config[:logging_enabled]

    # normalize angles and locations --------------------------------------------------
    @vel_x = @vel_y = @angle = 0.0
    @loc = MyObj::Loc.new(0,0)
    @jump_millis = @blink_millis = 0

    # set player variables ------------------------------------------------------------
    @health = @config[:current_health]
    @base_health = @config[:base_health]
    @blink_charge = MAX_PERCENT
    @blink_recharge_rate = @config[:blink_recharge_rate]

    # init state variables ------------------------------------------------------------
    @up_still_pressed = false
    @on_left_wall = false
    @on_right_wall = false
    @off_ground = false
  end

  def warp(loc)
    @loc = loc
  end

  def hitbox
    hitbox_x = ((@loc.x - @image.width/2 + SIDEROOM).to_i..(@loc.x + @image.width/2 - SIDEROOM))
    hitbox_y = ((@loc.y - @image.height/2 + HEADROOM).to_i..(@loc.y + @image.height/2 - FOOTROOM))
    {:x => hitbox_x, :y => hitbox_y}
  end

  def update(left_pressed, right_pressed, up_pressed)
    # check for key presses
    if left_pressed then
      @vel_x -= @config[:speed]
    end
    if right_pressed then
      @vel_x += @config[:speed]
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

    # update location values
    @loc.x += @vel_x
    @loc.y += @vel_y

    # check if player is on a wall
    check_wall_collisions

    # apply friction and gravity to movement
    @vel_x *= 0.5
    @vel_x = 0 if (@vel_x >= -0.1) and (@vel_x <= 0.1)
    @vel_y = @vel_y + @config[:gravity]
  end

  def draw(camera)
    @image.draw_rot(*camera.world_to_screen(@loc).to_a, ZOrder::Player, @angle)
  end

  def save
    File.open('config/player.yml', 'w+') {  |f| f.write(@config.to_yaml) }
  end

  private

  def jump
    if @off_ground
      if @on_left_wall
        @vel_y -= 10
        @loc.x -= 1
        @vel_x -= 5
      elsif @on_right_wall
        @vel_y -= 10
        @loc.x += 1
        @vel_x += 5
      end
    else
      @vel_y -= 15
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
    elsif @loc.y <= @window.levelbox.top+HEADROOM
      @loc.y = @window.levelbox.top+HEADROOM
      @vel_y = 0
    end
  end
end
