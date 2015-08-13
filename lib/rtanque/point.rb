module RTanque
  Point = Struct.new(:x, :y, :arena, :width) do
    def initialize(*args, &block)
      super
      self.width ||= 0
      block.call(self) if block
    end

    def self.rand(arena, width = 0)
      self.new(Kernel.rand(arena.width), Kernel.rand(arena.height), arena, width)
    end

    def self.distance(a, b)
      Math.hypot(a.x - b.x, a.y - b.y)
    end

    def ==(other_point)
      self.x == other_point.x && self.y == other_point.y
    end

    def within_radius?(other_point, radius)
      self.distance(other_point) <= radius
    end

    def on_top_wall?
      self.y >= self.arena.height - self.width
    end

    def on_bottom_wall?
      self.y <= 0 + self.width
    end

    def on_left_wall?
      self.x <= 0 + self.width
    end

    def on_right_wall?
      self.x >= self.arena.width - self.width
    end

    def on_wall?
      self.on_top_wall? || self.on_bottom_wall? || self.on_right_wall? || self.on_left_wall?
    end

    def outside_arena?
      self.y > self.arena.height - self.width || self.y < 0 + self.width || self.x > self.arena.width - self.width || self.x < 0 + self.width
    end

    def move(heading, speed, bound_to_arena = true, width = self.width)
      # round to avoid floating point errors
      self.x = (self.x + (Math.sin(heading) * speed)).round(10)
      self.y = (self.y + (Math.cos(heading) * speed)).round(10)
      if bound_to_arena
        bind_to_arena(width)
      end
    end

    def bind_to_arena(width = self.width)
      if self.x < width
        self.x = width
      elsif self.x > self.arena.width - width
        self.x = self.arena.width.to_f - width
      end
      if self.y < width
        self.y = width
      elsif self.y > self.arena.height - width
        self.y = self.arena.height.to_f - width
      end
    end

    def heading(other_point)
      Heading.new_between_points(self, other_point)
    end

    def distance(other_point)
      self.class.distance(self, other_point)
    end
  end
end
