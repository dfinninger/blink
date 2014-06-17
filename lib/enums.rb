#this just defines how deep things 
# are placed in the background
module ZOrder
  Background, Terrain, NPC, Player, HUD, Cursor = *0..5
end

module Tiles
  Start, Goal, Spike = *0..2
  Stone = 10
  Gem = 18
end


