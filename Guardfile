guard 'bundler' do
  watch('Gemfile')
  watch('launchkey.gemspec')
end

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { 'spec' }
end

guard 'yard' do
  watch(%r{lib/.+\.rb})
end
