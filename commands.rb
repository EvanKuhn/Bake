#===============================================================================
# A set of Bake utility commands
# 
# Evan Kuhn, 2012-02-05
#===============================================================================
require 'cmdline'
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
      s  = "#{USAGE_HEADER}\n"
      s << "\n"
      s << "  ABOUT\n"
      s << "    The 'build' command parses the bake.proj file in the current directory and\n"
      s << "    builds the project defined in that file.\n"
      s << "\n"
      s << "  USAGE\n"
      s << "    bake build\n"
      s << "\n"
      return s
    end
    
    # Run the command
    def run(args)
      # Parse command-line args
      cmdline = CommandLine.new
      cmdline.option("h,help")
      cmdline.parse(args)

      # Show help?
      if cmdline.has? 'help'
        puts usage
        return
      end

      # Parse the bake.proj file
      raise "No bake.proj file found" if !File.exists? BAKE_PROJ_FILE
      project = Project.new BAKE_PROJ_FILE

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
      s  = "#{USAGE_HEADER}\n"
      s << "\n"
      s << "  ABOUT\n"
      s << "    The 'clean' command deletes all files in the .bake dir. If a bake.proj file\n"
      s << "    file exists, it will also clean up the output file created during compilation.\n"
      s << "\n"
      s << "  USAGE\n"
      s << "    bake clean \n"
      s << "\n"
      return s
    end
    
    # Run the command
    def run(args)
      # Parse command-line args
      cmdline = CommandLine.new
      cmdline.option("h,help")
      cmdline.parse(args)

      # Show help?
      if cmdline.has? 'help'
        puts usage
        return
      end

      cleaned = false

      # Clean up .bake dir
      if File.exists?(BAKE_DIR) && File.directory?(BAKE_DIR)
        Dir.new(BAKE_DIR).each do |file|
          next if(file == '.' || file == '..')
          file = BAKE_DIR + file
          FileUtils.rm_rf(file)
        end
        puts "Cleaned .bake dir"
        cleaned = true
      end

      # Clean up output file
      if File.exists? BAKE_PROJ_FILE
        begin
          project = Project.new BAKE_PROJ_FILE
          if File.exists? project.outfile
            File.delete project.outfile
            puts "Deleted output file #{project.outfile}"
            cleaned = true
          end
        rescue => e
          puts "Error cleaning output file: " + e.message
        end
      end

      puts "Nothing to clean" if !cleaned
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
      s  = "#{USAGE_HEADER}\n"
      s << "\n"
      s << "  ABOUT\n"
      s << "    The 'easy' command tells Bake to build all source files in the current dir,\n"
      s << "    even if no bake.proj file exists. If such a file does exist, it is ignored.\n"
      s << "\n"
      s << "  USAGE\n"
      s << "    bake easy [app|lib|dll] [name]\n"
      s << "\n"
      return s
    end
    
    # Run the command
    def run(args)
      # Parse command-line args
      cmdline = CommandLine.new
      cmdline.option("h,help")
      cmdline.parse(args)

      # Show help?
      if cmdline.has? 'help'
        puts usage
        return
      end

      # Get and check params
      args = cmdline.params
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
  # The 'init' command creates a bake.proj file and initializes it with the
  # source files in the current dir. If such a file already exists, it will not
  # be changed.
  #=============================================================================
  class InitCommand < Command
    # Set up the name and description, and add to the CommandRegistry
    def initialize
      super("init", "Write a bake.proj file initialized with source files")
    end
    CommandRegistry.insert new

    # Get usage info
    def usage
      s  = "#{USAGE_HEADER}\n"
      s << "\n"
      s << "  ABOUT\n"
      s << "    The 'init' command creates a bake.proj file and initializes it with the\n"
      s << "    source files in the current dir. If such a file already exists, it will not\n"
      s << "    be changed.\n"
      s << "\n"
      s << "  USAGE\n"
      s << "    bake init [name] [type]\n"
      s << "\n"
      s << "  WHERE\n"
      s << "    name  - Project name. Default: #{DEFAULT_NAME}\n"
      s << "    type  - Project type. Default: #{DEFAULT_TYPE}\n"
      s << "\n"
      return s
    end
    
    # Run the command
    def run(args)
      # Parse command-line args
      cmdline = CommandLine.new
      cmdline.option("h,help")
      cmdline.parse(args)

      # Show help?
      if cmdline.has? 'help'
        puts usage
        return
      end

      # Get project name
      args = cmdline.params.clone
      name = (args.empty? ? DEFAULT_NAME : args.shift)
      type = (args.empty? ? DEFAULT_TYPE : args.shift)

      raise "Invalid name '#{name}'" if name !~ /^\w+$/
      raise "Invalid type '#{type}'" if !ProjectType::valid? type

      # Make sure no bake.proj file exists
      if File.exists? BAKE_PROJ_FILE
        puts BAKE_PROJ_FILE + ' already exists'
      else
        project = Project.new
        project.name = name
        project.type = type
        project.files = Utils::get_source_files
        project.to_file BAKE_PROJ_FILE
        puts BAKE_PROJ_FILE + ' file created'
      end
    end

    # Defaults
    DEFAULT_NAME = 'my_project'
    DEFAULT_TYPE = ProjectType::APP
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

    # Get usage info for the Bake utility
    def self.bake_usage
      s  = "#{USAGE_HEADER}\n"
      s << "\n"
      s << "  ABOUT\n"
      s << "    Bake is a utility for maintaining and building systems of C++ projects, very\n"
      s << "    similar to Make. It scales easily from a single application to a large set\n"
      s << "    of libraries and executables.\n"
      s << "\n"
      s << "  USAGE\n"
      s << "    bake <command> [<args>]\n"
      s << "\n"
      s << "  COMMANDS\n"
      CommandRegistry.commands.each do |command|
        s << '    ' + command.name.ljust(12) + command.desc + "\n"
      end
      s << "\n"
      s << "  OPTIONS\n"
      s << "    -h, --help       Display this screen, or help for the given command\n"
      s << "\n"
      return s
    end

    # Get usage info for the help command
    def usage
      s  = "#{USAGE_HEADER}\n"
      s << "\n"
      s << "  ABOUT\n"
      s << "    The 'help' command prints usage info for the Bake utility overall, or for a\n"
      s << "    given command.\n"
      s << "\n"
      s << "  USAGE\n"
      s << "    bake help [command]\n"
      s << "\n"
      return s
    end

    # Run the command
    def run(args)
      # Get the command for which to show usage info
      if args.empty?
        # If no args, show Bake usage
        puts BakeUtility::usage
      else
        command = CommandRegistry.lookup(args.first)
        if command.nil?
          # If invalid command, show Bake usage plus error message
          puts BakeUtility::usage
          puts "ERROR: '#{args.first}' is not a valid command"
        else
          # Otherwise show the command's usage
          puts command.usage
        end
      end
    end
  end
  
end # module Bake
