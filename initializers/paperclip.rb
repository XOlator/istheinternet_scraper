# Disable paperclip logging
Paperclip.options[:log] = false


# https://github.com/thoughtbot/paperclip/pull/823
module Paperclip
  class ExtraFileAdapter
    def initialize(target)
      @target = target
      @tempfile = @target[:tempfile]
    end
    def original_filename; @target[:filename]; end
    def content_type; @target[:type]; end
    def fingerprint; @fingerprint ||= Digest::MD5.file(path).to_s; end
    def size; File.size(path); end
    def nil?; false; end
    def read(length = nil, buffer = nil); @tempfile.read(length, buffer); end
    def rewind; @tempfile.rewind; end # We don't use this directly, but aws/sdk does.
    def close; @tempfile.close; end
    def closed?; @tempfile.closed?; end
    def eof?; @tempfile.eof?; end
    def path; @tempfile.path; end
  end

  module Interpolations
    def rails_root(attachment, style_name); APP_ROOT; end
    def rails_env(attachment, style_name); APP_ENV; end
  end
end

Paperclip.io_adapters.register Paperclip::ExtraFileAdapter do |target|
  target.class == Hash && !target[:tempfile].nil? && (File === target[:tempfile] || Tempfile === target[:tempfile])
end


# Simple pass-through processor for paperclip to save output of whatever HTML is scraped
# [Patch for when rmagick can't determine via content-type.]
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