#this just defines how deep things 
# are placed in the background
module ZOrder
  Background, Terrain, NPC, PlayerEffects, Player, HUD, Cursor = *0..6
end

module Tiles
  Start, Goal, Spike = *0..2
  Stone = 10
  Gem = 18
  Checkpoint = 35
  BkgTile = 9
  Blank = 6
end


