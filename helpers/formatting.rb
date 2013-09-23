# MISCELLANEOUS FUNCTIONS
def camelize(str)
  str.split('_').map {|w| w.capitalize}.join
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
  puts "\n\n" << " #{str.upcase} ".center(TEXT_COL_LEN, '-')
end

def _divider(str='-', t=false, b=false)
  return unless defined?(DEBUG) && DEBUG
  x = ''
  x << "\n\n" if t
  x << "".center(TEXT_COL_LEN, str)
  x << "\n\n" if b
  puts x
end

def _debug(msg, spaces=0, obj=[])
  return unless defined?(DEBUG) && DEBUG
  str = [obj].flatten.map{|v| v.present? ? "#{v.respond_to?(:id) && v.id.present? ? "<#{v.class.name} ##{v.id}>" : v.to_s}" : nil }.compact
  str << msg 
  puts "[#{Time.now.to_s(:db)}] #{'   ' * spaces}#{str.join(' ')}"
end

def _log(msg, spaces=0, obj=[])
  # return unless defined?(DEBUG) && DEBUG
  str = [obj].flatten.map{|v| v.present? ? "#{v.respond_to?(:id) && v.id.present? ? "<#{v.class.name} ##{v.id}>" : v.to_s}" : nil }.compact
  str << msg 
  puts "[#{Time.now.to_s(:db)}] #{'   ' * spaces}#{str.join(' ')}"
end

def _error(msg, spaces=0, obj=[])
  # return unless defined?(DEBUG) && DEBUG
  x, str = [], [obj].flatten.map{|v| v.present? ? "#{v.respond_to?(:id) && v.id.present? ? "<#{v.class.name} ##{v.id}>" : v.to_s}" : nil }.compact
  str << msg 
  x << "[#{Time.now.to_s(:db)}][ERROR] #{'   ' * spaces}#{str.join(' ')}"
  if msg.respond_to?(:backtrace)
    l = "[#{Time.now.to_s(:db)}][ERROR] #{'   ' * (spaces+1)}".size
    msg.backtrace.each do |m|
      x << " #{' ' * (l)}#{m}"
    end
  end

  puts x.join("\n")
end


# TIME OUTPUT
def _t; @timestop = Time.now.to_f; end
def _te; "(#{"%.2f" % (Time.now.to_f - @timestop) rescue 0.00} sec)"; end
def _tt; puts _te; end