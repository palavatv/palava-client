require 'bundler'
Bundler.require

namespace :coffee do
  desc 'compile coffee code'
  task :compile do
    sprockets = Sprockets::Environment.new(File.dirname(__FILE__)) { |env|
      # env.logger = Logger.new(STDOUT)
      env.append_path 'coffee'
    }

    asset = sprockets['main.coffee']
    asset.write_to('palava.js')
    puts Paint["Successfully built palava.js", :green]

    File.open('palava.min.js', 'w'){ |f|
      f.write Uglifier.compile File.read('palava.js'), {
        # uglifier options can be put here, see https://github.com/lautis/uglifier#usage
      }
    }
    puts Paint["Successfully built palava.min.js", :green]
  end
end
