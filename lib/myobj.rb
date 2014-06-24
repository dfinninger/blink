# this is a collection of objects that I need
module MyObj
  # this creates a location tuple for easy location passing
  class Loc
    attr_accessor :x, :y

    def initialize(x = 0, y = 0)
      @x = x.to_f
      @y = y.to_f
    end

    def +(b)
      result = dup
      result.x += b.x
      result.y += b.y
      result
    end
    def -(b)
      result = dup
      result.x -= b.x
      result.y -= b.y
      result
    end
    def <=(b)
      result = dup
      j = result.x.abs <= b.x.abs
      k = result.y.abs <= b.y.abs
      j and k
    end
    def *(b)
      raise ArgumentError unless b.respond_to?(:to_f)
      result = dup
      result.x *= b
      result.y *= b
      result
    end

    def to_a
      [@x, @y]
    end
  end
  
  class LevelBox
    attr_reader :left, :right, :top, :bot
    def initialize(left, right, top, bot)
      @left = left
      @right = right
      @top = top
      @bot = bot
    end
  end

end
