# this class builds levels by reading a YMAL file and populating the current space

def media_path(file)
  File.expand_path "../media/#{file}", File.dirname(__FILE__)
end

class Level
  TILE_SIZE = 100
  def initialize(window, load_file)
    @tileset = [Gosu::Image.new(window, media_path("blocks/Plain Block.png"), true)]

    gem_image = Gosu::Image.new(window, media_path("gems/Gem Green.png"), false)
    @gems = []

    @config = YAML.load_file('config/level.yml')
    level   = File.readlines(load_file).map { |line| line.chomp }
    @height = @config[:height]/TILE_SIZE
    @width  = @config[:width]/TILE_SIZE
    @tiles  = Array.new(@width) do |x|
      Array.new(@height) do |y|
        case level [y][x, 1]
          when '#'
            0
          when 'x'
            @gems.push(Collectibles::Gem.new(gem_image,  x * 100 + 25, y * 100 + 25))
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
          loc = MyObj::Loc.new(x * 100 - 5, y * 85 - 5)
          @tileset[tile].draw_rot(*camera.world_to_screen(loc).to_a, ZOrder::Terrain, 0.0) if tile
        end
      end
      @gems.each { |c| c.draw(camera) }
    end
  end

  def solid?(x, y)
    y < 0 || @tiles[x / 50][y / 50]
  end
end