# this class builds levels by reading a YMAL file and populating the current space

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class Level
  TILE_SIZE = 80
  attr_accessor :gems
  attr_reader :start, :goal
  def initialize(window, load_file)
    @tileset = Gosu::Image.load_tiles(window, media_path("tilesets/plat_tiles.png"), TILE_SIZE, TILE_SIZE, true)

    gem_image = @tileset[18]
    #gem_image = Gosu::Image.new(window, media_path("gems/Gem Green.png"), false)
    @gems = []

    @config = YAML.load_file('config/level.yml')
    @start  = MyObj::Loc.new(window.width/2, window.height/2)
    @goal   = MyObj::Loc.new(0, 0)
    lines   = File.readlines(load_file).map { |line| line.chomp }
    @height = lines.size
    @width  = lines[0].size
    @tiles  = Array.new(@width) do |x|
      Array.new(@height) do |y|
        case lines[y][x, 1]
          when '#'
            { :tile => 7, :angle => 0.0 }
          when '^'
            { :tile => 2, :angle => 0.0 }
          when '>'
            { :tile => 2, :angle => 90.0 }
          when '<'
            { :tile => 2, :angle => -90.0 }
          when 'S'
            @start = MyObj::Loc.new(x*TILE_SIZE,y*TILE_SIZE)
            { :tile => 0, :angle => 0.0 }
          when 'G'
            @goal = MyObj::Loc.new(x*TILE_SIZE,y*TILE_SIZE)
            { :tile => 1, :angle => 0.0 }
          when 'x'
            @gems.push(Collectibles::Gem.new(gem_image,  x * TILE_SIZE + 7, y * TILE_SIZE + TILE_SIZE/2))
            nil
          else
            nil
        end
      end
    end

    def draw(camera)
      @height.times do |y|
        @width.times do |x|
          tile = @tiles[x][y]
          loc = MyObj::Loc.new(x * TILE_SIZE + 7, y * TILE_SIZE + TILE_SIZE/2)
          @tileset[tile[:tile]].draw_rot(*camera.world_to_screen(loc).to_a, ZOrder::Terrain, tile[:angle]) if tile
        end
      end
      @gems.each { |c| c.draw(camera) }
    end
  end

  def solid?(x, y)
    return false unless @tiles[x / TILE_SIZE][y / TILE_SIZE]
    [7,2].include?(@tiles[x / TILE_SIZE][y / TILE_SIZE][:tile])
  end

  def height
    @height * TILE_SIZE
  end

  def width
    @width * TILE_SIZE
  end
end