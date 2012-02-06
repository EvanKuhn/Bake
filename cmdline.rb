#===============================================================================
# Command-line options parser for the Bake utility
#
# Evan Kuhn, 2012-02-02
#===============================================================================
require 'optparse'
require 'project'

class CmdLine
  def initialize
    # This hash will hold all options parsed from the command line
    @options = {}

    # Create the parser object
    @optparse = OptionParser.new do |opts|
      
      # Set a banner, displayed at the top of the help screen.
      opts.banner = <<eos
  Bake is a utility for maintaining and building systems of C++ projects, very
  similar to Make. It scales easily from a single application to a large set of
  libraries and executables. Bake provides two usage types:

  1) Easy mode

     Build all of the C++ files in the current directory. Output an application,
     static library, or shared library. Also allow the user to name the project,
     which determines the output filename.

     USAGE> bake --easy [app|lib|dll] [name]

  2) Normal mode

     This requires that a .bake file exist in the current directory. Bake will
     read the configuration info in the .bake file and build the project(s) 
     specified by the user.

     USAGE> bake <project|system> <name>
eos
      
      opts.separator ''
      opts.separator 'Options:'
      
      # Parse --easy option
      @options[:easy] = false
      @options[:type] = ProjectType::APP
      opts.on( '-e', '--easy', \
               'Compile all C++ files in the current dir.', \
               'Optionally takes args: [type] [name]') \
      do
        @options[:easy] = true
        @options[:type] = ARGV[0] if(ARGV.size > 0)
        @options[:name] = ARGV[1] if(ARGV.size > 1)

        # Make sure the project type is valid
        if(!ProjectType.valid? @options[:type])
          raise "Bad [type] given for --easy option"
        end
        
        # If no name is given, use the type string
        @options[:name] = @options[:type] if(@options[:name].nil?)
      end

      # Parse --verbose option
      opts.on('-v', '--verbose', 'Verbose output') do
        @options[:verbose] = true
      end
      
      # Parse --help option
      opts.on('-h', '--help', 'Display this screen') do
        puts opts
        exit
      end

      opts.separator ''
    end
  end

  # Parse the command line args, removing all options from ARGV
  def parse
    @optparse.parse!
  end

  # Was easy mode specified?
  def easy?
    return @options[:easy]
  end

  # Get the project type (for easy mode)
  def type
    return @options[:type]
  end

  # Get the project name (for easy mode)
  def name
    return @options[:name]
  end

  # Get the output filename (for easy mode). If none given, build one from the
  # project name and type
  def outfile
    return name + ProjectType::filename_suffix(type)
  end
  
  # Is verbose mode enabled?
  def verbose?
    return @options[:verbose]
  end
end
