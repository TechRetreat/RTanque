#Example code
class Haha < RTanque::Bot::Brain
  def tick!
    make_circles
    command.fire 0.25
  end

  def make_circles
    command.speed = RTanque::Bot::BrainHelper::MAX_BOT_SPEED
    command.heading = sensors.heading + RTanque::Heading.new_from_degrees(85)
    command.turret_heading = sensors.turret_heading - RTanque::Heading.new_from_degrees(35)
  end
end