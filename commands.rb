#===============================================================================
# A set of Bake utility commands
# 
# Evan Kuhn, 2012-02-05
#===============================================================================
require 'compiler'
require 'project'
require 'utils'

module Bake
  
  #=============================================================================
  # The CommandRegistry contains a single instance of each command
  #=============================================================================
  class CommandRegistry
    @@commands = {}
    
    # Add a command to the registry
    def self.insert(command)
      @@commands[command.name] = command
    end

    # Get all commands, sorted by name
    def self.commands
      return @@commands.values.sort! { |a,b| a.name <=> b.name }
    end

    # Look up a command by name (case-insensitive). Returns nil if not found
    def self.lookup(name)
      return @@commands[name.downcase]
    end

    # Does the registry contain the given command?
    def self.has?(name)
      return @@commands.has_key?(name.downcase)
    end
  end
  
  #=============================================================================
  # Base class for all commands. Each command contains a name and a description.
  #=============================================================================
  class Command
    attr_accessor :name, :desc
    def initialize(name, desc)
      @name = name.downcase
      @desc = desc
    end
  end

  #=============================================================================
  # The 'build' command builds all projects defined the .bake file
  #=============================================================================
  class BuildCommand < Command
    # Set up the name and description, and add to the CommandRegistry
    def initialize
      super("build", "Build projects defined in the .bake file in the current dir")
    end
    CommandRegistry.insert BuildCommand.new

    # Get usage info
    def usage
      s  = "\n"
      s += "  ABOUT\n"
      s += "    The 'build' command parses the .bake file in the current directory and\n"
      s += "    builds the project or system named by the user.\n"
      s += "\n"
      s += "  USAGE\n"
      s += "    bake build <project|system> <name>\n"
      s += "\n"
      return s
    end
    
    # Run the command
    def run
      # Get and check params
      raise "Missing <project|system> param. See 'bake help build'." if(ARGV.length < 2)
      raise "Missing <name> param. See 'bake help build'."           if(ARGV.length < 3) 

      type = ARGV[1].downcase
      name = ARGV[2]

      if(type != 'project' && type != 'system')
        raise "Invalid <project|system> value. See 'bake help build'."
      end

      puts "Building #{type} '#{name}'"
      # TODO
    end
  end

  #=============================================================================
  # The 'easy' command builds all C++ files in the current directory
  #=============================================================================
  class EasyCommand < Command
    # Set up the name and description, and add to the CommandRegistry
    def initialize
      super("easy", "Build all C++ files in the current directory")
    end
    CommandRegistry.insert EasyCommand.new

    # Get usage info
    def usage
      s  = "\n"
      s += "  ABOUT\n"
      s += "    The 'easy' command tells Bake to build all source files in the current dir,\n"
      s += "    even if no .bake file exists. If such a file does exist, it will be ignored.\n"
      s += "\n"
      s += "  USAGE\n"
      s += "    bake easy [app|lib|dll] [name]\n"
      s += "\n"
      return s
    end
    
    # Run the command
    def run
      # Get and check params
      type = (ARGV.length >= 2 ? ARGV[1] : ProjectType::APP)
      name = (ARGV.length >= 3 ? ARGV[2] : type)
      
      if(!ProjectType::valid? type)
        raise "Invalid [app|lib|dll] value. See 'bake help easy'."
      end

      # Figure out what the output filename will be
      outfile = name + ProjectType.filename_suffix(type)

      # Print some stuff
      puts "Output File Name: #{outfile}"
      puts "Output File Type: #{type} (#{ProjectType.desc(type)})"

      # Get all C++ files
      files = Utils.get_source_files
      
      # Create a project
      project = Project.new
      project.name = name
      project.type = type
      project.files = files

      # Build everything
      comp = Compiler.new
      comp.build(project)
    end
  end

  #=============================================================================
  # The 'help' command displays usage info for the Bake utility or any of its
  # commands
  #=============================================================================
  class HelpCommand < Command
    # Set up the name and description, and add to the CommandRegistry
    def initialize
      super("help", "Display usage info for any command")
    end
    CommandRegistry.insert HelpCommand.new

    # Get usage info for the Bake utility
    def usage
      s  = "\n"
      s += "  ABOUT\n"
      s += "    Bake is a utility for maintaining and building systems of C++ projects, very\n"
      s += "    similar to Make. It scales easily from a single application to a large set\n"
      s += "    of libraries and executables.\n"
      s += "\n"
      s += "  USAGE\n"
      s += "    bake <command> [<args>]\n"
      s += "\n"
      s += "  COMMANDS\n"
      CommandRegistry.commands.each do |command|
        s += '    ' + command.name.ljust(12) + command.desc + "\n"
      end
      s += "\n"
      s += "  OPTIONS\n"
      s += "    -h, --help       Display this screen, or help for the given command\n"
      s += "\n"
      return s
    end

    # Run the command
    def run


      # Get the command for which to show usage info
      command = (ARGV.size < 2 ? self : CommandRegistry.lookup(ARGV[1]))
      if command.nil?
        raise "'#{ARGV[1]}' is not a valid command. See 'bake help'."
      end

      # Print usage info
      puts "Bake: A Better C++ Build Utility"
      print command.usage
    end
  end
  
end # module Bake
