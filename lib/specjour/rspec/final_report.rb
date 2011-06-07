module Specjour
  module Rspec
    class FinalReport
      attr_reader :duration, :example_count, :failure_count, :pending_count, :pending_examples, :failing_examples

      def initialize
        @duration = 0.0
        @example_count = 0
        @failure_count = 0
        @pending_count = 0
        @pending_examples = []
        @failing_examples = []
      end

      def add(stats)
        stats.each do |key, value|
          if key == :duration
            @duration = value.to_f if duration < value.to_f
          else
            increment(key, value)
          end
        end
      end

      def exit_status
        failing_examples.empty?
      end

      def increment(key, value)
        current = instance_variable_get("@#{key}")
        instance_variable_set("@#{key}", current + value)
      end

      def formatter_options
        @formatter_options ||= OpenStruct.new(
          :colour   => true,
          :autospec => false,
          :dry_run  => false
        )
      end

      def formatter
        @formatter ||= begin
          f = Spec::Runner::Formatter::BaseTextFormatter.new(formatter_options, $stdout)
          f.instance_variable_set(:@pending_examples, pending_examples)
          f
        end
      end

      def dump_yaml(path)
        results = {
          :stats => {
            :passed => (example_count - failure_count - pending_count),
            :failed => failure_count,
            :pending => pending_count,
            :undefined => 0, # what is this?
          },
          :runtime => duration
        }

        results[:failures] = failing_examples.map do |failure|
          ([failure.header, failure.exception.message] + failure.exception.backtrace).join("\n")
        end

        results[:pending] = pending_examples.map do |pending|
          "'#{pending[0]}' @ #{pending[2]}"
        end

        File.open(path, 'w') do |f|
          f.write(results.to_yaml)
        end
      end

      def summarize
        if ENV['OUTPUT_PATH']
          dump_yaml(ENV['OUTPUT_PATH'])
        end

        if example_count > 0
          formatter.dump_pending
          dump_failures
          formatter.dump_summary(duration, example_count, failure_count, pending_count)
        end
      end

      def dump_failures
        failing_examples.each_with_index do |failure, index|
          formatter.dump_failure index + 1, failure
        end
      end
    end
  end
end
