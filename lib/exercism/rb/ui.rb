# frozen_string_literal: true

module Exercism
  module Rb
    class UI
      COLORS = {
        blue: "\e[34m",
        cyan: "\e[36m",
        green: "\e[32m",
        red: "\e[31m",
        yellow: "\e[33m",
        gray: "\e[90m",
        bold: "\e[1m",
        reset: "\e[0m"
      }.freeze

      def initialize(out: $stdout, err: $stderr, color: nil)
        @out = out
        @err = err
        @color = color.nil? ? default_color? : color
      end

      def say(message = "")
        @out.puts(message)
      end

      def title(message)
        @out.puts(bold(message))
      end

      def section(message)
        @out.puts(paint(message, :cyan))
      end

      def key_value(key, value, width: 8)
        label = key.to_s.ljust(width)
        @out.puts("#{paint(label, :gray)} #{value}")
      end

      def path(value)
        paint(value, :blue)
      end

      def highlight(value)
        paint(value, :bold)
      end

      def muted(value)
        paint(value, :gray)
      end

      def info(message)
        @out.puts(paint(message, :blue))
      end

      def success(message)
        @out.puts(paint(message, :green))
      end

      def warn(message)
        @err.puts(paint(message, :yellow))
      end

      def error(message)
        @err.puts(paint(message, :red))
      end

      def command(message)
        @out.puts(paint(message, :gray))
      end

      def bold(message)
        paint(message, :bold)
      end

      private

      def default_color?
        color_mode = ENV.fetch("XRB_COLOR", "").strip.downcase

        return true if %w[always force true yes 1].include?(color_mode)
        return false if %w[never none false no 0].include?(color_mode)
        return false if ENV.key?("NO_COLOR")
        return true if force_color?
        return false if ENV.fetch("CLICOLOR", nil) == "0"

        @out.tty?
      end

      def paint(message, color)
        return message unless @color

        "#{COLORS.fetch(color)}#{message}#{COLORS.fetch(:reset)}"
      end

      def force_color?
        value = ENV.fetch("CLICOLOR_FORCE", nil)
        !value.nil? && !value.empty? && value != "0"
      end
    end
  end
end
