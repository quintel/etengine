module Gql::Grammar
  # Used for GQL console
  class Console
    include ::Rubel::Core
    
    include ::Gql::Grammar::Functions::Legacy
    include ::Gql::Grammar::Functions::Constants
    include ::Gql::Grammar::Functions::Traversal
    include ::Gql::Grammar::Functions::Aggregate
    include ::Gql::Grammar::Functions::Control
    include ::Gql::Grammar::Functions::Lookup
    include ::Gql::Grammar::Functions::Policy
    include ::Gql::Grammar::Functions::Update
    include ::Gql::Grammar::Functions::Helper
    include ::Gql::Grammar::Functions::Core
    
    # A Pry prompt that logs what user enters to a log file
    # so it can easily be copy pasted by users.
    #
    # DOES NOT WORK :( couldn't make it work 
    class LoggingPrompt
      include Readline

      def readline(prompt = "GQL: ", add_hist = true)
        @logger ||= Logger.new('gqlconsole/prompt.log', 'daily')
        super(prompt, add_hist).tap do |line| 
          @logger.info(line)
        end
      end
    end

    # Prints string directly
    RESULT_PRINTER = proc do |output, value|
      if value.is_a?(String)
        output.puts value
      else
        Pry::DEFAULT_PRINT.call(output, value)
      end
    end

    # Starts the Pry console
    def console
      enable_code_completion
      puts "** Console Loaded"
      Pry.start(self, 
                # input: LoggingPrompt.new, 
                prompt: proc { |_, nest_level| "GQL: " },
                print:  RESULT_PRINTER)
    end

    # code completion is for the gql console.
    # it adds converter and gquery keys as methods,
    # so that PRY code completion picks it up. 
    #
    # The methods return the key as a symbol, which is
    # the same behaviour as with method_missing.
    #
    # There might be a better way of doing this by hooking
    # them up to some Pry code_completion commands.
    #
    def enable_code_completion
      self.class.enable_code_completion(self)
    end

    def self.enable_code_completion(rubel_base)
      # first create the foo, bar methods
      define_method :foo do rubel_base.ALL().first; end
      define_method :bar do rubel_base.ALL().second; end

      keys = [
        rubel_base.ALL().map(&:full_key),
        Gquery.all.map(&:key),
      ].flatten.
        map(&:to_sym) # really make sure keys are symbols

      keys.each do |key|
        define_method key do
          key
        end
      end
    end
  end
end