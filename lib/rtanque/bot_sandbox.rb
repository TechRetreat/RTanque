module RTanque
  class BotSandbox
    require 'shikashi'
    include Shikashi

    def initialize(code)
      @code = code
      @bot = nil
    end

    def bot
      if @bot
        @bot
      else
        sandbox = Sandbox.new
        privs = create_priviliges
        add_helpers sandbox.base_namespace
        bots = get_diff_in_object_space(RTanque::Bot::Brain) do
          sandbox.run privs, @code
        end
        if bots.length == 1
          @bot = bots[0]
        else
          fail LoadError, 'Could not load bot.'
        end
      end
    end

    protected

    def add_helpers(namespace)
      namespace.const_set :BOT_RADIUS, Bot::RADIUS
      namespace.const_set :MAX_FIRE_POWER, Bot::MAX_FIRE_POWER
      namespace.const_set :MIN_FIRE_POWER, Bot::MIN_FIRE_POWER
      namespace.const_set :MAX_HEALTH, Bot::MAX_HEALTH
      namespace.const_set :MAX_BOT_SPEED, Bot::MAX_SPEED
      namespace.const_set :MAX_BOT_ROTATION, Configuration.bot.turn_step
      namespace.const_set :MAX_TURRET_ROTATION, Configuration.turret.turn_step
      namespace.const_set :MAX_RADAR_ROTATION, Configuration.radar.turn_step
    end

    def create_priviliges
      privs = Privileges.new

      privs.allow_method :puts
      privs.allow_method :rand

      privs.object(RTanque::Heading).allow :new_from_degrees, :new_between_points, :delta_between_points, :rand, :new
      privs.object(RTanque::Point).allow :new, :rand, :distance

      privs.instances_of(Enumerator).allow_all
      privs.instances_of(Enumerable).allow_all
      privs.instances_of(Array).allow_all
      privs.instances_of(Hash).allow_all
      privs.instances_of(Fixnum).allow_all
      privs.instances_of(Float).allow_all
      privs.instances_of(String).allow_all
      privs.instances_of(Symbol).allow_all
      privs.instances_of(Range).allow_all

      privs.methods_of(Module).allow :include # Pretty sure include doesn't actually work in the sandbox anyway :/
      privs.methods_of(RTanque::Heading).allow_all
      privs.methods_of(RTanque::Bot::Brain).allow :command, :sensors, :arena
      privs.methods_of(RTanque::Bot::Command).allow :speed, :speed=, :heading, :heading=, :radar_heading,
                                                    :radar_heading=, :turret_heading, :turret_heading=, :fire_power,
                                                    :fire_power=, :fire
      privs.methods_of(RTanque::Bot::Sensors).allow :ticks, :health, :speed, :position, :heading, :radar, :radar_heading,
                                                    :turret_heading, :gun_energy
      privs.methods_of(RTanque::Arena).allow :width, :height
      privs.methods_of(RTanque::Point).allow :==, :within_radius?, :on_top_wall?, :on_bottom_wall?, :on_left_wall?,
                                             :on_right_wall?, :on_wall?, :outside_arena?, :move, :bind_to_arena,
                                             :heading, :distance
      privs.methods_of(RTanque::Bot::Radar::Reflection).allow :heading, :distance, :name

      all_constants privs, %w(RTanque RTanque::Bot::Brain RTanque::Bot::BrainHelper)
      all_constants privs, get_constants(RTanque::Heading)
      all_constants privs, get_constants(RTanque::Bot::BrainHelper)

      privs
    end

    def get_constants(klass)
      klass.constants.map { |const| "#{klass.name}::#{const}" }
    end

    def all_constants(privs, constants, type = 'read')
      constants.each { |const| privs.send("allow_const_#{type}", const) }
    end

    def get_diff_in_object_space(klass)
      current_object_space = self.get_descendants_of_class(klass)
      yield
      self.get_descendants_of_class(klass) - current_object_space
    end

    def get_descendants_of_class(klass)
      ::ObjectSpace.each_object(::Class).select {|k| k < klass }
    end
  end
end