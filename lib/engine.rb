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

  attr_reader :level
  def initialize
    @config = YAML.load_file('config/engine.yml')
    super @config[:width], @config[:height], @config[:fullscreen]
    self.caption = "Blink"
    @player = Player.new(self)
    log self, "Player Loaded" if @config[:logging_enabled]
    self.load_new(@config[:level])
  end

  def load_new(level)
    # Camera -----------------------------------------------------------------------------
    @camera = Camera.new(0, 0, :stop_at_wall)
    log self, "Camera loaded" if @config[:logging_enabled]

    # init level -------------------------------------------------------------------------
    @level = Map.new(self, level)
    @goal_fudge_factor = MyObj::Loc.new(65,65)
    @player.give_level

    # Background Image -------------------------------------------------------------------
    @background = Background.new(self, 0, 0, media_path("backgrounds/#{@level.background}"), ZOrder::Background)
    log self, "Background Loaded" if @config[:logging_enabled]


    # Player warp ------------------------------------------------------------------------
    @player.warp(@level.start)
    log self, "Player Warped" if @config[:logging_enabled]

    # enemies ----------------------------------------------------------------------------
    @enemies = Array.new(@level.enemies.size) {Enemy.new(self, @level)}
    @level.enemies.each_with_index { |enemy, idx| @enemies[idx].warp(enemy[:x]*80, enemy[:y]*80) }


    # cursor -----------------------------------------------------------------------------
    @cursor = Cursor.new(self, media_path("cursors/windows_cursor.png"), true)

    # Game Font --------------------------------------------------------------------------
    @font = Gosu::Font.new(self, media_path("fonts/Roboto-Regular.ttf"), 20)
    @large_font = Gosu::Font.new(self, Gosu::default_font_name, 100)
    @edit_mode_txt = Gosu::Image.from_text(self, "-- EDIT MODE --", Gosu::default_font_name, 50)
    @death_text_strings = [
                           "You're dead, good job",
                           "Geez, you suck",
                           "You done goofed",
                           "I can't believe what you just did",
                           "Welp, that was embarrassing",
                           "Why? For the love of god, why??",
                           "You know you have a free blink, right?",
                           "Good for you this isn't real life",
                           "You must suck",
                           "You're probably not supposed to do that...",
                           "Better luck next time?",
                           "How? You don't take fall damage",
                           "I didn't make this game just for you to die",
                           "Try again",
                           "I guess you felt too lucky, punk",
                           "Go and die another day",
                           "100 ways to die... and you pick the lamest one",]
    @death_text = Gosu::Image.from_text(self, @death_text_strings[Gosu::random(0, @death_text_strings.length-1)],
                                        media_path("fonts/note_this.ttf"), 150, 30, self.width, :center)
    @win_text = Gosu::Image.from_text(self, "Level Complete!",
                                      media_path("fonts/note_this.ttf"), 150, 30, self.width, :center)
    @alpha = 0

    # Music ------------------------------------------------------------------------------
    @game_music = Gosu::Song.new(self, media_path("sounds/DST-2ndBallad.ogg"))

    # State Variables --------------------------------------------------------------------
    @level_complete = false
    @eol_millis = 0
    @degrade_millis = 0
    @edit_block_selected = Tiles::Stone
    @edit_block_angle = 0.0

  end # -- end initialization --

  def update
    if @player.dead
      on_player_death
      return
    elsif @level_complete
      on_win
      return
    end
    @game_music.play unless @game_music.playing?
    @player.update((button_down? Gosu::KbLeft or button_down? Gosu::KbA),
                   (button_down? Gosu::KbRight or button_down? Gosu::KbD),
                   (button_down? Gosu::KbUp or button_down? Gosu::KbW),
                   (button_down? Gosu::KbDown or button_down? Gosu::KbS),
                   (button_down? Gosu::KbSpace),
                   (button_down? Gosu::KbLeftShift or button_down? Gosu::KbRightShift))

    @level.degrade_tiles
    update_camera
    block_painter if @config[:edit_mode]
    update_block_selector if @config[:edit_mode]
    @enemies.each { |e| e.move }

    if @level.gems.length == 0 and not @level_complete and (@player.loc - @level.goal <= @goal_fudge_factor)
      @level_complete = true
      @eol_millis = Gosu::milliseconds
    elsif @level_complete
      sleep 1
      close
    end

    @enemies.each { |e| @player.lose_life if collision?(@player, e)}
  end

  def draw
    if @level_complete
      draw_win
      return
    elsif @player.dead
      draw_death
      return
    else
      @player.draw(@camera)
      @background.draw(@camera)
      @level.draw(@camera)
      @cursor.draw if @config[:show_cursor]
      draw_hud
      draw_debug if @config[:debug]
      draw_editmode if @config[:edit_mode]
      draw_block_selector if @config[:edit_mode]
      draw_noclip if @player.config[:noclip]
      draw_loss_life_ani if @player.loss_life_ani
      draw_box
      @enemies.each { |e| e.draw(@camera) }
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
          @config[:edit_mode] = true if @level.editable
          @config[:show_cursor] = true if @level.editable
        end
      when Gosu::KbV
        if @config[:debug]
          @config[:debug] = false
          @config[:show_cursor] = false
        else
          @config[:debug] = true
          @config[:show_cursor] = true
        end
      when Gosu::KbJ
        @edit_block_angle -= 90.0 if @config[:edit_mode]
        @edit_block_angle = 0.0 if @edit_block_angle == -360.0
      when Gosu::KbK
        @edit_block_angle += 90.0 if @config[:edit_mode]
        @edit_block_angle = 0.0 if @edit_block_angle == 360.0
      else
    end
    @player.keypress_handler(id)
  end

  private

  # Drawing functions --------------------------------------------------------------------------------------------------

  def draw_hud
    self.draw_quad(5,   10, Gosu::Color.argb(0xcc000000),
                   160, 10, Gosu::Color.argb(0xcc000000),
                   5,   90, Gosu::Color.argb(0xcc000000),
                   160, 90, Gosu::Color.argb(0xcc000000),
                   ZOrder::HUD)
    @font.draw("Player HP:\t<c=ff0000>#{@player.health}/#{@player.base_health}</c>", 10, 10, ZOrder::HUD)
    @font.draw("Blink Chrg:\t<c=00ff00>%.2f</c>" % @player.blink_charge, 10, 30, ZOrder::HUD)
    @font.draw("Gems Left:\t<c=ff0000>#{@level.gems.length}", 10, 50, ZOrder::HUD)
    @font.draw("Lives:\t\t\t<c=ff0000>#{@player.lives}", 10, 70, ZOrder::HUD)
  end

  def draw_debug
    self.draw_quad(5,   90,  Gosu::Color.argb(0xcc000000),
                   175, 90,  Gosu::Color.argb(0xcc000000),
                   5,   130, Gosu::Color.argb(0xcc000000),
                   175, 130, Gosu::Color.argb(0xcc000000),
                   ZOrder::HUD)
    @font.draw("Mouse - X: #{(mouse_x/80).floor} :: Y: #{(mouse_y/80).floor}", 10, 90, ZOrder::HUD)
    @font.draw("Player - X: #{(@player.loc.x/80).floor} :: Y: #{(@player.loc.y/80).floor}", 10, 110, ZOrder::HUD)
  end

  def draw_noclip
    mod = @config[:debug] ? 40 : 0
    self.draw_quad(5,   90 + mod,  Gosu::Color.argb(0xcc000000),
                   175, 90 + mod,  Gosu::Color.argb(0xcc000000),
                   5,   110 + mod, Gosu::Color.argb(0xcc000000),
                   175, 110 + mod, Gosu::Color.argb(0xcc000000),
                   ZOrder::HUD)
    @font.draw("NO_CLIP ENABLED!", 10, 90 + mod, ZOrder::HUD)
  end

  def draw_editmode
    self.draw_quad(self.width/2-@edit_mode_txt.width/2-5, 35,  Gosu::Color.argb(0xcc000000),
                   self.width/2+@edit_mode_txt.width/2+5, 35,  Gosu::Color.argb(0xcc000000),
                   self.width/2-@edit_mode_txt.width/2-5, 90, Gosu::Color.argb(0xcc000000),
                   self.width/2+@edit_mode_txt.width/2+5, 90, Gosu::Color.argb(0xcc000000),
                   ZOrder::HUD)
    @edit_mode_txt.draw(self.width/2-@edit_mode_txt.width/2, 40, ZOrder::HUD)
  end

  def draw_block_selector
    self.draw_quad(self.width-180, 65,  Gosu::Color.argb(0xcc000000),
                   self.width-25,  65,  Gosu::Color.argb(0xcc000000),
                   self.width-180, 215, Gosu::Color.argb(0xcc000000),
                   self.width-25,  215, Gosu::Color.argb(0xcc000000),
                   ZOrder::HUD)
    @font.draw("Current Block:", self.width - 175, 70, ZOrder::HUD)
    if @edit_block_selected == Tiles::Stone then
      @font.draw("<c=00ff00>1: Stone</c>, <c=ff0000>#{@edit_block_angle}</c>", self.width - 150, 90, ZOrder::HUD)
    else
      @font.draw("1: Stone", self.width - 150, 90, ZOrder::HUD)
    end

    if @edit_block_selected == Tiles::Spike then
      @font.draw("<c=00ff00>2: Spike</c>, <c=ff0000>#{@edit_block_angle}</c>", self.width - 150, 110, ZOrder::HUD)
    else
      @font.draw("2: Spike", self.width - 150, 110, ZOrder::HUD)
    end

    if @edit_block_selected == Tiles::Gem then
      @font.draw("<c=00ff00>3: Gem</c>, <c=ff0000>#{@edit_block_angle}</c>", self.width - 150, 130, ZOrder::HUD)
    else
      @font.draw("3: Gem", self.width - 150, 130, ZOrder::HUD)
    end

    if @edit_block_selected == Tiles::Start then
      @font.draw("<c=00ff00>4: Start</c>, <c=ff0000>#{@edit_block_angle}</c>", self.width - 150, 150, ZOrder::HUD)
    else
      @font.draw("4: Start", self.width - 150, 150, ZOrder::HUD)
    end

    if @edit_block_selected == Tiles::Goal then
      @font.draw("<c=00ff00>5: Goal</c>, <c=ff0000>#{@edit_block_angle}</c>", self.width - 150, 170, ZOrder::HUD)
    else
      @font.draw("5: Goal", self.width - 150, 170, ZOrder::HUD)
    end

    if @edit_block_selected == Tiles::Checkpoint then
      @font.draw("<c=00ff00>6: Checkpoint</c>, <c=ff0000>#{@edit_block_angle}</c>", self.width - 150, 190, ZOrder::HUD)
    else
      @font.draw("6: Checkpoint", self.width - 150, 190, ZOrder::HUD)
    end
  end

  def draw_box
    self.draw_line(*@camera.world_to_screen(MyObj::Loc.new(0,0)).to_a, Gosu::Color::WHITE, *@camera.world_to_screen(MyObj::Loc.new(@level.width, 0)).to_a, Gosu::Color::WHITE)
    self.draw_line(*@camera.world_to_screen(MyObj::Loc.new(1, 0)).to_a, Gosu::Color::WHITE, *@camera.world_to_screen(MyObj::Loc.new(1, @level.height)).to_a, Gosu::Color::WHITE)
    self.draw_line(*@camera.world_to_screen(MyObj::Loc.new(@level.width, 0)).to_a, Gosu::Color::WHITE, *@camera.world_to_screen(MyObj::Loc.new(@level.width, @level.height)).to_a, Gosu::Color::WHITE)
    self.draw_line(*@camera.world_to_screen(MyObj::Loc.new(0, @level.height)).to_a, Gosu::Color::WHITE, *@camera.world_to_screen(MyObj::Loc.new(@level.width, @level.height)).to_a, Gosu::Color::WHITE)
  end

  def draw_death
    self.draw_quad(0, 0, Gosu::Color.new((@alpha * 0xff).to_i, 0xff, 0x00, 0x00),
                   self.width, 0, Gosu::Color.new((@alpha * 0xff).to_i, 0xff, 0x00, 0x00),
                   0, self.height, Gosu::Color.new((@alpha * 0xff).to_i, 0x00, 0x00, 0x00),
                   self.width, self.height, Gosu::Color.new((@alpha * 0xff).to_i, 0x00, 0x00, 0x00),
                   ZOrder::HUD)
    @death_text.draw(self.width/2 - @death_text.width/2, self.height/4, ZOrder::HUD)
    @font.draw("Continue? (Enter)", self.width/2-65, self.height/4*3, ZOrder::HUD)
    @font.draw("Quit? (Esc)", self.width/2-40, self.height/4*3+20, ZOrder::HUD)
  end

  def draw_win
    self.draw_quad(0, 0, Gosu::Color.new((@alpha * 0xff).to_i, 0x00, 0xcc, 0x00),
                   self.width, 0, Gosu::Color.new((@alpha * 0xff).to_i, 0x00, 0xcc, 0x00),
                   0, self.height, Gosu::Color.new((@alpha * 0xff).to_i, 0x00, 0x00, 0x00),
                   self.width, self.height, Gosu::Color.new((@alpha * 0xff).to_i, 0x00, 0x00, 0x00),
                   ZOrder::HUD)
    @win_text.draw(self.width/2 - @win_text.width/2, self.height/4, ZOrder::HUD)
    @font.draw("Continue? (Enter)", self.width/2-65, self.height/4*3, ZOrder::HUD)
    @font.draw("Quit? (Esc)", self.width/2-40, self.height/4*3+20, ZOrder::HUD)
  end

  def draw_loss_life_ani
    flash = 0.5 * Math.sin(Gosu::milliseconds / 133.7)
    self.draw_quad(0, 0, Gosu::Color.new((flash * 0xff).to_i, 0xff, 0x00, 0x00),
                   self.width, 0, Gosu::Color.new((flash * 0xff).to_i, 0xff, 0x00, 0x00),
                   0, self.height, Gosu::Color.new((flash * 0xff).to_i, 0xff, 0x00, 0x00),
                   self.width, self.height, Gosu::Color.new((flash * 0xff).to_i, 0xff, 0x00, 0x00),
                   ZOrder::HUD)
  end

  # Update functions ---------------------------------------------------------------------------------------------------

  def update_block_selector
    if button_down? Gosu::Kb1 or button_down? Gosu::KbNumpad1
      @edit_block_selected = Tiles::Stone
    elsif button_down? Gosu::Kb2 or button_down? Gosu::KbNumpad2
      @edit_block_selected = Tiles::Spike
    elsif button_down? Gosu::Kb3 or button_down? Gosu::KbNumpad3
      @edit_block_selected = Tiles::Gem
    elsif button_down? Gosu::Kb4 or button_down? Gosu::KbNumpad4
      @edit_block_selected = Tiles::Start
    elsif button_down? Gosu::Kb5 or button_down? Gosu::KbNumpad5
      @edit_block_selected = Tiles::Goal
    elsif button_down? Gosu::Kb6 or button_down? Gosu::KbNumpad6
      @edit_block_selected = Tiles::Checkpoint
    end
  end

  def block_painter
    if button_down? Gosu::MsLeft
      @level.create_block(@camera, MyObj::Loc.new(self.mouse_x+25, self.mouse_y), @edit_block_selected, @edit_block_angle)
    elsif button_down? Gosu::MsRight
      @level.delete_block(@camera, MyObj::Loc.new(self.mouse_x+25, self.mouse_y))
    end
  end

  def update_camera
    if @camera.type == :track_player
      @camera.x = @player.loc.x - self.width/2
      @camera.y = @player.loc.y - self.height/2 - 50
    elsif @camera.type == :stop_at_wall
      @camera.x = @player.loc.x - self.width/2
      @camera.y = @player.loc.y - self.height/2 - 50

      @camera.x = 0 if @camera.x <= 0
      @camera.x = @level.width-self.width+1 if @camera.x >= @level.width-self.width+1
      @camera.y = 0 if @camera.y <= 0
      @camera.y = @level.height-self.height+1 if @camera.y >= @level.height-self.height+1
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

  def on_player_death
    @game_music.volume <= 0 ? @game_music.stop : @game_music.volume = @game_music.volume - 0.005
    @alpha = @alpha >= 1 ? 1 : @alpha + 0.005
    revive if button_down? Gosu::KbEnter or button_down? Gosu::KbReturn
  end
  def on_win
    @game_music.volume <= 0 ? @game_music.stop : @game_music.volume = @game_music.volume - 0.005
    @alpha = @alpha >= 1 ? 1 : @alpha + 0.005
    next_level if button_down? Gosu::KbEnter or button_down? Gosu::KbReturn
  end

  def revive
    flush
    @player = Player.new(self)
    load_new(@config[:level])
  end

  def next_level
    @level.next_level ? load_new(@level.next_level) : close
  end

end

