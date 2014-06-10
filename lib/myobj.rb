# this is a collection of objects that I need
module MyObj
  # this creates a location tuple for easy location passing
  class Loc
    attr_accessor :x, :y
    def initialize(x, y)
      @x = x.to_f, @y = y.to_f
    end
  end

end
