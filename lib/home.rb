# This is the home file that launches before anything else
#   From here the player can configure the game, select levels, etc.

require 'rubygems'
#require 'bundler/setup'
require 'gosu'
require 'yaml'

require './lib/engine.rb'

require_relative '../objects/cursor'

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class HomeWindow < Gosu::Window
  def initialize
    @home_config = YAML.load_file('config/home.yml')
    @engine_config = YAML.load_file('config/engine.yml')
    super 800, 600, false
    self.caption = "Blink"

    @cursor = Cursor.new(self, media_path("cursors/windows_cursor.png"), true)
    @background = Background.new(self, 0, 0, media_path("backgrounds/bluewood.jpg"), ZOrder::Background)

    @play_text = Gosu::Image.from_text(self, "Play", media_path("fonts/note_this.ttf"), 25)
    @title_text = Gosu::Image.from_text(self, "Blink", media_path("fonts/note_this.ttf"), 150)

    @play_button = Gosu::Image.new(self, media_path("buttons/play.png"), false)
    @play_button_hash = {:obj => @play_button,
                         :x => self.width/2-@play_button.width/2,
                         :y => self.height/2-@play_button.height/2}
    @buttons = [@play_button_hash]

    @level_to_play = "levels/level_1.txt"
  end

  def update
  end

  def draw
    @background.draw(nil)
    @cursor.draw
    @title_text.draw(self.width/2-@title_text.width/2,50,0)
    @play_button.draw(self.width/2-@play_button.width/2, self.height/2-@play_button.height/2, 0)
    @play_text.draw(self.width/2-@play_text.width/2-4, self.height/2-@play_text.height/2, 0, 1, 1, Gosu::Color.new(0xff, 0x00, 0x00, 0x00), :default)
  end

  def button_down(id)
    case id
      when Gosu::MsLeft
        button_click_handler(check_for_click(self.mouse_x, self.mouse_y))
        game_window = GameWindow.new(@level_to_play)
        game_window.show()
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

    end
  end

end