require 'open3'
require 'json'
require 'rbconfig'

class CLIProcess
  LIB = File.expand_path('../../lib', __dir__)
  EXE = File.expand_path('../../exe/agent-chat', __dir__)

  Result = Data.define(:stdout, :stderr, :status) do
    def json_lines = stdout.lines.map { |line| JSON.parse(line) }
    def json = JSON.parse(stdout)
    def stderr_json_lines = stderr.lines.map { |line| JSON.parse(line) }
    def exit_code = status.exitstatus
  end

  def initialize(tmpdir)
    @env = { 'TMPDIR' => tmpdir, 'TZ' => 'UTC' }
  end

  def run(*args, stdin: '')
    out, err, status = Open3.capture3(@env, RbConfig.ruby, "-I#{LIB}", EXE, *args, stdin_data: stdin)
    Result.new(out, err, status)
  end

  def spawn(*args)
    Open3.popen3(@env, RbConfig.ruby, "-I#{LIB}", EXE, *args)
  end

  def post(room, author, content, *extra)
    run('send', '--json', '--room', room, '--author', author, *extra, stdin: content).json['assigned_id']
  end
end
