module RTanque
  class Bot
    # Commands the associated {RTanque::Bot}. This class should be inherited from and {NAME} and {#tick!} overridden.
    #
    # See {RTanque::Bot::BrainHelper} for a useful mixin
    #
    # Sample bots:
    #
    #  * {file:sample_bots/seek_and_destroy.rb SeekAndDestroy}
    #  * {file:sample_bots/camper.rb Camper}
    #  * {file:sample_bots/keyboard.rb Keyboard} Special bot controlled by the keyboard
    #
    class Brain
      # Bot's display name
      # @!parse NAME = 'bot name'

      # @!attribute [r] sensors
      #   @return [RTanque::Bot::Sensors]
      # @!attribute [r] command
      #   @return [RTanque::Bot::Command]
      attr_accessor :sensors, :command
      # @return [RTanque::Arena]
      attr_reader :arena

      # @!visibility private
      def initialize(arena, logger = nil)
        @arena = arena
        @logger = logger
      end

      # @!visibility private
      def tick(sensors)
        self.sensors = sensors
        RTanque::Bot::Command.new.tap do |empty_command|
          self.command = empty_command
          self.tick!
        end
      end

      # Main logic goes here
      #
      # Get input from {#sensors}. See {RTanque::Bot::Sensors}
      #
      # Give output to {#command}. See {RTanque::Bot::Command}
      # @abstract
      def tick!
        # Sweet bot logic
      end

      # Run block every 'num_of_ticks'
      # @param [Integer] num_of_ticks tick interval at which to execute block
      # @yield
      # @return [void]
      def at_tick_interval(num_of_ticks)
        yield if @ticks % num_of_ticks == 0
      end

      def puts(msg)
        @logger.call msg if @logger
      end
    end
  end
end
