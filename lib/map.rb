# map generator that reads in a yaml file
#   far moe extensible than a text file

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class Map
  TILE_SIZE = 80
  attr_accessor :gems
  attr_reader :start, :goal
  def initialize(window, level_name)
    @tileset = Gosu::Image.load_tiles(window, media_path("tilesets/plat_tiles.png"), TILE_SIZE, TILE_SIZE, true)
    @gem_image = @tileset[Tiles::Gem]
    @gems = []
    @background_tiles = []

    @file = media_path("levels/#{level_name}.yml")
    @map = File.file?(@file) ? YAML.load_file(@file) : new_level
    @start  = MyObj::Loc.new(@map[:start][:x] * TILE_SIZE, @map[:start][:y] * TILE_SIZE)
    @goal   = MyObj::Loc.new(@map[:goal][:x] * TILE_SIZE, @map[:goal][:y] * TILE_SIZE)
    @tiles  = Array.new(@map[:width]) { |x| Array.new(@map[:height]) { |y| nil } }
    @map[:tiles].each do |tile|
      @tiles[tile[:x]][tile[:y]] = tile
    end

    @map[:gems].each { |gem| @gems.push(Collectibles::Gem.new(@gem_image,  gem[:x], gem[:y])) } if @map[:gems]
    @gem_timeout = 0
  end

  def draw(camera)
    @map[:height].times do |y|
      @map[:width].times do |x|
        tile = @tiles[x][y]
        loc = MyObj::Loc.new(x * TILE_SIZE + 7, y * TILE_SIZE + TILE_SIZE/2)
        @tileset[tile[:tile]].draw_rot(*camera.world_to_screen(loc).to_a, ZOrder::Terrain, tile[:angle]) if tile
      end
    end
    @gems.each { |c| c.draw(camera) }
  end

  def solid?(x, y)
    return false unless @tiles[x / TILE_SIZE][y / TILE_SIZE]
    [Tiles::Stone].include?(@tiles[x / TILE_SIZE][y / TILE_SIZE][:tile])
  end

  def tile_instant_death?(x, y)
    if @tiles[x / TILE_SIZE][y / TILE_SIZE]
      [Tiles::Spike].include?(@tiles[x / TILE_SIZE][y / TILE_SIZE][:tile])
    end
  end

  def height
    @map[:height] * TILE_SIZE
  end

  def width
    @map[:width] * TILE_SIZE
  end

  def create_block(camera, loc, block, angle = 0.0)
    x, y = *camera.screen_to_world(loc).to_a
    if block == Tiles::Gem
      if (Gosu::milliseconds - @gem_timeout) > 200
        @gems.push(Collectibles::Gem.new(@gem_image, x - 25, y))
        @gem_timeout = Gosu::milliseconds
      end
    else
      @tiles[x / TILE_SIZE][y / TILE_SIZE] = { :x => x.to_i / TILE_SIZE, :y => y.to_i / TILE_SIZE, :tile => block, :angle => angle }
    end

    if block == Tiles::Start
      @map[:start][:x] = x.floor / TILE_SIZE
      @map[:start][:y] = y.floor / TILE_SIZE
    elsif block == Tiles::Goal
      @map[:goal][:x] = x.floor / TILE_SIZE
      @map[:goal][:y] = y.floor / TILE_SIZE
    end
  end

  def delete_block(camera, loc)
    x, y = *camera.screen_to_world(loc).to_a
    @tiles[x / TILE_SIZE][y / TILE_SIZE] = nil
  end

  def save
    @map[:tiles] = []

    @map[:height].times do |y|
      @map[:width].times do |x|
        if @tiles[x][y]
          @map[:tiles].push(@tiles[x][y])
        end
      end
    end

    @map[:gems] = []
    @gems.each do |gem|
      @map[:gems].push({:x => gem.loc.x, :y => gem.loc.y})
    end

    File.open(@file, 'w+') {  |f| f.write(@map.to_yaml) }
  end

  private

  def new_level
    {
        :width => 50,
        :height => 50,
        :start => {
            :x => 1,
            :y => 1
        },
        :goal => {
            :x => 50,
            :y => 50
        },
        :tiles => [],
        :gems => []
    }
  end
end