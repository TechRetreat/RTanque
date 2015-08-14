require 'configuration'

module RTanque
  one_degree = (Math::PI / 180.0)
  speed_factor = 2

  # @!visibility private
  Configuration = ::Configuration.for('default') do
    raise_brain_tick_errors false
    quit_when_finished true
    tick_timeout 0.01 * speed_factor

    bot do
      radius 19
      health_reduction_on_exception 4
      health_reduction_on_collision 10
      health 0..100
      speed -3 * speed_factor..3 * speed_factor
      speed_step 0.05 * speed_factor
      turn_step one_degree * 1.5 * speed_factor
      fire_power 1..5
      gun_energy_max 10
      gun_energy_factor 15
      gun_recharge 1 * speed_factor
    end
    turret do
      length 28
      turn_step (one_degree * 2.0) * speed_factor
    end
    radar do
      turn_step 0.05 * speed_factor
      vision -(one_degree * 10.0)..(one_degree * 10.0)
    end
    shell do
      speed_factor 4.5 * speed_factor
      ratio 1.5 # used by Bot#adjust_fire_power and to calculate damage done by shell to bot
    end
    explosion do
      life_span 70 * 1 / speed_factor # should be multiple of the number of frames in the explosion animation
    end
  end
  def Configuration.config(&block)
    ::Configuration::DSL.evaluate(self, &block)
  end
end
