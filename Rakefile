require 'rspec/core/rake_task'
require 'rake/clean'
require_relative 'lib/erescat_annual_stats'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :run do
  queries = ObjectSpace.each_object(EresStats::Query.singleton_class).
            reject { |q| q == EresStats::Query }

  desc 'Run all queries'
  task :all do
    queries.each do |q|
      puts q.name.split('::').last
      q.new.write_results
    end
    Rake::Task['run:summary_count'].invoke
  end

  # creates, e.g., run:StreamingVideoNoncoll
  queries.each do |query|
    name = query.name.split('::').last.to_sym
    desc "Run query for: #{name}"
    task name do
      query.new.write_results
    end
  end

  task :summary_count do
    File.open('summary_counts.txt', 'w') do |ofile|
      Dir['*.txt'].each do |filename|
        unless filename == 'summary_counts.txt'
          ofile << "#{filename}\t#{File.foreach(filename).count - 1}\n"
        end
      end
    end
  end
end
