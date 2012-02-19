#===============================================================================
# Project and ProjectType classes. A project contains all the settings for a
# single application or library. The class's fields mirror the format of a
# project specification in a bake.proj file.
#
# Evan Kuhn, 2012-02-02
#===============================================================================

module Bake
  
  #=============================================================================
  # Project types:
  #
  #   1) app - An application / executable
  #   2) lib - A staticly-linked library
  #   3) dll - A dynamically-linked / shared-object library 
  #
  #=============================================================================
  class ProjectType
    # The different project types
    APP = 'app'
    LIB = 'lib'
    DLL = 'dll'

    # Check if a given type is valid
    def self.valid?(type)
      return type == APP || type == LIB || type == DLL
    end

    # Get a long description of the type
    def self.desc(type)
      case type
      when ProjectType::APP
        return 'executable'
      when ProjectType::LIB
        return 'static library'
      when ProjectType::DLL
        return 'shared library'
      else
        raise "Invalid ProjectType '#{type}'"
      end
    end
    
    # Get the default filename suffix for the given project type
    # 1) app --> <empty string>
    # 2) lib --> .a
    # 3) dll --> .so
    def self.filename_suffix(type)
      case type
      when APP
        return ''
      when LIB
        return '.a'
      when DLL
        return '.so'
      else
        raise 'Invalid ProjectType: ' + type
      end
    end
  end

  #=============================================================================
  # A project is made up of:
  #
  #   name      - The project name. Determines the output filename.
  #   type      - A type (app, lib, dll)
  #   files     - A set of C++ source files
  #   deps      - Other projects that this project depends on
  #   libs      - Third-party libraries
  #   inc-paths - Third-party include paths
  #   lib-paths - Third-party library paths
  #
  #=============================================================================
  class Project
    attr_accessor :name, :type, :files, :deps, :libs, :inc_paths, :lib_paths

    # Initializer
    # - Takes an optional filename, which it will parse
    def initialize(file=nil)
      @files = []
      @deps = []
      @libs = []
      @inc_paths = []
      @lib_paths = []
      from_s Utils::read_file file if !file.nil?
    end
    
    # Get the project's output filename
    def outfile
      return name + ProjectType::filename_suffix(type)
    end

    # Write the project to a file
    def to_file(file)
      Utils.write_file(file, to_s)
    end

    # Read the project from a file
    def from_file(file)
      from_s Utils::read_file file
    end
    
    # Convert the project to a string. The output string will match the format
    # that is expected in a bake.proj file.
    def to_s
      # First check that we have all necessary fields
      raise 'Missing project name' if(name.nil? || name.empty?)
      raise 'Missing project type' if(type.nil? || type.empty?)

      # Now we can build the string and return it
      str = ''

      str << 'project ' + name + " {\n"
      str << "  # The project type determines what kind of file will be created, as well as\n"
      str << "  # its name. Given a project named 'foo', we can build one of three file types:\n"
      str << "  # 1) An application named foo\n"
      str << "  # 2) A static library named libfoo.a\n"
      str << "  # 3) A shared library named libfoo.so\n"
      str << "  type = #{type}\n"
      str << "\n"
      str << "  # All files in this project that should be compiled\n"
      str << "  files {\n"
      files.each { |x| str << "    #{x}\n" } if !files.nil?
      str << "  }\n"
      str << "\n"
      str << "  # All the other projects that this project depends on\n"
      str << "  deps {\n"
      deps.each { |x| str << "    #{x}\n" } if !deps.nil?
      str << "  }\n"
      str << "\n"
      str << "  # A list of third-party libraries used by this project.\n"
      str << "  # For a library file named 'libfoo.a' or 'libfoo.so', just write 'foo'.\n"
      str << "  libs {\n"
      libs.each { |x| str << "    #{x}\n" } if !libs.nil?
      str << "  }\n"
      str << "\n"
      str << "  # Paths to search for included files\n"
      str << "  inc-paths {\n"
      inc_paths.each { |x| str << "    #{x}\n" } if !inc_paths.nil?
      str << "  }\n"
      str << "\n"
      str << "  # Paths to search for third-party library files\n"
      str << "  lib-paths {\n"
      lib_paths.each { |x| str << "    #{x}\n" } if !lib_paths.nil?
      str << "  }\n"
      str << "}\n"
      
      return str;
    end

    # Parse a project definition from a string
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
      raise "Project definition empty" if lines.empty?

      # Parse project declaration
      parse_project_decl lines
      raise "Unexpected end of project declaration" if lines.empty?

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
          when 'type'
            parse_type lines
          when 'files'
            Utils::parse_unnamed_block(lines, files)
          when 'deps'
            Utils::parse_unnamed_block(lines, deps)
          when 'libs'
            Utils::parse_unnamed_block(lines, libs)
          when 'inc-paths'
            Utils::parse_unnamed_block(lines, inc_paths)
          when 'lib-paths'
            Utils::parse_unnamed_block(lines, lib_paths)
          else
            raise "Unknown project property"
          end
        rescue => e
          raise "Error parsing property '#{property}': " + e.message
        end

        # Make sure we haven't reached a premature end of the definition
        raise "Unexpected end of system declaration" if lines.empty?
      end
    end
    
    # Parse a project declaration, modifying the input array
    # - Expects "project <name>" or "project <name> {"
    def parse_project_decl(lines)
      # Get the first line, which is the project definition
      curline = lines.shift
      tokens = curline.split

      # Check for errors
      if tokens.size < 2 || tokens[0] != "project"
        raise "Missing 'project <name>' from project definition" 
      end
      if tokens.size > 2 && tokens[2] != '{' || tokens.size > 3
        raise "Invalid project declaration '#{curline}'"
      end
      if tokens.size == 2
        curline = lines.shift
        raise "Expected '{' after project declaration" if curline != '{'
      end

      # Save the project name
      @name = tokens[1]
    end

    # Parse the project specification string "type = <type>"
    def parse_type(lines)
      tokens = lines.shift.split
      if tokens.size != 3 || tokens[0] != 'type' || tokens[1] != '=' || tokens[2] !~ /\w+/
        raise "Invalid type specification '#{str}'"
      end
      type = tokens[2]
      raise "Invalid project type '#{type}'" if !ProjectType::valid? type
      @type = type
    end
  end
  
end # module Bake
