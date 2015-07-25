module RTanque
  class Match
    attr_reader :arena, :bots, :shells, :explosions, :ticks, :max_ticks, :teams, :tick_data_array
    attr_accessor :recorder
    attr_writer :before_start, :after_tick, :after_stop

    def initialize(arena, max_ticks = nil, teams = false)
      @arena = arena
      @max_ticks = max_ticks
      @teams = teams
      @ticks = 0
      @shells = TickGroup.new
      @bots = TickGroup.new
      @explosions = TickGroup.new
      @bots.pre_tick(&method(:pre_bot_tick))
      @bots.post_tick(&method(:post_bot_tick))
      @shells.pre_tick(&method(:pre_shell_tick))
      @stopped = false
      @tick_data_array = Array.new
    end

    def teams=(bool)
      @teams = bool
    end

    def max_ticks_reached?
      self.max_ticks && self.ticks >= self.max_ticks
    end

    def finished?
      @stopped || self.max_ticks_reached? || self.bots.count <= 1 ||
        (self.teams && self.bots.map(&:name).uniq.size == 1)
    end

    def add_bots(*bots)
      self.bots.add(*bots)
    end

    def start
      @before_start.call(self) if @before_start
      self.tick until self.finished?
      @after_stop.call(self) if @after_stop
      recorder.stop if recorder
    end

    def stop
      @stopped = true
    end

    def pre_bot_tick(bot)
      bot.radar.scan(self.bots.all_but(bot))
    end

    def post_bot_tick(bot)
      if bot.firing?
        # shell starts life at the end of the turret
        shell_position = bot.position.move(bot.turret.heading, RTanque::Bot::Turret::LENGTH)
        @shells.add(RTanque::Shell.new(bot, shell_position, bot.turret.heading.clone, bot.fire_power))
      end
    end

    def pre_shell_tick(shell)
      shell.hits(self.bots.all_but(shell.bot)) do |origin_bot, bot_hit|
        damage = (shell.fire_power**RTanque::Shell::RATIO)
        bot_hit.reduce_health(damage)
        if bot_hit.dead?
          @explosions.add(Explosion.new(bot_hit.position))
        end
      end
    end

    def getTankData
      bot_array = Array.new
      @bots.each { |bot|
        bot_array.push name: bot.name, x: bot.position.x, y: bot.position.y, health: bot.health, heading: bot.heading.to_f,
                       turret_heading: bot.radar.heading.to_f, radar_heading: bot.turret.heading.to_f
      }
      return bot_array
    end

    def getShellsCreated
      created = Array.new
      @shells.each { |shell|
        created.push id: "test"
      }
      return created
    end

    def getShellsDestroyed
      destroyed = Array.new
      @shells.each { |shell|
        destroyed.push id: "test"
      }
      return destroyed
    end

    def write_data
      @tick_data_array.push tick: @ticks, tanks: getTankData, created: getShellsCreated, destroyed: getShellsDestroyed

      if @ticks % 5 == 4
        File.open("testing/last-match-test" + @ticks.to_s + ".txt",'w') do |file|
          file.puts(@tick_data_array.to_s)
        end
        @tick_data_array = Array.new
      end
    end

    def tick
      self.shells.tick
      self.bots.tick
      self.explosions.tick
      @after_tick.call(self) if @after_tick
      write_data
      @ticks += 1
    end
  end
end
