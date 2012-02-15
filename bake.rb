#===============================================================================
# 'Bake' C++ build utility
#
# Evan Kuhn, 2012-01-31
#===============================================================================
require 'commands'

begin
  # Get the command given by the user, or use the HelpCommand otherwise
  command_given = !ARGV.empty? && Bake::CommandRegistry.has?(ARGV[0])
  command = (command_given ? Bake::CommandRegistry.lookup(ARGV[0]) : Bake::HelpCommand.new)
  
  # Run the command
  command.run
rescue => e
  print "Error: ", e.message, "\n"
  exit
end

exit
