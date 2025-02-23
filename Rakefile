# frozen_string_literal: true

require_relative 'config/application'

Rails.application.load_tasks

unless Rails.env.production?
  require 'brakeman'

  require 'syntax_tree/rake_tasks'
  [SyntaxTree::Rake::CheckTask, SyntaxTree::Rake::WriteTask].each do |klass|
    klass.new do |t|
      t.source_files = FileList[%w[Gemfile Rakefile app/**/*.rb bin/**/*.rb config/**/*.rb spec/**/*.rb]]
      t.plugins = %w[plugin/single_quotes]
      t.print_width = 120
    end
  end

  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
end

task brakeman: :environment do
  result = Brakeman.run app_path: '.', print_report: true, pager: false

  unless result.filtered_warnings.empty?
    puts "Brakeman found #{result.filtered_warnings.count} warnings"
    exit 1
  end
end

task write_public_errors: :environment do
  StaticErrors.write_public_error_files
end

Rake::Task['assets:precompile'].enhance { Rake::Task['write_public_errors'].invoke }

task lint_js: :environment do
  puts 'Running javascript linting... '
  sh 'yarn run lint', verbose: false
end

task lint_js_fix: :environment do
  puts 'Running javascript linting... '
  sh 'yarn run lint --fix', verbose: false
end

task lint_rb: :environment do
  puts 'Running syntax tree on ruby... '
  sh "stree check '**/*.rb' '**/*.rake' Gemfile Rakefile", verbose: false
end

task lint_rb_fix: :environment do
  puts 'Running syntax tree on ruby... '
  sh "stree write '**/*.rb' '**/*.rake' Gemfile Rakefile", verbose: false
end

task lint_md: :environment do
  puts 'Running prettier on markdown... '
  sh "./node_modules/.bin/prettier --check '**/*.md'", verbose: false
end

task lint_md_fix: :environment do
  puts 'Running prettier on markdown... '
  sh "./node_modules/.bin/prettier --write '**/*.md'", verbose: false
end

task force_kill: :environment do
  puts 'force killing'
  Kernel.exit!(0)
end

task default: %i[lint_warn rspec]
task lint: %i[stree:write lint_md_fix rubocop:autocorrect_all lint_js_fix force_kill]
task lint_warn: %i[brakeman stree:check rubocop lint_md lint_js]
