require 'rake/testtask'

Rake::TestTask.new(:spec) do |t|
  t.test_files = FileList['spec/**/*_spec.rb']
end

Rake::TestTask.new(:acceptance) do |t|
  t.test_files = FileList['acceptance/**/*_test.rb', 'acceptance/**/test_*.rb']
end

desc 'Run frontend tests (npm test)'
task :frontend do
  sh 'npm test'
end

task test: [:spec, :acceptance, :frontend]
task default: :test
