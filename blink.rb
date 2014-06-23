require './lib/engine.rb'
require './lib/home.rb'
require './lib/settingswindow.rb'


home_window = HomeWindow.new
home_window.show
home_window.flush

exit if home_window.exit

case home_window.next_window
  when :settings
    settings_window = SettingsWindow.new
    settings_window.show
    settings_window.flush
  when :game
    game_window = GameWindow.new
    game_window.show
    game_window.flush
end