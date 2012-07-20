# encoding: UTF-8

desc "use spork to run all tests"
task :stest do
    files = FileList["test/**/*_test.rb"].reject{|file|File.directory?(file)}
    Rake.sh "testdrb -Itest #{files}"
end
