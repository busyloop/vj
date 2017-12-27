require 'vj/version'

require 'oj'
require 'optix'
require 'set'
require 'digest'
require 'paint'

module Vj
  class Cli < Optix::Cli
    TEMPLATE_OPTS = %i[before_key after_key before_value after_value].freeze
    cli_root do
      text "vj v#{Vj::VERSION}"
      opt :version, 'Print version and exit', short: :none
      trigger :version do
        puts "vj v#{Tc::VERSION}"
      end
    end

    parent :none
    opt :suppress, 'Suppress keys', type: :strings
    opt :prioritize, 'Prioritize keys', type: :strings
    opt :template, 'Template for JSON lines', short: :t, default: '\e[4m%{key}\e[0m \e[1m%{value}\e[0m  '
    opt :nonjson_template, 'Template for conversion of non-JSON lines to JSON', short: :T, default: '{ "E": "%{default_event_id}", "msg": "%{quoted_line}" }'
    opt :color_key, 'Color by key', short: :c, type: :string
    opt :default_event_id, 'Default event id', default: 'container'
    opt :light_background, 'Light terminal background', default: false
    opt :jsonify, 'Output JSON', short: :J
    text 'JSON Humanizer'
    def main(_cmd, opts, _argv)
      if ($stdout.isatty || ENV['FORCE_UNBUFFERED']) && ENV['FORCE_BUFFERED'].nil?
        $stdout.sync = true
        $stdin.sync = true
      end

      palette = bob_ross(opts[:light_background])
      opts[:prioritize] ||= []

      base_json = nil
      base_json_line_key = nil

      begin
        base_json = Oj.load(format(opts[:nonjson_template], default_event_id: opts[:default_event_id], quoted_line: '%{quoted_line}'))
        base_json.each_pair do |k, v|
          if v == '%{quoted_line}'
            base_json_line_key = k
            break
          end
        end
      rescue StandardError => e
        puts "Error: nonjson-template is not valid JSON (#{e})"
        exit 1
      end
      suppress_keys = Set.new(opts[:suppress])
      hash = nil
      STDIN.each do |line|
        line.chomp!
        next if line == ''
        begin
          hash = Oj.load(line)
          next if hash.nil?
        rescue StandardError => e
          hash = Marshal.load(Marshal.dump(base_json))
          hash[base_json_line_key] = line
        end

        if opts[:jsonify]
          puts Oj.dump(hash)
          next
        end

        color = nil
        if hash[opts[:color_key]]
          color = palette[Digest::MD5.hexdigest(hash[opts[:color_key]].to_s).to_i(16) % palette.length]
          print Paint[" #{hash[opts[:color_key]]} ", color, :inverse] + ' '
          hash.delete(opts[:color_key])
        end

        keys = hash.keys.sort
        opts[:prioritize].reverse.each do |pkey|
          keys.unshift(keys.delete(pkey)) if keys.include? pkey
        end

        keys.each do |k|
          next if suppress_keys.include?(k)
          v = hash[k]
          next if v.nil? || v == ''
          print Paint[eval(format('"%s"', format(opts[:template], key: k, value: v).tr('"', "\001"))).tr("\001", '"'), color]
        end
        puts
      end
    end

    def bob_ross(light = true)
      op = light ? :reject : :select
      Paint::RGB_COLORS.values.reject { |r, g, b| r == g && g == b }.send(op) { |r, g, b| (((r * 299) + (g * 587) + (b * 114)) / 1000.0 > 127) }
    end
  end
end
