# Disable paperclip logging
Paperclip.options[:log] = false

s3_options = YAML.load_file(File.join(APP_ROOT, 's3.yml'))[APP_ENV].symbolize_keys rescue nil

if s3_options.present?
  USE_S3 = true
  Paperclip::Attachment.default_options.merge!({
    storage:  :s3,
    bucket:   s3_options[:bucket],
    s3_credentials: {
      access_key_id: s3_options[:access_key_id],
      secret_access_key: s3_options[:secret_access_key]
    }
  })
end

USE_S3 ||= false

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