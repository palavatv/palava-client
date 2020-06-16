require 'fileutils'
require 'bundler'
Bundler.require

desc 'compile code (creates palava.js and palava.min.js)'
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

desc 'generate bundle file, which contains all dependencies (creates palava.min.js)'
task bundle: [:compile] do
  # palava.bundle.js
  sh 'npm install'
  FileUtils.rm 'palava.bundle.js'
  %w[
    node_modules/webrtc-adapter/out/adapter_no_edge.js
    node_modules/wolfy87-eventemitter/EventEmitter.min.js
    palava.min.js
  ].each{ |input_file|
    File.open('palava.bundle.js', 'a'){ |f| f.puts File.read(input_file) }
  }
  FileUtils.rm_r 'node_modules'
  puts Paint["Successfully built palava.bundle.js", :green]
end

desc 'generate codo documentation'
task :docs do
  sh 'codo -n "palava-client" -t "palava-client documentation" -o docs'
end

desc 'create bundle and docs'
task prepare_release: [:bundle, :docs]
