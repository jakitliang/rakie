Gem::Specification.new do |s|
  s.name               = "rakie"
  s.version            = "0.0.2"

  s.authors = ["Jakit Liang"]
  s.date = %q{2021-03-29}
  s.description = %q{Rakie is lucky and lucky}
  s.email = %q{jakitliang@163.com}
  s.files = [
    "lib/rakie.rb",
    "lib/rakie/channel.rb",
    "lib/rakie/event.rb",
    "lib/rakie/simple_server.rb",
    "lib/rakie/tcp_channel.rb",
    "lib/rakie/tcp_server_channel.rb",
    "Rakefile"
  ]
  s.test_files = ["test/test_rakie.rb"]
  s.homepage = %q{https://github.com/Jakitto/rakie}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Rakie!}
  s.license = 'BSD-2-Clause-Patent'
end