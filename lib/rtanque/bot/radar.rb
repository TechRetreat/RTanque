module RTanque
  class Bot
    class Radar
      include Enumerable
      include Movable
      extend NormalizedAttr
      VISION_RANGE = Configuration.radar.vision
      attr_normalized(:heading, Heading::FULL_RANGE, Configuration.radar.turn_step)

      # A Reflection is the information obtained for a bot detected by {RTanque::Bot::Radar}
      #
      # @attr_reader [RTanque::Heading] heading
      # @attr_reader [Float] distance
      # @attr_reader [String] name
      # @attr_reader [Float] enemy_health
      # @attr_reader [RTanque::Heading] enemy_heading
      # @attr_reader [Float] enemy_speed

      Reflection = Struct.new(:heading, :distance, :enemy_health, :enemy_heading, :enemy_speed, :enemy_name) do
        def self.new_from_points(from_position, enemy)
          self.new(from_position.heading(enemy.position), from_position.distance(enemy.position), enemy.health, enemy.heading, enemy.speed, enemy.name)
        end
      end

      def initialize(bot, heading)
        @bot = bot
        @heading = heading
        @reflections = []
      end

      def position
        @bot.position
      end

      def each(&block)
        @reflections.each(&block)
      end

      def empty?
        self.count == 0
      end

      def scan(bots)
        @reflections.clear
        bots.each do |other_bot|
          if self.can_detect?(other_bot)
            @reflections << Reflection.new_from_points(self.position, other_bot)
          end
        end
        self
      end

      def can_detect?(other_bot)
        VISION_RANGE.include?(Heading.delta_between_points(self.position, self.heading, other_bot.position))
      end
    end
  end
end