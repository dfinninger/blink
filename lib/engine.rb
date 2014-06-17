#  
#  Blink - a platformer that should be a bit fun
#
#     Author:     Devon Finninger
#     Init Date:  2014-06-04
#
#

require 'rubygems'
#require 'bundler/setup'
require 'gosu'
require 'yaml'

require_relative 'enums'
require_relative 'blinkutils'
require_relative 'myobj'
require_relative 'camera'
require_relative 'level'
require_relative 'map'

require_relative '../objects/enemy'
require_relative '../objects/player'
require_relative '../objects/background'
require_relative '../objects/platform'
require_relative '../objects/collectibles'
require_relative '../objects/cursor'

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class GameWindow < Gosu::Window
  include BlinkUtils

  attr_reader :levelbox, :level
  def initialize
    @config = YAML.load_file('config/window.yml')
    super @config[:width], @config[:height], @config[:fullscreen]
    self.caption = "Blink"

    # Camera -----------------------------------------------------------------------------
    @camera = Camera.new(0, 0, :stop_at_wall)
    log self, "Camera loaded" if @config[:logging_enabled]

    # init level -------------------------------------------------------------------------
    @level = Map.new(self)
    @goal_fudge_factor = MyObj::Loc.new(65,65)

    # Walls, ceiling and floor -----------------------------------------------------------
    @levelbox = MyObj::LevelBox.new(0, @level.width, 0, @level.height)

    # Background Image -------------------------------------------------------------------
    #@background_image = Gosu::Image.new(self, media_path("backgrounds/bluewood.jpg"), true)
    @background = Background.new(self, 0, 0, media_path("backgrounds/bluewood.jpg"), ZOrder::Background)
    log self, "Background Loaded" if @config[:logging_enabled]

    # Player -----------------------------------------------------------------------------
    @player = Player.new(self)
    log self, "Player Loaded" if @config[:logging_enabled]
    @player.warp(@level.start)
    log self, "Player Warped" if @config[:logging_enabled]

    # cursor -----------------------------------------------------------------------------
    @cursor = Cursor.new(self, media_path("cursors/windows_cursor.png"), true)

    # Game Font --------------------------------------------------------------------------
    @font = Gosu::Font.new(self, Gosu::default_font_name, 18)
    @large_font = Gosu::Font.new(self, Gosu::default_font_name, 100)
    @edit_mode_txt = Gosu::Image.from_text(self, "-- EDIT MODE --", Gosu::default_font_name, 50)

    # Wall padding -----------------------------------------------------------------------
    @padding = @config[:levelbox_padding]

    # State Variables --------------------------------------------------------------------
    @level_complete = false
    @eol_millis = 0
    @edit_block_selected = Tiles::Stone

  end # -- end initialization --

  def update
    @player.update((button_down? Gosu::KbLeft or button_down? Gosu::KbA),
                   (button_down? Gosu::KbRight or button_down? Gosu::KbD),
                   (button_down? Gosu::KbUp or button_down? Gosu::KbW),
                   (button_down? Gosu::KbDown or button_down? Gosu::KbS))

    update_camera
    block_painter if @config[:edit_mode]
    update_block_selector if @config[:edit_mode]

    if @level.gems.length == 0 and not @level_complete and (@player.loc - @level.goal <= @goal_fudge_factor)
      @level_complete = true
      @eol_millis = Gosu::milliseconds
    end
  end

  def draw
    if @level_complete and (Gosu::milliseconds - @eol_millis) > 250
      @font.draw("Level Complete!", self.width/2-60, self.height/2, ZOrder::HUD)
    else
      @player.draw(@camera)
      @background.draw(@camera)
      @level.draw(@camera)
      @cursor.draw if @config[:show_cursor]
      draw_hud
      draw_debug if @config[:debug]
      draw_editmode if @config[:edit_mode]
      draw_block_selector if @config[:edit_mode]
    end
  end

  def button_down(id)
    case id
      when Gosu::KbEscape
        save
        close
      when Gosu::KbE
        if @config[:edit_mode]
          @config[:edit_mode] = false
          @config[:show_cursor] = false
        else
          @config[:edit_mode] = true
          @config[:show_cursor] = true
        end
      else
    end
    @player.keypress_handler(id)
  end

  private

  def draw_hud
    @font.draw("Player HP: <c=ff0000>#{@player.health}/#{@player.base_health}</c>", 10, 10, ZOrder::HUD)
    @font.draw("Blink Charge: <c=00ff00>#{@player.blink_charge}%</c>", 10, 30, ZOrder::HUD)
    @font.draw("Gems Remaining: <c=ff0000>#{@level.gems.length}", self.width-175, 10, ZOrder::HUD)
  end

  def draw_debug
    @font.draw("Mouse - X: #{mouse_x} :: Y: #{mouse_y}", 10, 50, ZOrder::HUD)
    @font.draw("Player - X: #{@player.loc.x} :: Y: #{@player.loc.y}", 10, 70, ZOrder::HUD)
    @font.draw("<c=0000ff>NO_CLIP ENABLED!</c>", 10, 90, ZOrder::HUD) if @player.config[:noclip]
  end

  def draw_editmode
    @edit_mode_txt.draw(self.width/2-@edit_mode_txt.width/2, 40, ZOrder::HUD)
  end

  def draw_block_selector
    @font.draw("Current Block:", self.width - 175, 70, ZOrder::HUD)
    @edit_block_selected == Tiles::Stone ? @font.draw("<c=00ff00>1: Stone</c>", self.width - 150, 90, ZOrder::HUD) : @font.draw("1: Stone", self.width - 150, 90, ZOrder::HUD)
    @edit_block_selected == Tiles::Gem   ? @font.draw("<c=00ff00>2: Gem</c>", self.width - 150, 110, ZOrder::HUD)   : @font.draw("2: Gem", self.width - 150, 110, ZOrder::HUD)
  end

  def update_block_selector
    if button_down? Gosu::Kb1 or button_down? Gosu::KbNumpad1
      @edit_block_selected = Tiles::Stone
    elsif button_down? Gosu::Kb2 or button_down? Gosu::KbNumpad2
      @edit_block_selected = Tiles::Gem
    end
  end

  def block_painter
    if button_down? Gosu::MsLeft
      @level.create_block(@camera, MyObj::Loc.new(self.mouse_x+25, self.mouse_y), @edit_block_selected) if @config[:edit_mode]
    elsif button_down? Gosu::MsRight
      @level.delete_block(@camera, MyObj::Loc.new(self.mouse_x+25, self.mouse_y)) if @config[:edit_mode]
    end
  end

  def update_camera
    if @camera.type == :track_player
      @camera.x = @player.loc.x - self.width/2
      @camera.y = @player.loc.y - self.height/2 - 50
    elsif @camera.type == :stop_at_wall
      @camera.x = @player.loc.x - self.width/2
      @camera.y = @player.loc.y - self.height/2 - 50

      @camera.x = @levelbox.left-@padding if @camera.x <= @levelbox.left-@padding
      @camera.x = @levelbox.right-self.width+@padding if @camera.x >= @levelbox.right-self.width+@padding
      @camera.y = @levelbox.top-@padding if @camera.y <= @levelbox.top-@padding
      @camera.y = @levelbox.bot-self.height+@padding if @camera.y >= @levelbox.bot-self.height+@padding
    end
    log self, "Camera loc - x: #{@camera.x}, y: #{@camera.y}" if @config[:logging_enabled]
  end

  def collision?(object_1, object_2)
    hitbox_1, hitbox_2 = object_1.hitbox, object_2.hitbox
    common_x = hitbox_1[:x].to_a & hitbox_2[:x].to_a
    common_y = hitbox_1[:y].to_a & hitbox_2[:y].to_a
    common_x.size > 0 && common_y.size > 0
  end

  def save
    @player.save
    @level.save
  end

end

