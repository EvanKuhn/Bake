

#cmdline.option("h,help")
#cmdline.option("f,file", 1)
#cmdline.option()

#cmdline.parse(ARGV)

#cmdline.has('h')
#value = cmdline.get('f')




class CommandLine
  def initialize
    @index = 0
    @option_index_map = {}  # Map from option name to index
    @option_keys = []       # Array of option name per index
    @option_nvals = []      # Num expected values to be given with option
    @option_given = []      # Flags indicating if the option was specified
    @option_vals = []       # Actual values given with option
    @params = []            # Non-option args
  end
  
  # Add an option to parse.
  # Params:
  #   1) The option character and/or name. Eg: "h,help", "h", or "help",
  #      depending on which ones you want to accept.
  #   2) The number of values expected to be passed after the option.
  #
  # Notes:
  # - Options must start with an alphanumeric character.
  # - Subsequent characters can include '-' or '_'
  def option(key, num_values=0)   
    if(key =~ /^[a-zA-Z0-9]$/)
      raise "Option '#{key}' already specified" if @option_index_map.has_key? key
      @option_index_map[key] = @index
      @option_keys[@index] = key
      @option_nvals[@index] = num_values
      @option_given[@index] = false
      @index += 1
    elsif(key =~ /^[a-zA-Z][\w\-]+$/)
      raise "Option '#{key}' already specified" if @option_index_map.has_key? key
      @option_index_map[key] = @index
      @option_keys[@index] = key
      @option_nvals[@index] = num_values
      @option_given[@index] = false
      @index += 1
    elsif(key =~ /^([a-zA-Z0-9]),([a-zA-Z][\w\-]+)$/)
      raise "Option '#{$1}' already specified" if @option_index_map.has_key? $1
      raise "Option '#{$2}' already specified" if @option_index_map.has_key? $2
      @option_index_map[$1] = @index
      @option_index_map[$2] = @index
      @option_keys[@index] = $1
      @option_nvals[@index] = num_values
      @option_given[@index] = false
      @index += 1
    else
      raise "Invalid option specification '#{key}'"
    end
  end

  # Will this object accept the given option string?
  def accepts?(option)
    return @option_index_map.has_key? option
  end

  # Parse the command line args
  def parse(args)
    args.each do |arg|
      if arg.start_with? '--'
        puts "long option '#{arg}'"
        
        # Argument is a long option (--foobar)
        arg = arg[2,arg.length]
        raise "Option '--#{arg}' not accepted" if !accepts? arg

        # Remember that the option was specified
        index = @option_index_map[arg]
        @option_given[index] = true
        
        # TODO - check for and save the option's values
        # @option_vals[index]
        
      elsif arg.start_with? '-'
        # Argument is a short option (-a, -abc)
        arg = arg[1,arg.length]

        # Make sure each character is accepted
        arg.chars.each_with_index do |c,i|
          puts "short option '#{c}'"
          
          # Check for errors
          raise "Option '-#{c}' not accepted" if !accepts? c
          index = @option_index_map[c]
          nvals = @option_nvals[index]

          if nvals > 0 && i < arg.size-1
            raise "Option '-#{c}' must be followed by #{nvals} values" 
          end
          
          # Remember that the option was specified
          index = @option_index_map[c]
          @option_given[index] = true

          # TODO - check for and save the option's values
          # @option_vals[index]
        end

      else
        # Argument is a param (ie. not an option)
        @params << arg
      end
    end
  end

  # Check if the option has been specified at the command line
  def has?(arg)
    return false if !@param_index_map.has_key? arg
    index = @param_index_map[arg]
    return @option_given[index]
  end

  # Get the value for the given arg
  # - Raises an error if the option hasn't been specified
  # - Returns nil if no values are expected 
  # - Returns a single value if only one is expected
  # - Returns an array of values if multiple values are expected
  def value(arg)
    raise "Option '#{arg}' not accepted" if !accepts? arg
    raise "Option '#{arg}' not specified" if !has? arg
    index = @param_index_map[arg]
    case @param_nvals[index]
    when 0
      return nil
    when 1
      return @param_vals[index][0]
    else
      return @param_vals[index]
    end
  end

  # Get the remaining values in ARGV that were not options (ie. did not start
  # with a hyphen).
  def params
    return @params
  end

  # Get all the options given.
  # - Returns an array of option strings.
  # - Call value() to get the corresponding values.
  def options
    ops = []
    @option_keys.each_with_index do |op,i|
      ops << op if @option_given[i]
    end
    return ops
  end
end




begin
  cmdline = CommandLine.new
  cmdline.option("h,help")
  cmdline.option("verbose")
  cmdline.option("f", 1)
  cmdline.option('2', 2)
  cmdline.option('what-you-want', 1)
  
  cmdline.parse(ARGV)
  
  puts "Params: " + cmdline.params.join(', ')
  puts "Options: " + cmdline.options.join(', ')
rescue => e
  puts "ERROR: " + e.message
end
