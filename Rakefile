require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = ["ontologies_api_client"]
  t.test_files = FileList['test/**/test*.rb']
end

Rake::TestTask.new do |t|
  t.libs = ["ontologies_api_client"]
  t.name = "test:models"
  t.test_files = FileList['test/models/test*.rb']
end

