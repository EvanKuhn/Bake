#===============================================================================
# 'Bake' C++ build utility
#
# Evan Kuhn, 2012-01-31
#===============================================================================
require 'utils'
require 'project'
require 'cmdline'
require 'compiler'

print "Bake: A Better C++ Build Utility\n\n"

# Parse the command-line inputs
cmdline = CmdLine.new
begin
  cmdline.parse
rescue => e
  print "Error: ", e.message, "\n"
  exit
end

# Check if .bake file exists in the current directory
if(!File.exist? ".bake")
  if(cmdline.easy?)
    print 'Compiling local files into '
    case cmdline.type
    when ProjectType::APP
      print 'an executable'
    when ProjectType::LIB
      print 'a static library'
    when ProjectType::DLL
      print 'a shared library'
    end
    puts " named '" + cmdline.outfile + "'"

    # Get all C++ files
    files = Utils.get_source_files
    
    # Create a project
    project = Project.new
    project.name = cmdline.name
    project.type = cmdline.type
    project.files = files
    
    # Build everything
    comp = Compiler.new
    comp.verbose = cmdline.verbose?
    comp.build(project)
    
  else
    puts 'No .bake file found'
  end

# Parse the .bake file
else
  print "Found .bake file\n"

  #TODO - parse .bake file, build whatever projects we should
end









