require 'gserver'

# This class implements a very simple SMTP server which
# accepts all mails and calls callback block on each incoming mail.
#
# @example
#  server = TestSmtpd.new(:port => 1025, :host => "localhost", :debug => true) do |msg|
#    puts "Mail recieved: #{msg}"
#  end
#  server.start
#  server.join
class TestSmtpd < GServer

  # Create a new TestSmtpd server. Listens on localhost port 1025
  # by default. These defaults can be overridden by passing an option
  # hash as first parameter.
  #
  # @option options [Integer] port (1025) The tcp port to listen to
  # @option options [String] host ('127.0.0.1') The hostname or ip address to listen to
  # @option options [boolean] debug (false) Set to true to turn debug output on
  # @option options [Integer] max_connections (4) Maximum number of concurrent connections
  def initialize(options = {}, &message_handler)
    opts = {
      :port => 1025,
      :host => "127.0.0.1",
      :max_connections => 4,
      :debug => false
    }.merge(options)
    super(opts[:port], opts[:host], opts[:max_connections], $stderr, opts[:debug], opts[:debug])
    @message_handler = message_handler
  end

  def serve(io)
    mode = :CMD
    out io, 220,  "hello"
    msg = ""
    while !io.closed?
      data = io.readline
      if mode == :CMD
        log "<<< #{data}"
        mode = :DATA if process_cmd(data, io) == :DATA_MODE
      else
        mode = :CMD if process_data(data, msg, io) == :CMD_MODE
      end
    end
  end

  private

  def out(io, status, text)
    log(">>> #{status.to_s} #{text}") if @audit
    io.print("#{status.to_s} #{text}\r\n")
  end

  def process_cmd(line, io)
    case line
    when /^(HELO|EHLO|MAIL FROM|RCPT TO)/
      out io, 250, 'OK'
    when /^QUIT/
      out io, 221, 'Bye'
      io.close
    when /^DATA/
      out io, 354, 'End data with <CR><LF>.<CR><LF>'
      return :DATA_MODE
    else
      out io, 500, 'ERROR'
    end
  end

  def process_data(line, msg, io)
    if line.chomp =~ /^\.$/
      #msg << line
      log("Recieved message") if @audit
      out io, 250, "OK"
      @message_handler.call msg
      msg.clear
      return :CMD_MODE
    else
      msg << line
    end
  end
end

