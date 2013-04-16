# MISCELLANEOUS FUNCTIONS
def camelize(str)
  str.split('_').map {|w| w.capitalize}.join
end

def time_since_overall; time_since(TIME_START); end
def time_since(start=nil)
  @_time_since ||= TIME_START
  start ||= @_time_since
  @_time_since = Time.now

  "#{Time.now - start} seconds"
end


# TEXT FORMATTING
def _heading(str)
  return unless defined?(DEBUG) && DEBUG
  puts "\n\n\n"
  _divider('#')
  puts " #{str.upcase} ".center(TEXT_COL_LEN)
  _divider('#')
end

def _subheading(str)
  return unless defined?(DEBUG) && DEBUG
  puts "\n\n"
  puts " #{str.upcase} ".center(TEXT_COL_LEN, '-')
end

def _divider(str='-', t=false, b=false)
  return unless defined?(DEBUG) && DEBUG
  puts "\n\n" if t
  puts "".center(TEXT_COL_LEN, str)
  puts "\n\n" if b
end

def _debug(msg, spaces=0)
  puts "#{'   ' * spaces}#{msg}" if defined?(DEBUG) && DEBUG
end