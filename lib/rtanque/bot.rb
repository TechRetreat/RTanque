module RTanque
  class Bot
    require 'timeout'

    include Movable
    extend NormalizedAttr
    HEALTH_REDUCTION_ON_EXCEPTION = Configuration.bot.health_reduction_on_exception
    RADIUS = Configuration.bot.radius
    GUN_RECHARGE = Configuration.bot.gun_recharge
    MAX_GUN_ENERGY = Configuration.bot.gun_energy_max
    GUN_ENERGY_FACTOR = Configuration.bot.gun_energy_factor
    attr_reader :arena, :brain, :radar, :turret, :ticks, :health, :fire_power, :gun_energy, :killer, :logs, :error, :width
    attr_normalized(:speed, Configuration.bot.speed, Configuration.bot.speed_step)
    attr_normalized(:heading, Heading::FULL_RANGE, Configuration.bot.turn_step)
    attr_normalized(:fire_power, Configuration.bot.fire_power)
    attr_normalized(:health, Configuration.bot.health)

    def self.new_random_location(*args)
      self.new(*args).tap do |bot|
        rand_heading = Heading.rand
        bot.position = Point.rand(bot.arena, RADIUS)
        bot.heading = rand_heading
        bot.radar.heading = rand_heading
        bot.turret.heading = rand_heading
      end
    end

    def initialize(arena, brain_klass = Brain, name = nil)
      @arena = arena
      @brain = brain_klass.new(self.arena, method(:log))
      @ticks = 0
      @name = name
      @width = RADIUS
      self.health = self.class::MAX_HEALTH
      self.speed = 0
      self.fire_power = nil
      self.heading = Heading.new
      self.position = Point.new(0, 0, self.arena, @width)
      @radar = Radar.new(self, self.heading.clone)
      @turret = Turret.new(self.heading.clone)
    end

    def name
      @name ||= self.brain.respond_to?(:name) ? self.brain.name : nil
      @name ||= self.brain.class.const_defined?(:NAME) ? self.brain.class.const_get(:NAME) : [self.brain.class.name, self.object_id].join(':')
    end

    def health=(val)
      @health = val
    end

    def fire_power=(power)
      @fire_power = power || 0
    end

    def adjust_fire_power
      @gun_energy ||= MAX_GUN_ENERGY
      if @gun_energy <= 0
        self.fire_power = 0
      else
        @gun_energy -= (self.fire_power**RTanque::Shell::RATIO) * GUN_ENERGY_FACTOR
      end
      @gun_energy += GUN_RECHARGE
      @gun_energy = MAX_GUN_ENERGY if @gun_energy > MAX_GUN_ENERGY
    end

    def firing?
      self.fire_power && self.fire_power > 0
    end

    def reduce_health(reduce_by, cause = nil)
      self.health -= reduce_by
      @killer = cause if self.dead?
    end

    def dead?
      self.health <= self.class::MIN_HEALTH
    end

    def tick
      @error = nil
      @logs = []
      @ticks += 1
      self.tick_brain
      self.adjust_fire_power
      super
    end

    def tick_brain
      begin
        Timeout::timeout(Configuration.tick_timeout) do
          self.execute_command self.brain.tick(self.sensors)
        end
      rescue Exception => brain_error
        @error = brain_error
        @logs ||= []
        if Configuration.raise_brain_tick_errors
          raise brain_error
        else
          self.reduce_health(HEALTH_REDUCTION_ON_EXCEPTION)
        end
      end
    end

    def execute_command(command)
      self.fire_power = self.normalize_fire_power(self.fire_power, command.fire_power)
      self.speed = self.normalize_speed(self.speed, command.speed)
      self.heading = self.normalize_heading(self.heading, command.heading)
      self.radar.heading = self.radar.normalize_heading(self.radar.heading, command.radar_heading)
      self.turret.heading = self.turret.normalize_heading(self.turret.heading, command.turret_heading)
    end

    def sensors
      Sensors.new do |sensors|
        sensors.ticks = self.ticks
        sensors.health = self.health
        sensors.speed = self.speed
        sensors.position = self.position
        sensors.heading = self.heading
        sensors.radar = self.radar.to_enum
        sensors.radar_heading = self.radar.heading
        sensors.gun_energy = self.gun_energy
        sensors.turret_heading = self.turret.heading
      end
    end

    def to_command
      RTanque::Bot::Command.new.tap do |empty_command|
        empty_command.fire_power = self.fire_power
        empty_command.speed = self.speed
        empty_command.heading = self.heading
        empty_command.radar_heading = self.radar.heading
        empty_command.turret_heading = self.turret.heading
      end
    end

    def log(message)
      @logs << message
    end
  end
end
