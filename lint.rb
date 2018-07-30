require 'active_support'
require 'active_support/core_ext/hash'

require 'json'
require 'pry-byebug'


class Scope
  attr_reader :selectors
  attr_accessor :name, :settings

  def initialize(selectors)
    @selectors = selectors
    @name = nil
    @settings = []
  end

  def equal?(rhs)
    @selectors == rhs.selectors
  end

  def include?(rhs)
    raise ArgumentError unless rhs.kind_of? String
    @selectors.include? rhs
  end

  def to_s
    [
      '{',
      {
        name: name.present? ? "\"#{name}\"" : nil,
        selectors: selectors,
        settings: settings,

      }.compact.map {|k, v|
        "  #{k}: #{v}"
      }.join(",\n"),

      '}',

    ].join("\n")
  end
end


class Linter
  def initialize(path)
    @json = JSON.parse(
      File.read(path),
      symbolize_keys: true
    )
    @tokenColors = @json['tokenColors'].map(&:symbolize_keys)

    @colors = {}
  end

  def analyze
    @tokenColors.each do |cfg|
      scope = Scope.new(Array.wrap(cfg[:scope]))
      scope.name = cfg[:name]
      scope.settings = cfg[:settings]

      begin
        @colors.keys.map {|s|
          common = (s.selectors & scope.selectors)
          if common.present?
            puts "--------------------------------------------"
            puts "multiple scopes have same selectors in common:\n  [#{common.join(', ')}]\n\n"
            puts "scope [1]: #{s}"
            puts "scope [2]: #{scope}"
            puts ''
          end
        }

      ensure
        @colors[scope] = cfg[:settings]
      end
    end
  end
end

linter = Linter.new(Pathname.new('themes').join %q{Color7.tmTheme.json})
linter.analyze
