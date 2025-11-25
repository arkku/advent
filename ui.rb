# frozen_string_literal: true

# @param enabled [Boolean]
# @param curses [Boolean]
def make_ui(enabled:, curses: nil)
  curses ||= ARGV.include?('-u')
  if curses
    require 'curses'
    CursesUI.new
  elsif enabled
    StdoutUI.new
  else
    NullUI.new
  end
end

class NullOutput
  INSTANCE = NullOutput.new.freeze

  def <<(str)
    str
  end
end

class CursesUI
  DEFAULT_DELAY = 1.0 / 5
  STEP_DELAY = 1.0 / 30

  def initialize
    @paused = false
    @delay = DEFAULT_DELAY
    @saved_delay = @delay
    @active = true
    @steps = 1
    @frame = -1
    @message = nil
    @result = nil
    @buffer = ''
    @recording = false
    @prefix = $PROGRAM_NAME.sub(/^.*\//, '').sub(/\..*$/, '').gsub(/[^0-9a-zA-Z_-]/, '')
    @part = nil

    start
    at_exit { close }
  end

  # @yield output
  def frame
    return yield NullOutput::INSTANCE unless @active

    handle_input
    if @paused
      sleep(0.1)
    else
      if @steps
        @steps -= 1
        if @steps > 0
          @message = "step #{@steps}"
        else
          @paused = true
          @message = "paused (#{@recording ? 'rec' : 'step'})"
          @steps = nil
          @delay = @saved_delay
        end
      end

      @frame += 1
      output = []
      result = yield output
      Curses.clear
      Curses.addstr("#{@prefix} #{@frame}\t#{@message}\t#{@result}\n")
      @buffer = output.map { |o| o.is_a?(Array) ? o.join : o.to_s }.join("\n") unless output.empty?
      Curses.addstr(@buffer)
      write_file if @recording
      sleep(@delay) if @delay
      result
    end
    self
  end

  # @return [self]
  def close
    return self if Curses.closed?
    while @paused
      handle_input
      sleep(0.1)
    end
    Curses.close_screen
    puts @buffer if @buffer
    self
  end

  # @return [self]
  def split
    Curses.close_screen
    puts @buffer if @buffer
    @part = 1 if @part.nil?
    @part += 1
    @frame = 0
    @steps = 1
    @paused = false
    @result = "part #{@part}"
    self
  end

  private

  def start
    Curses.init_screen
    Curses.cbreak
    Curses.noecho
    Curses.timeout = 0

    $stdin.reopen('/dev/tty', 'r') if $stdin.tty? == false
  end

  def write_file
    filename = "#{@prefix}#{@part}-frame-#{@frame}.txt"
    begin
      File.write(filename, @buffer) unless @buffer.empty?
      @result = "wrote #{filename}"
      true
    rescue StandardError => e
      @result = e
      false
    end
  end

  def handle_input
    input = Curses.getch
    case input
    when ' '
      @paused = !@paused
      @message = @paused ? 'paused' : nil
      @result = nil
      @delay ||= @saved_delay
    when '1', '2', '3', '4'
      steps = 10**(input.to_i - 1)
      if @steps && @steps > 1
        if @steps > steps
          @steps = steps
        else
          @delay = @delay ? nil : STEP_DELAY
        end
      else
        @steps = steps
        @saved_delay = @delay if @delay && @steps.nil? && @delay != STEP_DELAY
        @delay = STEP_DELAY if @steps > 1
      end
      @paused = false
      @result = nil
    when '0'
      if @delay
        @saved_delay = @delay unless @steps
        @delay = nil
        @message = '>>'
      else
        @delay = @saved_delay
        @message = ''
      end
      @paused = false
      @result = nil
    when 'x', 'q'
      @active = false
      @result = 'QUIT'
      @message = nil
      @paused = false
      close
      puts @buffer
      exit 1 if input == 'q'
    when '[', '-'
      if @delay
        @delay *= 1.1
      else
        @delay = DEFAULT_DELAY
      end
    when ']', '+', '='
      if @delay
        @delay *= 0.9
      else
        @delay = DEFAULT_DELAY
      end
    when 'w', 'r'
      if input == 'r'
        @recording = !@recording
      end
      write_file
      @steps = 1
      @paused = false
    else
      @result = "unknown input #{input.inspect}" if input
    end
  end
end

class NullUI
  # @yield output
  def frame
    yield NullOutput::INSTANCE
  end

  # @return [self]
  def close
    self
  end

  # @return [self]
  def split
    self
  end
end

class StdoutUI
  # @yield output
  def frame
    output = []
    result = yield output
    puts output.map { |o| o.is_a?(Array) ? o.join : o.to_s }.join("\n") unless output.empty?
    result
  end

  # @return [self]
  def split
    puts
    self
  end

  # @return [self]
  def close
    self
  end
end
