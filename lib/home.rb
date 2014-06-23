# This is the home file that launches before anything else
#   From here the player can configure the game, select levels, etc.

require 'rubygems'
#require 'bundler/setup'
require 'gosu'
require 'yaml'

require './lib/engine.rb'

require_relative '../objects/cursor'
require_relative '../objects/scripted_npc'

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class HomeWindow < Gosu::Window
  attr_reader :next_window, :exit
  TILE_SIZE = 80
  def initialize
    @home_config = YAML.load_file('config/home.yml')
    @engine_config = YAML.load_file('config/engine.yml')
    super 800, 600, false
    self.caption = "Blink"

    # media ------------------------------------------------------------------------------------------------------------
    @cursor = Cursor.new(self, media_path("cursors/windows_cursor.png"), true)
    @background = Background.new(self, 0, 0, media_path("backgrounds/bluewood.jpg"), ZOrder::Background, :falling)
    @tileset = Gosu::Image.load_tiles(self, media_path("tilesets/plat_tiles.png"), TILE_SIZE, TILE_SIZE, true)
    @npc = NPC.new(self, media_path("characters/Character Boy.png"))
    @npc.warp(-500, 200)
    @npc.floor -= TILE_SIZE
    @npc.lock_x(5)
    @npc_looparound = Gosu::random(self.width, self.width + 10000)

    # text -------------------------------------------------------------------------------------------------------------
    @play_text = Gosu::Image.from_text(self, "Play", media_path("fonts/note_this.ttf"), 25)
    @title_text = Gosu::Image.from_text(self, "Blink", media_path("fonts/note_this.ttf"), 150)

    # buttons ----------------------------------------------------------------------------------------------------------
    @play_button = Gosu::Image.new(self, media_path("buttons/play.png"), false)
    @play_button_hash = {:obj => @play_button,
                         :x => (self.width/4)*3-100-@play_button.width/2,
                         :y => self.height/2-@play_button.height/2}
    @settings_button = Gosu::Image.new(self, media_path("buttons/settings.png"), false)
    @settings_button_hash = {:obj => @settings_button,
                         :x => self.width/4+100-@settings_button.width/2,
                         :y => self.height/2-@settings_button.height/2}
    @buttons = [@play_button_hash, @settings_button_hash]

    # music ------------------------------------------------------------------------------------------------------------
    @intro_song = Gosu::Song.new(self, media_path("sounds/DST-BlinkWorld.ogg"))
    @intro_song.play(true)
    @next_window = nil
    @exit = false
  end

  def update
    @intro_song.play unless @intro_song.playing?
    @background.update
    @npc.update
    @npc_jump_loc = Gosu::random(0, self.width*3).floor if @npc.loc.x < 0
    if (@npc.loc.x - @npc_jump_loc).floor.abs < 5
      @npc.jump
    end
    if @npc.loc.x > @npc_looparound
      @npc.warp(-500,200)
      @npc_looparound = Gosu::random(self.width, self.width + 10000)
    end
  end

  def draw
    @background.draw(nil)
    @cursor.draw
    @title_text.draw(self.width/2-@title_text.width/2,50,0)
    @play_button.draw((self.width/4)*3-100-@play_button.width/2, self.height/2-@play_button.height/2, 0)
    @play_text.draw((self.width/4)*3-100-@play_text.width/2-4, self.height/2-@play_text.height/2, 0, 1, 1, Gosu::Color.new(0xff, 0x00, 0x00, 0x00), :default)
    @settings_button.draw(self.width/4+100-@settings_button.width/2, self.height/2-@settings_button.height/2, 0)
    0.upto(self.width/TILE_SIZE) do |idx|
      @tileset[Tiles::Stone].draw(TILE_SIZE * idx, self.height - TILE_SIZE, ZOrder::Terrain)
    end
    @npc.draw
  end

  def button_down(id)
    case id
      when Gosu::MsLeft
        button_click_handler(check_for_click(self.mouse_x, self.mouse_y))
      when Gosu::KbEscape
        @exit = true
        close
      else
    end
  end

  private

  def check_for_click(x, y)
    @buttons.each do |button|
      x_val = (button[:x]..(button[:x] + button[:obj].width)).to_a.include?(x.to_i)
      y_val = (button[:y]..(button[:y] + button[:obj].width)).to_a.include?(y.to_i)
      if x_val and y_val
        return button[:obj]
      end
    end
    nil
  end

  def button_click_handler(button)
    return false unless button
    case button
      when @play_button
        @next_window = :game
        close
      when @settings_button
        @next_window = :settings
        close
    end
  end

end