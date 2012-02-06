#===============================================================================
# Compiler class for the Bake utility. This is responsible for compiling code.
# If we need to support multiple compilers, we can write a separate class for
# each compiler.
#
# Evan Kuhn, 2012-02-02
#===============================================================================
require 'constants'
require 'project'
require 'utils'

module Bake
  
  class Compiler
    attr_accessor :verbose
    
    # Build (compile) a project
    def build(project)
      puts "Building project '#{project.name}':"
      puts
      project.files.each { |f| puts "  #{f}" }
      puts
      
      # Build up the command string
      tokens = project.files.clone
      tokens << '-o ' + project.outfile
      
      command = 'g++ ' + tokens.join(" \\\n    ")
      puts command if verbose

      # Make sure the temp output dir exists
      Dir.mkdir(TEMP_OUTPUT_DIR) if(!Dir.exists? TEMP_OUTPUT_DIR)
      compiler_output_file = TEMP_OUTPUT_DIR  + '.compiler-output'
      
      # Run the command and save output in a temp file
      system(command + ' &> ' + compiler_output_file)
      
      # Print success or failure
      if $?.success?
        puts 'Success!'
      else
        print "Compiler error:\n\n"
        Utils.print_file(compiler_output_file, '  ')
        puts
      end
    end
  end

end # module Bake
