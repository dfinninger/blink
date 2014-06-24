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
  MAX_PERCENT = 100
  MAX_FALL_SPEED = 50

  attr_accessor :loc, :health, :base_health, :recently_hit, :on_left_wall,
                :on_right_wall, :off_ground, :config, :gems_collected, :dead
  attr_reader :foot, :left, :right, :blink_charge, :blink_prep, :lives, :loss_life_ani

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
    @lives = @config[:base_lives]

    # init state variables ------------------------------------------------------------
    @up_still_pressed = false
    @on_left_wall = false
    @on_right_wall = false
    @already_walljumped = false
    @gems_collected = 0
    @blink_prep = false
    @blink_recharging = false
    @current_blink_length = 0
    @dead = false
    @animation_playing = false
    @invulnerable = false
    @wobble_millis = 0
    @travel_step = nil
  end

  def warp(loc)
    @loc.x = loc.x
    @loc.y = loc.y
  end

  def hitbox
    hitbox_x = ((@loc.x - SIDEROOM).to_i..(@loc.x + SIDEROOM).to_i)
    hitbox_y = ((@loc.y - HEADROOM).to_i..(@loc.y + FOOTROOM).to_i)
    {:x => hitbox_x, :y => hitbox_y}
  end

  def update(left_pressed, right_pressed, up_pressed, down_pressed, blink_button_pressed)
    if @dead
      on_player_death
      return
    end

    if @animation_playing
      animation_handler
      return
    end

    adjust_velocity(left_pressed, right_pressed, up_pressed, down_pressed)
    @config[:noclip] ? move_noclip(left_pressed, right_pressed, up_pressed, down_pressed) : move
    collect_goodies(@level.gems)

    check_wall_collisions
    @health -= 2 if inside_wall? unless @config[:noclip]

    update_blink(blink_button_pressed)

    # apply friction and gravity to movement ------------------------------------------
    friction_and_gravity(right_pressed, left_pressed)

    # walljump ------------------------------------------------------------------------
    @already_walljumped = false unless on_left_wall? or on_right_wall?

    # adjust player angle -------------------------------------------------------------
    update_player_angle

    check_damaging_tiles unless @config[:noclip]
    check_health
  end

  def draw(camera)
    @image.draw_rot(*camera.world_to_screen(@loc).to_a, ZOrder::Player, @angle)
    draw_blink(camera) if @blink_prep
  end

  def save
    File.open('config/player.yml', 'w+') {  |f| f.write(@config.to_yaml) }
  end

  def keypress_handler(id)
    case id
      when Gosu::KbQ
        @config[:noclip] = !@config[:noclip]
      when Gosu::KbR
        warp(@level.start)
      when Gosu::KbF
        @blink_charge = 100
      else
    end
  end

  def lose_life
    @lives -= 1 unless @invulnerable
    @dead = @lives == 0 ? true : false
    #warp(@level.start)
    @invulnerable = true
    @loss_life_ani = true
    @animation_playing = true
  end

  # ====================================================================================================================
  # -- PRIVATE METHODS -------------------------------------------------------------------------------------------------
  # ====================================================================================================================

  private

  def move
    if (@vel_x <=> 0) == 1
      @vel_x.to_i.abs.times { @loc.x += would_fit_right? ? 1 : 0 }
    elsif (@vel_x <=> 0) == -1
      @vel_x.to_i.abs.times { @loc.x += would_fit_left? ? -1 : 0 }
    end

    if (@vel_y <=> 0) == 1
      @vel_y.to_i.abs.times { @loc.y += on_floor? ? 0 : 1 }
    elsif (@vel_y <=> 0) == -1
      @vel_y.to_i.abs.times { @loc.y += would_fit_up? ? -1 : 0 }
      @vel_y = 0 unless would_fit_up?
    end
  end

  def move_noclip(l, r, u, d)
    @vel_x = @vel_y = 0
    @loc.x -= @config[:noclip_speed] if l
    @loc.x += @config[:noclip_speed] if r
    @loc.y -= @config[:noclip_speed] if u
    @loc.y += @config[:noclip_speed] if d
  end

  def friction_and_gravity(r, l)
    @vel_x = @config[:max_run_speed] if @vel_x > @config[:max_run_speed]
    @vel_x = -@config[:max_run_speed] if @vel_x < -@config[:max_run_speed]
    unless r or l
      @vel_x *= 0.5 if on_floor?
    end
    @vel_x *= 0.9 unless on_floor?
    @vel_x = 0 if (@vel_x >= -0.1) and (@vel_x <= 0.1)
    @vel_y = on_floor? ? 0 : @vel_y + @config[:gravity]
    if on_left_wall? or on_right_wall?
      @vel_y = (MAX_FALL_SPEED - 40) if @vel_y > (MAX_FALL_SPEED - 40)
    else
      @vel_y = MAX_FALL_SPEED if @vel_y > MAX_FALL_SPEED
    end
  end

  def update_blink(blink_button_pressed) # This is where we get the name from!!
    if blink_button_pressed and (@blink_charge.to_i == 100)
      @blink_prep = true
      if @current_blink_length <= @config[:blink_distance]
        @current_blink_length += @config[:blink_distance] / 10
      elsif @current_blink_length >= @config[:blink_distance]
        @current_blink_length = @config[:blink_distance]
      end
    elsif @blink_prep and not blink_button_pressed
      @blink_prep = false
      blink
      @blink_recharging = true
      @current_blink_length = 0
      @blink_charge = 0
    end

    if @blink_recharging
      if @blink_charge < MAX_PERCENT
        @blink_charge += @config[:blink_recharge_rate]
      else
        @blink_charge = MAX_PERCENT
        @blink_recharging = false
      end
    end
  end

  def draw_blink(camera)
      temp = @loc.x + (@current_blink_length * (@vel_x <=> 0))
      @window.draw_triangle(*camera.world_to_screen(MyObj::Loc.new(@loc.x, @loc.y-@image.height/4)).to_a, Gosu::Color.argb(0xFF0000FF),
                            *camera.world_to_screen(MyObj::Loc.new(@loc.x, @loc.y+@image.height/4)).to_a, Gosu::Color.argb(0xFF0000FF),
                            *camera.world_to_screen(MyObj::Loc.new(temp, @loc.y-@image.height/4)).to_a, Gosu::Color.argb(0xFFFF0000),
                            ZOrder::PlayerEffects)
  end

  def blink
    @loc.x += (@current_blink_length * (@vel_x <=> 0))
  end

  def animation_handler
    if @loss_life_ani
      @angle += 3.6
      @travel_step = (@level.start - @loc)*0.01 unless @travel_step
      @loc = @loc + @travel_step
      if (@loc.x - @level.start.x).abs < 20 and (@loc.y - @level.start.y).abs < 20
        @loss_life_ani = false
        @animation_playing = false
        @invulnerable = false
        @travel_step = nil
        @vel_x = @vel_y = 0
      end
    end
  end

  def adjust_velocity(left_pressed, right_pressed, up_pressed, down_pressed)
    if left_pressed then
      @vel_x -= on_floor? ? @config[:speed] : @config[:speed]/5
    end
    if right_pressed then
      @vel_x += on_floor? ? @config[:speed] : @config[:speed]/5
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
  end

  def on_left_wall?
    not would_fit?(0,0)
  end
  def on_right_wall?
    not would_fit?(@image.width,0)
  end

  def would_fit?(x_offset, y_offset)
    not @level.solid?(@loc.x + x_offset, @loc.y + y_offset) and
        not @level.solid?(@loc.x + x_offset, @loc.y + y_offset - @image.height/2)
  end

  def would_fit_left?
    ((@loc.y-@image.height/2+1).to_i..(@loc.y+@image.height/2-1).to_i).each do |y|
      if @level.solid?(@loc.x+14,y)
        @on_left_wall = true
        return false
      end
    end
    @on_left_wall = false
    true
  end

  def would_fit_right?
    ((@loc.y-@image.height/2+1).to_i..(@loc.y+@image.height/2-1).to_i).each do |y|
      if @level.solid?(@loc.x+@image.width-14,y)
        @on_right_wall = true
        return false
      end
    end
    @on_right_wall = false
    true
  end

  def would_fit_up?
    ((@loc.x+@image.width/2-15).to_i..(@loc.x+@image.width/2+15).to_i).each do |x|
      return false if @level.solid?(x,@loc.y-@image.height/2)
    end
    true
  end

  def on_floor?
    ((@loc.x+@image.width/2-15).to_i..(@loc.x+@image.width/2+15).to_i).each do |x|
      if @level.solid?(x,@loc.y+@image.height/2)
        @already_walljumped = false
        return true
      end
    end
    false
  end

  def near_floor?
    ((@loc.x+@image.width/2-15).to_i..(@loc.x+@image.width/2+15).to_i).each do |x|
      return true if @level.solid?(x,@loc.y+@image.height/2+60)
    end
    false
  end

  def inside_wall?
    not would_fit_up? and
        not would_fit_left? and
        not would_fit_right?
  end

  def update_player_angle
    if on_left_wall? and not near_floor?
      @angle = 20.0
    elsif on_right_wall? and not near_floor?
      @angle = -20.0
    else
      @angle = @vel_x * 2
      @angle += 3*Math.sin(Gosu::milliseconds / 133.7) if @vel_x.abs == @config[:max_run_speed]
    end
  end

  def jump
    if on_floor?
      @vel_y -= @config[:jumpheight]
    else
      if on_left_wall? and not @already_walljumped
        @vel_y -= @config[:jumpheight] * 0.666
        @loc.x += 1
        @vel_x += @config[:speed]
        @already_walljumped = true
      elsif on_right_wall? and not @already_walljumped
        @vel_y -= @config[:jumpheight] * 0.666
        @loc.x -= 1
        @vel_x -= @config[:speed]
        @already_walljumped = true
      end
    end
  end

  def update_stats(item, value)
    @config[item] = value
  end

  def check_health
    if @health < 0
      @health = 0
      lose_life
    end
  end

  def check_damaging_tiles
    # left
    ((@loc.y-@image.height/4).to_i..(@loc.y+@image.height/4).to_i).each do |y|
      lose_life if @level.tile_instant_death?(@loc.x+20,y)
    end

    #right
    ((@loc.y-@image.height/4).to_i..(@loc.y+@image.height/4).to_i).each do |y|
      lose_life if @level.tile_instant_death?(@loc.x+@image.width-20,y)
    end

    #up
    ((@loc.x+@image.width/2-15).to_i..(@loc.x+@image.width/2+15).to_i).each do |x|
      lose_life if @level.tile_instant_death?(x,@loc.y-@image.height/4)
    end

    #down
    ((@loc.x+@image.width/2-15).to_i..(@loc.x+@image.width/2+15).to_i).each do |x|
      lose_life if @level.tile_instant_death?(x,@loc.y+@image.height/4)
    end
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

  def collect_goodies(goodies)
    # Same as in the tutorial game.
    goodies.reject! do |c|
      if (c.loc.x - @loc.x).abs < 50 and (c.loc.y - @loc.y).abs < 50
        @gems_collected += 1
        true
      end
    end
  end

  def on_player_death
    @angle = 90.0
    @loc.y += 1
  end
end
