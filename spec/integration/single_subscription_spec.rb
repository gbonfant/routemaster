require 'spec_helper'
require 'spec/support/persistence'
require 'routemaster/client'
require 'pathname'

describe 'integration' do

  class SubProcess
    def initialize(name:, command:, start: nil, stop: nil)
      @name    = name
      @command = command
      @pid     = nil
      @reader  = nil
      @loglines = []
      @start_regexp = start
      @stop_regexp  = stop
    end

    def start
      raise 'already started' if @pid
      _log 'starting'
      @loglines = []
      rd, wr = IO.pipe
      if @pid = fork
        # parent
        wr.close
        @reader = Thread.new { _read_log(rd) }
      else
        _log 'forked'
        # child
        rd.close
        ENV['ROUTEMASTER_LOG_FILE'] = nil
        $stdin.reopen('/dev/null')
        $stdout.reopen(wr)
        $stderr.reopen(wr)
        $stdout.sync = true
        $stderr.sync = true
        exec @command
      end
      self
    end

    def stop
      return if @pid.nil?
      _log 'stopping'
      Process.kill('TERM', @pid)
      Process.wait(@pid)
      @reader.join
      @pid = nil
      self
    end

    def wait_start
      return unless @start_regexp
      _log 'waiting to start'
      wait_log @start_regexp
      _log 'started'
    end

    def wait_stop
      return unless @stop_regexp
      wait_log @stop_regexp
    end

    def wait_log(regexp)
      Timeout::timeout(25) do
        until @loglines.pop =~ regexp
          sleep 50e-3
        end
      end
    end

    private

    def _read_log(io)
      while line = io.gets
        $stderr.write line # REMOVE ME
        $stderr.flush      #
        @loglines.push line
      end
    end

    def _log(message)
      $stderr.write("\t-> #{@name}: #{message}\n")
    end
  end

  WatchProcess = SubProcess.new(
    name:    'watch',
    command: 'ruby -I. watch.rb',
    start:   /INFO: starting watch service/,
    stop:    /INFO: watch completed/
  )

  WebProcess = SubProcess.new(
    name:    'web',
    command: 'unicorn -c config/unicorn.rb',
    start:   /worker=1 ready/,
    stop:    /master complete/
  )

  ClientProcess = SubProcess.new(
    name:    'client',
    command: 'unicorn -c spec/support/client.rb -p 17892 spec/support/client.ru',
    start:   /worker=1 ready/,
    stop:    /master complete/
  )

  ServerTunnelProcess = SubProcess.new(
    name:    'server-tunnel',
    command: 'ruby spec/support/tunnel 127.0.0.1:17893 127.0.0.1:17891',
    start:   /Ready/
  )

  ClientTunnelProcess = SubProcess.new(
    name:    'client-tunnel',
    command: 'ruby spec/support/tunnel 127.0.0.1:17894 127.0.0.1:17892',
    start:   /Ready/
  )

  Processes = [ServerTunnelProcess, ClientTunnelProcess, WatchProcess, WebProcess, ClientProcess]

  shared_examples 'start and stop' do
    before { subject.start }
    after  { subject.stop }

    it 'starts cleanly' do
      subject.wait_start
    end

    it 'stops cleanly' do
      subject.wait_start
      subject.stop
      subject.wait_stop
    end
  end

  context 'watch worker' do
    subject { WatchProcess }
    include_examples 'start and stop'
  end

  context 'web worker' do
    subject { WebProcess }
    include_examples 'start and stop'
  end

  context 'client worker' do
    subject { ClientProcess }
    include_examples 'start and stop'
  end

  context 'server tunnel' do
    subject { ServerTunnelProcess }
    include_examples 'start and stop'
  end

  context 'client tunnel' do
    subject { ClientTunnelProcess }
    include_examples 'start and stop'
  end

  context 'ruby client' do
    before { Processes.each(&:start) }
    before { Processes.each(&:wait_start) }
    after  { Processes.each(&:stop) }

    let(:client) {
      Routemaster::Client.new(url: 'https://127.0.0.1:17893', uuid: 'demo')
    }

    it 'connects' do
      expect { client }.not_to raise_error
    end

    it 'subscribes' do
      client.subscribe(
        topics: %w(widgets),
        callback: 'https://127.0.0.1:17894/events'
      )
    end
    
    it 'publishes' do
      client.created('widgets', 'https://example.com/widgets/1')
    end
  end
end
