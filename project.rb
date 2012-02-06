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

    # Get the project's output filename
    def outfile
      return name + ProjectType::filename_suffix(type)
    end
    
    # Parse a project definition from a string
    def from_s
      raise 'Project::from_s() not implemented!'
    end
    
    # Convert the project to a string. The output string will match the format
    # that is expected in a bake.proj file.
    def to_s
      # First check that we have all necessary fields
      raise 'Missing project name'  if(name.nil?  || name.empty?)
      raise 'Missing project type'  if(type.nil?  || type.empty?)
      raise 'Missing project files' if(files.nil? || files.empty?)

      # Now we can build the string and return it
      str = ''

      str += 'project ' + name + " {\n"
      str += "  # The project type determines what kind of file will be created, as well as\n"
      str += "  # its name. Given a project named 'foo', we can build one of three file types:\n"
      str += "  # 1) An application named foo\n"
      str += "  # 2) A static library named foo.a\n"
      str += "  # 3) A shared library named foo.so\n"
      str += "  type = #{type}\n"
      str += "\n"
      str += "  # All files in this project that should be compiled\n"
      str += "  files {\n"
      files.each { |x| str += "    #{x}\n" } if(!files.nil?)
      str += "  }\n"
      str += "\n"
      str += "  # All the other projects that this project depends on\n"
      str += "  deps {\n"
      deps.each { |x| str += "    #{x}\n" } if(!deps.nil?)
      str += "  }\n"
      str += "\n"
      str += "  # A list of third-party libraries used by this project\n"
      str += "  libs {\n"
      libs.each { |x| str += "    #{x}\n" } if(!libs.nil?)
      str += "  }\n"
      str += "\n"
      str += "  # Paths to search for included files\n"
      str += "  include-paths {\n"
      inc_paths.each { |x| str += "    #{x}\n" } if(!inc_paths.nil?)
      str += "  }\n"
      str += "\n"
      str += "  # Paths to search for third-party library files\n"
      str += "  lib-paths {\n"
      lib_paths.each { |x| str += "    #{x}\n" } if(!lib_paths.nil?)
      str += "  }\n"
      str += "}\n"
      
      return str;
    end
  end
  
end # module Bake
