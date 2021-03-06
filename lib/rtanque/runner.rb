require 'ruby-prof'
# Add the working directory so that loading of bots works as expected
$LOAD_PATH << Dir.pwd
# Add the gem root dir so that sample_bots can be loaded
$LOAD_PATH << File.expand_path('../../../', __FILE__)

module RTanque
  # Runner manages running an {RTanque::Match}
  class Runner
    LoadError = Class.new(::LoadError)
    attr_reader :match

    # @param [Integer] width
    # @param [Integer] height
    # @param [*match_args] args provided to {RTanque::Match#initialize}
    def initialize(width, height, *match_args)
      @match = RTanque::Match.new(RTanque::Arena.new(width, height), *match_args)
    end

    # Attempts to load given {RTanque::Bot::Brain} given its path
    # @param [String] brain_path
    # @raise [RTanque::Runner::LoadError] if brain could not be loaded
    def add_brain_path(brain_path, name = nil, sandbox: false)
      parsed_path = self.parse_brain_path(brain_path)
      relative_path = File.expand_path parsed_path.path, File.expand_path('../../../', __FILE__)

      if File.exists? parsed_path.path
        path = parsed_path.path
      elsif File.exists? relative_path
        path = relative_path
      else
        fail LoadError, "Could not find file #{parsed_path.path}"
      end

      code = File.read path
      add_brain_code code, parsed_path.multiplier, name, sandbox
    end

    def add_brain_code(code, num_bots = 1, name = nil, sandbox = false)
      brains = num_bots.times.map do
        begin
          BotSandbox.new(code, sandbox).bot
        rescue ::LoadError
          raise LoadError, 'Failed to load bot from code.'
        end
      end
      bots = brains.map { |klass| RTanque::Bot.new_random_location(self.match.arena, klass, name) }
      self.match.add_bots(bots)
      bots
    end

    # Starts the match
    # @param [Boolean] gui if false, runs headless match
    def start(profile = false)
        if profile
          RubyProf.measure_mode = RubyProf::PROCESS_TIME
          RubyProf.start
        end
        # RubyProf.pause
        trap(:INT) { self.match.stop }
        self.match.start
        if profile
          result = RubyProf.stop
          printer = RubyProf::FlatPrinterWithLineNumbers.new(result)
          printer.print(STDOUT)
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
