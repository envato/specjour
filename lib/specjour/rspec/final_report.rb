module Specjour
  module Rspec
    class FinalReport
      attr_reader :duration, :example_count, :failure_count, :pending_count, :pending_examples, :failing_examples, :output_path

      def initialize
        @duration = 0.0
        @example_count = 0
        @failure_count = 0
        @pending_count = 0
        @pending_examples = []
        @failing_examples = []
      end

      def output_path=(value)
        @output_path = value
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

      def dump_yaml
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

        Dir.mkdir(output_path) unless File.exists?(output_path)
        File.open(File.join(output_path, 'specs.yml'), 'w') do |f|
          f.write(results.to_yaml)
        end
      end

      def summarize
        if example_count > 0
          formatter.dump_pending
          dump_failures
          formatter.dump_summary(duration, example_count, failure_count, pending_count)

          dump_yaml if output_path
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
