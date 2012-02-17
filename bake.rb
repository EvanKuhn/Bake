#===============================================================================
# 'Bake' C++ build utility
#
# Evan Kuhn, 2012-01-31
#===============================================================================
require 'utility'

begin
  Bake::BakeUtility::run(ARGV.clone)
rescue => e
  print "ERROR: ", e.message, "\n"
end

exit
