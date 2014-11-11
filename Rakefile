require 'fileutils'
require 'bundler'
Bundler.require

namespace :build do
  desc 'compile coffee code'
  task :compile do
    sprockets = Sprockets::Environment.new(File.dirname(__FILE__)) { |env|
      # env.logger = Logger.new(STDOUT)
      env.append_path 'coffee'
    }

    # palava.js
    asset = sprockets['main.coffee']
    asset.write_to('palava.js')
    puts Paint["Successfully built palava.js", :green]

    # palava.min.js
    uglifier_options = JSON(File.read(File.dirname(__FILE__) + '/uglifier_options.json'))
    File.open('palava.min.js', 'w'){ |f|
      f.write Uglifier.compile File.read('palava.js'), uglifier_options
    }
    puts Paint["Successfully built palava.min.js", :green]
  end

  desc 'create bundle'
  task bundle: [:compile] do
    # palava.bundle.js
    sh 'npm install'
    FileUtils.rm 'palava.bundle.js'
    %w[
      node_modules/jquery/dist/jquery.min.js
      node_modules/wolfy87-eventemitter/EventEmitter.min.js
      palava.min.js
    ].each{ |input_file|
      File.open('palava.bundle.js', 'a'){ |f| f.puts File.read(input_file) }
    }
    FileUtils.rm_r 'node_modules'
    puts Paint["Successfully built palava.bundle.js", :green]
  end
end
