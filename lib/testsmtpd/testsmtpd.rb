require 'gserver'

class TestSmtpd < GServer

  def initialize(options = {}, &message_handler)
    super(1025, "127.0.0.1")
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

