require 'rubygems'
require 'gosu'
require 'yaml'

require_relative '../objects/textbox'

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class SettingsWindow < Gosu::Window
  def initialize
    super(400, 300, false)
    self.caption = "Blink Settings"

    @config = YAML.load_file('config/engine.yml')
    @init_text = [@config[:height].to_s, @config[:width].to_s, @config[:fullscreen].to_s]
    @init_descriptors = ["Height", "Width", "Fullscreen?"]

    font = Gosu::Font.new(self, Gosu::default_font_name, 20)

    # Set up an array of three text fields.
    @text_fields = Array.new(3) { |index| TextField.new(self, font, 200, 30 + index * 50, @init_text[index]) }
    @text_descriptors = Array.new(3) { |index| Gosu::Image.from_text(self, @init_descriptors[index], font, 20) }

    @cursor = Gosu::Image.new(self, media_path("cursors/windows_cursor.png"), false)

    @save_message = Gosu::Image.from_text(self, "Press ESC to save and exit.", font, 20)
  end

  def draw
    @text_fields.each { |tf| tf.draw }
    @text_descriptors.each_with_index { |td, idx| td.draw(100, 33 + idx * 50, 0) }
    @cursor.draw(mouse_x, mouse_y, 0)
    @save_message.draw(self.width/2-@save_message.width/2, 200, 0)
  end

  def button_down(id)
    if id == Gosu::KbTab then
      # Tab key will not be 'eaten' by text fields; use for switching through
      # text fields.
      index = @text_fields.index(self.text_input) || -1
      self.text_input = @text_fields[(index + 1) % @text_fields.size]
    elsif id == Gosu::KbEscape then
      # Escape key will not be 'eaten' by text fields; use for deselecting.
      if self.text_input then
        self.text_input = nil
      else
        save_and_close
      end
    elsif id == Gosu::MsLeft then
      # Mouse click: Select text field based on mouse position.
      self.text_input = @text_fields.find { |tf| tf.under_point?(mouse_x, mouse_y) }
      # Advanced: Move caret to clicked position
      self.text_input.move_caret(mouse_x) unless self.text_input.nil?
    end
  end

  private

  def save_and_close
    @config[:height] = @text_fields[0].text.to_i
    @config[:width] = @text_fields[1].text.to_i
    @config[:fullscreen] = @text_fields[2].text == "true"
    File.open('config/engine.yml', 'w+') {  |f| f.write(@config.to_yaml) }
    close
  end
end