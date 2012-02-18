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

  class System
    attr_accessor :name, :projects

    # Initializer
    # - Takes an optional filename, which it will parse
    def initialize(file=nil)
      @projects = []
      from_s Utils::read_file file if !file.nil?
    end

    # Write systems to a file
    def self.to_file(file, systems)
      str = ''
      sytems.each { |x| str << x.to_s; }
      Utils::write_file(file, str)
    end

    # Read the system from a file
    def from_file(file)
      from_s Utils::read_file file
    end
    
    # Convert the system to a string. The output string will match the format
    # that is expected in a bake.sys file.
    def to_s
      # First check that we have all necessary fields
      raise 'Missing system name' if(name.nil? || name.empty?)

      # Now we can build the string and return it
      str = ''

      str += "# A system is comprised of multiple projects\n"
      str += 'system ' + name + " {\n"
      str += "  projects {\n"
      projects.each { |x| str += "    #{x}\n" } if !projects.empty?
      str += "  }\n"
      str += "}\n"
      
      return str;
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

      while !lines.empty?
        # Get the next property string
        curline = lines.shift
        tokens = curline.split
        property = tokens.first

        # Check if we're all done
        if property == '}'
          if !lines.empty?
            raise "Unexpected tokens after final '}' in system definition"
          end
          return
        end

        # Check for a bad input
        if !is_valid_property? property
          raise "Invalid property \"#{property}\""
        else
          if tokens.size == 1 && lines.shift != "{"
            raise "Expected \"{\" after property declaration \"#{property}\""
          elsif tokens.size > 1 && !(tokens[1] == "{" || tokens[1] == "{}")
            raise "Expected \"{\" after property declaration \"#{property}\""
          elsif tokens.size > 2 && tokens[2] != "}"
            raise "Expected \"}\" after property declaration \"#{property} {\""
          elsif tokens.size > 3
            raise "Invalid property declaration \"#{property}\""
          end
        end

        # Check if the property is empty
        next if tokens.size == 2 && tokens[1] == "{}"
        next if tokens.size == 3 && tokens[1] == "{" && tokens[2] == "}"
        
        # Parse each property
        case property
        when 'projects'
          parse_projects lines
        else
          # We should never get here, as long as is_valid_property? is correct
          raise "Unknown project property \"#{property}\""
        end
      end
    end

    # Is the system property valid?
    def is_valid_property?(property)
      case property
      when 'projects'
      else
        return false
      end
      return true
    end
    
    # Parse a system declaration, modifying the input array
    # - Expects "system <name>" or "system <name> {"
    def parse_system_decl(lines)
      # Get the first line, which is the system declaration
      line = lines.shift
      tokens = line.split

      # Check for errors
      if tokens.size < 2 || tokens[0] != "system"
        raise "Missing \"system <name>\" from system definition" 
      end
      if tokens.size > 2 && tokens[2] != '{' || tokens.size > 3
        raise "Invalid system declaration \"#{line}\""
      end
      if tokens.size == 2
        curline = lines.shift
        raise "Expected \"{\" after system declaration" if curline != "{"
      end

      # Save the system name
      @name = tokens[1]
    end

    def parse_projects(lines)
      while true
        curline = lines.shift
        if curline.nil?
          raise "Unexpected end of system definition while parsing \"projects\" property"
        end
        return if curline == '}'
        @projects << curline
      end
    end
  end
  
end # module Bake

