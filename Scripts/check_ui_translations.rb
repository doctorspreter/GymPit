#!/usr/bin/env ruby
# frozen_string_literal: true

# Checks every literal passed to AppLanguage.ui and every text emitted by the
# trainer recommendation engine. German is the source string; all other app
# languages must be present in one of the UI translation tables.

ROOT = File.expand_path("..", __dir__)
LANGUAGE_FILE = File.join(ROOT, "Sources/GymPit/AppLanguage.swift")
SOURCE_GLOB = File.join(ROOT, "Sources/**/*.swift")
EXPECTED_LANGUAGES = %w[english french spanish italian russian chinese japanese].freeze

def unescape_swift_string(value)
  value.gsub('\\"', '"').gsub('\\\\', '\\')
end

def dictionary_block(source, marker)
  start = source.index(marker)
  raise "Translation table not found: #{marker}" unless start

  assignment = source.index("=", start)
  opening = source.index("[", assignment)
  depth = 0
  in_string = false
  escaped = false

  (opening...source.length).each do |index|
    character = source[index]
    if in_string
      if escaped
        escaped = false
      elsif character == "\\"
        escaped = true
      elsif character == '"'
        in_string = false
      end
      next
    end

    if character == '"'
      in_string = true
    elsif character == "["
      depth += 1
    elsif character == "]"
      depth -= 1
      return source[opening..index] if depth.zero?
    end
  end

  raise "Unterminated translation table: #{marker}"
end

translations = Hash.new { |hash, key| hash[key] = [] }
language_source = File.read(LANGUAGE_FILE)
%w[uiTextCorrections uiTexts additionalUITexts].each do |table|
  block = dictionary_block(language_source, "private static let #{table}")
  block.scan(/"((?:\\.|[^"])*)":\s*\[(.*?)\]\s*,?/m).each do |key, values|
    values.scan(/\.(#{EXPECTED_LANGUAGES.join('|')}):/).flatten.each do |language|
      translations[unescape_swift_string(key)] << language
    end
  end
end

used_keys = []
Dir.glob(SOURCE_GLOB).sort.each do |path|
  source = File.read(path)
  source.scan(/\b(?:appLanguage|language)\.ui\(\s*"((?:\\.|[^"])*)"/).each do |match|
    used_keys << unescape_swift_string(match.first)
  end
end

trainer_source = File.read(File.join(ROOT, "Sources/GymPit/TrainerRecommendation.swift"))
trainer_source.scan(/\b(?:title|explanation)\s*(?::|=)\s*"((?:\\.|[^"])*)"/).each do |match|
  used_keys << unescape_swift_string(match.first)
end
trainer_source.scan(/detailKeys\.append\("((?:\\.|[^"])*)"\)/).each do |match|
  used_keys << unescape_swift_string(match.first)
end

failures = used_keys.uniq.sort.map do |key|
  missing = EXPECTED_LANGUAGES - translations[key].uniq
  [key, missing] unless missing.empty?
end.compact

if failures.empty?
  puts "#{used_keys.uniq.length} UI keys are complete in all #{EXPECTED_LANGUAGES.length} target languages."
  exit 0
end

warn "Missing UI translations:"
failures.each { |key, missing| warn "- #{key}: #{missing.join(', ')}" }
exit 1
