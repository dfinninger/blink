# this class builds levels by reading a YMAL file and populating the current space

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class Level
  TILE_SIZE = 80
  def initialize(window, load_file)
    @tileset = Gosu::Image.load_tiles(window, media_path("tilesets/plat_tiles.png"), TILE_SIZE, TILE_SIZE, true)

    gem_image = @tileset[19]
    #gem_image = Gosu::Image.new(window, media_path("gems/Gem Green.png"), false)
    @gems = []

    @config = YAML.load_file('config/level.yml')
    lines   = File.readlines(load_file).map { |line| line.chomp }
    @height = lines.size
    @width  = lines[0].size
    @tiles  = Array.new(@width) do |x|
      Array.new(@height) do |y|
        case lines[y][x, 1]
          when '#'
            7
          when 'x'
            @gems.push(Collectibles::Gem.new(gem_image,  x * TILE_SIZE + 25, y * TILE_SIZE + 25))
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
          loc = MyObj::Loc.new(x * TILE_SIZE + 25, y * TILE_SIZE + 25)
          @tileset[tile].draw_rot(*camera.world_to_screen(loc).to_a, ZOrder::Terrain, 0.0) if tile
        end
      end
      @gems.each { |c| c.draw(camera) }
    end
  end

  def solid?(x, y)
    y < 0 || @tiles[x / TILE_SIZE][y / TILE_SIZE]
  end
end