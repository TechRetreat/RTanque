# Add the working directory so that loading of bots works as expected
$LOAD_PATH << Dir.pwd
# Add the gem root dir so that sample_bots can be loaded
$LOAD_PATH << File.expand_path('../../../', __FILE__)

module RTanque
  # Runner manages running an {RTanque::Match}
  class Runner
    LoadError = Class.new(::LoadError)
    attr_reader :match
    attr_accessor :recorder, :replayer

    # @param [Integer] width
    # @param [Integer] height
    # @param [*match_args] args provided to {RTanque::Match#initialize}
    def initialize(width, height, *match_args)
      @match = RTanque::Match.new(RTanque::Arena.new(width, height), *match_args)
    end

    # Attempts to load given {RTanque::Bot::Brain} given its path
    # @param [String] brain_path
    # @raise [RTanque::Runner::LoadError] if brain could not be loaded
    def add_brain_path(brain_path)
      parsed_path = self.parse_brain_path(brain_path)
      fail LoadError unless File.exists? parsed_path.path
      File.open parsed_path.path, 'r' do |file|
        code = file.read
        add_brain_code code, parsed_path.multiplier
      end
    end

    def add_brain_code(code, num_bots = 1)
      brains = num_bots.times.map do
        begin
          BotSandbox.new(code).bot
        rescue ::LoadError
          raise LoadError, 'Failed to load bot from code.'
        end
      end
      bots = brains.map { |klass| RTanque::Bot.new_random_location(self.match.arena, klass) }
      self.recorder.add_bots(bots) if recording?
      self.match.add_bots(bots)
    end

    # Starts the match
    # @param [Boolean] gui if false, runs headless match
    def start(gui = true)
      if gui
        require 'rtanque/gui'
        window = RTanque::Gui::Window.new(self.match)
        trap(:INT) { window.close }
        window.show
      else
        trap(:INT) { self.match.stop }
        self.match.start
      end
    end

    def recording?
      !self.recorder.nil?
    end

    protected

    BRAIN_PATH_PARSER = /\A(.+?)\:[x|X](\d+)\z/
    # @!visibility private
    ParsedBrainPath = Struct.new(:path, :multiplier)
    def parse_brain_path(brain_path)
      path = brain_path.gsub('\.rb$', '')
      multiplier = 1
      brain_path.match(BRAIN_PATH_PARSER) { |m|
        path = m[1]
        multiplier = m[2].to_i
      }
      ParsedBrainPath.new(path, multiplier)
    end
  end
end
