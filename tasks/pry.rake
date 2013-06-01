task pry: :environment do
  require 'pry'
  Pry.start
end

desc 'Start Pry REPL'
task console: :pry
task c: :pry
