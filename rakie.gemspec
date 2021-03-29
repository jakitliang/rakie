Gem::Specification.new do |s|
  s.name               = "rakie"
  s.version            = "0.0.1"
  s.default_executable = "rakie"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jakit Liang"]
  s.date = %q{2021-03-29}
  s.description = %q{Rakie is lucky and lucky}
  s.email = %q{jakitliang@163.com}
  s.files = ["Rakefile"]
  s.test_files = ["test/test_rakie.rb"]
  s.homepage = %q{https://github.com/Jakitto/rakie}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Rakie!}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end