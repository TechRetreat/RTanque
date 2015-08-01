module RTanque
  class Match
    attr_reader :arena, :bots, :shells, :explosions, :ticks, :max_ticks, :teams, :shell_id
    attr_accessor :recorder
    attr_writer :before_start, :after_tick, :after_stop, :shell_created, :shell_destroyed, :after_death

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
      @shell_id = 0
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
        shell = RTanque::Shell.new(bot, shell_position, bot.turret.heading.clone, bot.fire_power, @shell_id)
        @shells.add(shell)
        @shell_created.call(shell) if @shell_created
        @shell_id +=1
      end
    end

    def pre_shell_tick(shell)
      shell.hits(self.bots.all_but(shell.bot)) do |origin_bot, bot_hit|
        damage = (shell.fire_power**RTanque::Shell::RATIO)
        bot_hit.reduce_health(damage, shell.bot)
        @shell_destroyed.call(shell) if @shell_destroyed
        if bot_hit.dead?
          @explosions.add(Explosion.new(bot_hit.position))
        end
      end
    end

    def tick
      self.shells.tick
      self.bots.each { |tank| @after_death.call(tank, self) if tank.dead? && @after_death }
      self.bots.tick
      self.explosions.tick
      @after_tick.call(self) if @after_tick
      @ticks += 1
    end
  end
end
