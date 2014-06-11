#  
#  Blink - a platformer that should be a bit fun
#
#     Author:     Devon Finninger
#     Init Date:  2014-06-04
#
# Note: This is the main file that should be run to play the game

require 'rubygems'
#require 'bundler/setup'
require 'gosu'
require 'yaml'

require_relative 'zorder'
require_relative 'blinkutils'
require_relative 'myobj'
require_relative 'camera'
require_relative 'level'

require_relative '../objects/enemy'
require_relative '../objects/player'
require_relative '../objects/background'
require_relative '../objects/platform'
require_relative '../objects/collectibles'

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class GameWindow < Gosu::Window
  include BlinkUtils

  attr_reader :levelbox
  def initialize
    @config = YAML.load_file('config/window.yml')
    super @config[:width], @config[:height], @config[:fullscreen]
    self.caption = "Blink"

    # Camera -----------------------------------------------------------------------------
    @camera = Camera.new(0, 0, :stop_at_wall)
    log self, "Camera loaded" if @config[:logging_enabled]

    # Walls, ceiling and floor -----------------------------------------------------------
    @levelbox = MyObj::LevelBox.new(0, 1920, 0, 1080)

    # Background Image -------------------------------------------------------------------
    #@background_image = Gosu::Image.new(self, media_path("backgrounds/bluewood.jpg"), true)
    @background = Background.new(self, 0, 0, media_path("backgrounds/bluewood.jpg"), ZOrder::Background)
    log self, "Background Loaded" if @config[:logging_enabled]

    # Player -----------------------------------------------------------------------------
    @player = Player.new(self)
    log self, "Player Loaded" if @config[:logging_enabled]
    @player.warp(MyObj::Loc.new(@levelbox.right/2,levelbox.bot/2))
    log self, "Player Warped" if @config[:logging_enabled]

    # Game Font --------------------------------------------------------------------------
    @font = Gosu::Font.new(self, Gosu::default_font_name, 18)

    # Wall padding -----------------------------------------------------------------------
    @padding = @config[:levelbox_padding]

    # init level -------------------------------------------------------------------------
    @level = Level.new(self, media_path("levels/CptnRuby Map.txt"))

  end # -- end initialization --

  def update
    @player.update((button_down? Gosu::KbLeft),
                   (button_down? Gosu::KbRight),
                   (button_down? Gosu::KbUp))
    update_camera
  end

  def draw
    @player.draw(@camera)
    @background.draw(@camera)
    @font.draw("Player HP: <c=ff0000>#{@player.health}/#{@player.base_health}</c>", 10, 10, ZOrder::HUD)
    @font.draw("Blink Charge: <c=00ff00>#{@player.blink_charge}%</c>", 10, 30, ZOrder::HUD)
    @level.draw(@camera)
  end

  def button_down(id)
    if id == Gosu::KbEscape
      save
      close
    end
  end

  private

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
  end

end

