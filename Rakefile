require 'rake/testtask'

task default: %w[test]

Rake::TestTask.new do |t|
  t.libs = []
  t.test_files = FileList['test/**/test*.rb']
end

Rake::TestTask.new do |t|
  t.libs = []
  t.name = "test:models"
  t.test_files = FileList['test/models/test*.rb']
end

