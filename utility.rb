#===============================================================================
# The BakeUtility object encapsulates the high-level logic and runs commands.
#
# Evan Kuhn, 2012-02-16
#===============================================================================
require 'commands'

module Bake
  
  class BakeUtility
    # Get usage for the Bake utility
    def self.usage
      return HelpCommand::bake_usage
    end
    
    # Run the utility
    def self.run(args)
      help = false
      
      # Remove any options before the command name
      while !args.empty? && args.first.start_with?('-') do
        op = args.shift
        if op == '-h' || op == '--help'
          # If the help option is given, get rid of the rest of the arguments so
          # the help command gives help for the Bake utility
          help = true
          args.clear
        else
          raise "Invalid option #{op}"
        end
      end

      if help || args.empty?
        # Print usage
        puts usage
      elsif !Bake::CommandRegistry.has? args.first
        # Print usage plus an error message
        puts usage
        puts "ERROR: Invalid command '#{args.first}'"
      else
        # Get and run the command
        command = Bake::CommandRegistry.lookup args.first
        args.shift
        command.run(args)
      end
    rescue => e
      print "ERROR: ", e.message, "\n"
      exit
    end
  end

end # module Bake
