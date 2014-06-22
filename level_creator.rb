require './lib/engine.rb'
require './lib/home.rb'

loop do
  home_window = HomeWindow.new
  home_window.show
  home_window.close
  break if home_window.exit

  game_window = GameWindow.new
  game_window.show
  game_window.close
end

#game_window = GameWindow.new
#game_window.show
#game_window.close

