#===============================================================================
# System class. A system contains multiple projects and is defined in a bake.sys
# file. Multiple systems can be defined in the same file, referencing different
# underlying projects.
#
# The directory structure for a system consists of a top-level directory, in
# which the system is defined. Projects are defined in subdirectories. Eg:
#
#     SystemDir/
#         bake.sys
#         bake.map
#         Proj1/
#             bake.proj
#             foo.h
#             foo.cpp
#         Proj2/
#             bake.proj
#             bar.h
#             bar.cpp
#             ...
#
# Evan Kuhn, 2012-02-02
#===============================================================================
require 'utils'

module Bake

  #=============================================================================
  # A build contains a set of projects to compile
  #=============================================================================
  class Build
    attr_accessor :name, :projects
    def initialize(name='')
      @name = name
      @projects = []
    end
  end
    

  #=============================================================================
  # A system contains a set of builds, which are stored in a hash from build
  # name to Build object
  #=============================================================================
  class System
    attr_accessor :builds

    # Initializer
    # - Takes an optional filename, which it will parse
    def initialize(file=nil)
      @builds = {}
      from_s Utils::read_file file if !file.nil?
    end

    # Write systems to a file
    def to_file(file)
      Utils::write_file(file, to_s)
    end

    # Read the system from a file
    def from_file(file)
      from_s Utils::read_file file
    end
    
    # Convert the system to a string. The output string will match the format
    # that is expected in a bake.sys file.
    def to_s
      str = ''
      
      str << "# A system is comprised of builds, each of which contain projects\n"
      str << "system {\n"
      builds.each_value do |build|
        str << "  build #{build.name} {\n"
        build.projects.each { |proj| str << "    #{proj}\n"; }
        str << "  }\n"
      end
      str << "}\n"
      
      return str
    end

    # Parse the system definition from a string
    def from_s(str)
      # Get rid of whitespace
      str.strip!

      # Parse into lines
      lines = str.split /\n/

      # Remove comments and get rid of empty lines
      lines.each do |line|
        line.lstrip!
        line.sub!(/#.*$/, '')
        line.rstrip!
      end
      lines.delete_if { |line| line.empty? }
      raise "System definition empty" if lines.empty?

      # Parse system declaration
      parse_system_decl lines
      raise "Unexpected end of system declaration" if lines.empty?

      while !lines.empty?
        # Get the next property string
        curline = lines.first
        tokens = curline.split
        property = tokens.first

        # Check if we're all done
        if property == '}'
          if lines.size > 1
            raise "Unexpected tokens after final '}' in project definition"
          end
          return
        end

        # Parse each property
        begin
          case property
          when 'build'
            build = Build.new
            Utils::parse_named_block(lines, build.name, build.projects)
            @builds[build.name] = build
          else
            raise "Unknown system property"
          end
        rescue => e
          raise "Error parsing property '#{property}': " + e.message
        end

        # Make sure we haven't reached a premature end of the  definition
        raise "Unexpected end of project declaration" if lines.empty?
      end
    end
    
    # Parse a system declaration, modifying the input array
    # - Expects "system <name>" or "system <name> {"
    def parse_system_decl(lines)
      # Get the first line, which is the system declaration
      curline = lines.shift
      tokens = curline.split

      # Check for errors
      if tokens.size == 1
        curline = lines.shift
        raise "Expected '{' after system declaration" if curline != '{'
      elsif tokens.size == 2 && tokens[1] == '{}'
        return
      elsif tokens.size > 1 && tokens[1] != '{'
        raise "Expected '{' after system declaration"
      elsif tokens.size == 3 && tokens[2] != '}'
        raise "Expected '}' after opening '{' in system declaration"
      elsif tokens.size > 3
        raise "Invalid system declaration '#{curline}'"
      end
    end
  end
  
end # module Bake

