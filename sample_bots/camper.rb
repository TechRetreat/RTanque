# Camper: Sample Bot
#
# Enjoys sitting in the corners and firing powerful shots
class Camper < RTanque::Bot::Brain
  include RTanque::Bot::BrainHelper

  def name
    'Camper'
  end

  def corners
    [:NE, :NE, :SE, :SW]
  end

  def turret_fire_range
    RTanque::Heading::ONE_DEGREE * 1.0
  end

  def switch_corner_tick_range
    (600..1000)
  end

  def tick!
    self.hide_in_corners
    if (target = self.nearest_target)
      self.fire_upon(target)
    else
      self.detect_targets
    end
  end

  def fire_upon(target)
    self.command.radar_heading = target.heading
    self.command.turret_heading = target.heading
    if self.sensors.turret_heading.delta(target.heading).abs < turret_fire_range
      self.command.fire(MAX_FIRE_POWER)
    end
  end

  def nearest_target
    self.sensors.radar.min { |a,b| a.distance <=> b.distance }
  end

  def detect_targets
    self.command.radar_heading = self.sensors.radar_heading + MAX_RADAR_ROTATION
    self.command.turret_heading = self.sensors.heading + RTanque::Heading::HALF_ANGLE
  end

  def hide_in_corners
    @corner_cycle ||= corners.shuffle.cycle
    if self.sensors.ticks % self.camp_interval == 0
      self.corner = @corner_cycle.next
      self.reset_camp_interval
    end
    self.corner ||= @corner_cycle.next
    self.move_to_corner
  end

  def move_to_corner
    if self.corner
      command.heading = self.sensors.position.heading(RTanque::Point.new(*self.corner, self.arena))
      command.speed = MAX_BOT_SPEED
    end
  end

  def corner=(corner_name)
    @corner = case corner_name
      when :NE
        [self.arena.width, self.arena.height]
      when :SE
        [self.arena.width, 0]
      when :SW
        [0, 0]
      else
        [0, self.arena.height]
    end
  end

  def corner
    @corner
  end

  def camp_interval
    @camp_interval ||= self.reset_camp_interval
  end

  def reset_camp_interval
    @camp_interval = rand(switch_corner_tick_range.max - switch_corner_tick_range.min) + switch_corner_tick_range.min
  end
end
