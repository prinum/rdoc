require 'rdoc'

##
# This class is a wrapper around File IO and Encoding that helps RDoc load
# files and convert them to the correct encoding.

module RDoc::Encoding

  ##
  # Reads the contents of +filename+ and handles any encoding directives in
  # the file.
  #
  # The content will be converted to the +encoding+.  If the file cannot be
  # converted a warning will be printed and nil will be returned.

  def self.read_file filename, encoding
    content = open filename, "rb" do |f| f.read end

    utf8 = content.sub!(/\A\xef\xbb\xbf/, '')

    RDoc::Encoding.set_encoding content

    if Object.const_defined? :Encoding then
      encoding ||= Encoding.default_external
      orig_encoding = content.encoding

      if utf8 then
        content.force_encoding Encoding::UTF_8
        content.encode! encoding
      else
        # assume the content is in our output encoding
        content.force_encoding encoding
      end

      unless content.valid_encoding? then
        # revert and try to transcode
        content.force_encoding orig_encoding
        content.encode! encoding
      end

      unless content.valid_encoding? then
        warn "unable to convert #{filename} to #{encoding}, skipping"
        content = nil
      end
    end

    content
  rescue ArgumentError => e
    raise unless e.message =~ /unknown encoding name - (.*)/
    warn "unknown encoding name \"#{$1}\" for #{filename}, skipping"
    nil
  rescue Encoding::UndefinedConversionError => e
    warn "unable to convert #{e.message} for #{filename}, skipping"
    nil
  rescue Errno::EISDIR, Errno::ENOENT
    nil
  end

  ##
  # Sets the encoding of +string+ based on the magic comment

  def self.set_encoding string
    return unless Object.const_defined? :Encoding

    first_line = string[/\A(?:#!.*\n)?.*\n/]

    name = case first_line
           when /^<\?xml[^?]*encoding=(["'])(.*?)\1/ then $2
           when /\b(?:en)?coding[=:]\s*([^\s;]+)/i   then $1
           else                                           return
           end

    enc = Encoding.find name
    string.force_encoding enc if enc
  end

end


