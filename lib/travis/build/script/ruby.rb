module Travis
  module Build
    class Script
      class Ruby < Script
        DEFAULTS = {
          rvm:     'default',
          gemfile: 'Gemfile'
        }

        include Jdk
        include RVM

        def setup
          super
          setup_bundler
        end

        def announce
          super
          cmd 'gem --version'
        end

        def install
          gemfile? do |sh|
            sh.if "-f #{config[:gemfile]}.lock" do
              sh.cmd bundler_command("--deployment"), fold: 'install', retry: true
            end

            sh.else do
              sh.cmd bundler_command, fold: 'install', retry: true
            end
          end
        end

        def script
          gemfile? then: 'bundle exec rake', else: 'rake'
        end

        private

          def bundler_command(args = nil)
            args = bundler_args if bundler_args
            ["bundle install", args].compact.join(" ")
          end

          def bundler_args
            config[:bundler_args]
          end

          def setup_bundler
            gemfile? do |sh|
              set 'BUNDLE_GEMFILE', "$PWD/#{config[:gemfile]}"
              cmd 'gem query --local | grep bundler >/dev/null || gem install bundler'
            end
          end

          def gemfile?(*args, &block)
            self.if "-f #{config[:gemfile]}", *args, &block
          end

          def uses_java?
            config[:rvm] =~ /jruby/i
          end

          def uses_jdk?
            uses_java? && super
          end
      end
    end
  end
end
