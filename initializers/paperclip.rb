module Paperclip
  class SaveHtml < Processor
    def initialize(file, options={}, attachment=nil)
      super
      @file             = file
      @instance         = attachment.instance
      @current_format   = File.extname(@file.path)
      @save_format      = ".#{@options[:format].to_s}" rescue nil
      @basename         = File.basename(@file.path, @current_format)
    end

    def make
      dst = Tempfile.new([@basename, (@save_format || @current_format || '')])
      dst.write(File.read(@file.path))
      dst
    end
  end
end