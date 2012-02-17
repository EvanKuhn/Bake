#===============================================================================
# A set of Bake utility commands
# 
# Evan Kuhn, 2012-02-05
#===============================================================================
require 'compiler'
require 'fileutils'
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
  # The Bake utility runs commands 
  #=============================================================================
  class BakeUtility
    # Get usage info for the Bake utility
    def self.usage
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
    def self.run(args)
      help = false
      
      # Remove any options before the command name
      while !args.empty? && args.first.start_with?('-') do
        op = args.shift
        if op == '-h' || op == '--help'
          # If the help option is given, get rid of the rest of the arguments so the
          # help command gives help for the Bake utility
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
  
  #=============================================================================
  # The 'build' command builds all projects defined the bake.proj file
  #=============================================================================
  class BuildCommand < Command
    # Set up the name and description, and add to the CommandRegistry
    def initialize
      super("build", "Build projects defined in the bake.proj file in the current dir")
    end
    CommandRegistry.insert new

    # Get usage info
    def usage
      s  = "\n"
      s += "  ABOUT\n"
      s += "    The 'build' command parses the bake.proj file in the current directory and\n"
      s += "    builds the project defined in that file.\n"
      s += "\n"
      s += "  USAGE\n"
      s += "    bake build\n"
      s += "\n"
      return s
    end
    
    # Run the command
    def run(args)
      # Parse the bake.proj file
      raise "No bake.proj file found" if !File.exists? 'bake.proj'
      project = Project.new Utils::read_file 'bake.proj'

      # Build the project
      comp = Compiler.new
      comp.build(project)
    end
  end

  #=============================================================================
  # The 'clean' command deletes all compiled files
  #=============================================================================
  class CleanCommand < Command
    # Set up the name and description, and add to the CommandRegistry
    def initialize
      super("clean", "Delete all compiled files")
    end
    CommandRegistry.insert new

    # Get usage info
    def usage
      s  = "\n"
      s += "  ABOUT\n"
      s += "    The 'clean' command deletes all compiled files. You may clean up all files,\n"
      s += "    those in the current directory, or those for a specific project or system. A\n"
      s += "    bake.proj file is required for all cleanup types except 'current', which will\n"
      s += "    simply delete the contents of the .bake directory.\n"
      s += "\n"
      s += "  USAGE\n"
      s += "    bake clean <all|current|project|system> [name]\n"
      s += "\n"
      return s
    end
    
    # Run the command
    def run(args)
      raise "No action given. See 'bake help clean'." if(args.size < 1)
      action = args[0]

      if action == 'all'
        puts "*** I'm not implemented yet! ***"
        # TODO
      elsif action == 'current'
        if(File.exists?(BAKE_DIR) && File.directory?(BAKE_DIR))
          puts "Cleaning current directory"
          Dir.new(BAKE_DIR).each do |file|
            next if(file == '.' || file == '..')
            file = BAKE_DIR + file
            FileUtils.rm_rf(file)
          end
          puts ".bake/ dir cleaned"
        end
      elsif action == 'project'
        puts "*** I'm not implemented yet! ***"
        # TODO
      elsif action == 'system'
        puts "*** I'm not implemented yet! ***"
        # TODO
      end          
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
    CommandRegistry.insert new

    # Get usage info
    def usage
      s  = "\n"
      s += "  ABOUT\n"
      s += "    The 'easy' command tells Bake to build all source files in the current dir,\n"
      s += "    even if no bake.proj file exists. If such a file does exist, it is ignored.\n"
      s += "\n"
      s += "  USAGE\n"
      s += "    bake easy [app|lib|dll] [name]\n"
      s += "\n"
      return s
    end
    
    # Run the command
    def run(args)
      # Get and check params
      type = (args.length >= 1 ? args[0] : ProjectType::APP)
      name = (args.length >= 2 ? args[1] : type)
      
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
    CommandRegistry.insert new

    # Get usage info for the help command
    def usage
      s  = "\n"
      s += "  ABOUT\n"
      s += "    The 'help' command prints usage info for the Bake utility overall, or for a\n"
      s += "    given command.\n"
      s += "\n"
      s += "  USAGE\n"
      s += "    bake help [command]\n"
      s += "\n"
      return s
    end

    # Run the command
    def run(args)
      usage = "Bake: A Better C++ Build Utility"

      # Get the command for which to show usage info
      if args.empty?
        # If no args, show Bake usage
        usage += BakeUtility::usage
      else
        command = CommandRegistry.lookup(args.first)
        if command.nil?
          # If invalid command, show Bake usage plus error message
          usage += BakeUtility::usage
          usage += "ERROR: '#{args.first}' is not a valid command"
        else
          # Otherwise show the command's usage
          usage += command.usage
        end
      end
      
      # Print usage
      puts usage
    end
  end
  
end # module Bake
