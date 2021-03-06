module Specjour
  module Cucumber
    class Summarizer
      attr_reader :duration, :failing_scenarios, :step_summary, :output_path
      def initialize
        @duration = 0.0
        @failing_scenarios = []
        @step_summary = []
        @scenarios = Hash.new(0)
        @steps = Hash.new(0)
      end

      def output_path=(value)
        @output_path = value
      end

      def increment(category, type, count)
        current = instance_variable_get("@#{category}")
        current[type] += count
      end

      def add(stats)
        stats.each do |category, hash|
          if category == :failing_scenarios
            @failing_scenarios += hash
          elsif category == :step_summary
            @step_summary += hash
          elsif category == :duration
            @duration = hash.to_f if duration < hash.to_f
          else
            hash.each do |type, count|
              increment(category, type, count)
            end
          end
        end
      end

      def scenarios(status=nil)
        length = status ? @scenarios[status] : @scenarios.inject(0) {|h,(k,v)| h += v}
        any = @scenarios[status] > 0 if status
        OpenStruct.new(:length => length , :any? => any)
      end

      def steps(status=nil)
        length = status ? @steps[status] : @steps.inject(0) {|h,(k,v)| h += v}
        any = @steps[status] > 0 if status
        OpenStruct.new(:length => length , :any? => any)
      end
    end

    class FinalReport
      include ::Cucumber::Formatter::Console

      attr_accessor :output_path

      def initialize
        @features = []
        @summarizer = Summarizer.new
      end

      def add(stats)
        @summarizer.add(stats)
      end

      def exit_status
        @summarizer.failing_scenarios.empty?
      end

      def dump_yaml
        results = {
          :stats => {},
          :runtime => @summarizer.duration,
          :pending => []
        }

        [:passed, :pending, :failed, :undefined, :skipped].each do |status|
          results[:stats][status] = @summarizer.steps(status).length
        end

        results[:failures] = @summarizer.step_summary.map do |failure|
          failure.gsub(/\e\[\d+m/, '')
        end

        Dir.mkdir(output_path) unless File.exists?(output_path)
        File.open(File.join(output_path, 'features.yml'), 'w') do |f|
          f.write(results.to_yaml)
        end
      end

      def summarize
        return if @summarizer.steps.length == 0
        if @summarizer.steps(:failed).any?
          puts "\n\n"
          @summarizer.step_summary.each {|f| puts f }
        end

        if @summarizer.failing_scenarios.any?
          puts "\n\n"
          puts format_string("Failing Scenarios:", :failed)
          @summarizer.failing_scenarios.each {|f| puts f }
        end

        default_format = lambda {|status_count, status| format_string(status_count, status)}
        puts
        puts scenario_summary(@summarizer, &default_format)
        puts step_summary(@summarizer, &default_format)
        puts format_duration(@summarizer.duration) if @summarizer.duration

        dump_yaml if output_path
      end
    end
  end
end
