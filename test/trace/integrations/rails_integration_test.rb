# Copyright 2017 OpenCensus Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fileutils"
require "open3"
require "timeout"

require "faraday"
require "test_helper"
require "opencensus/trace/integrations/rails"

describe "Rails integration" do
  module RailsTestHelper
    APP_NAME = "railstest"
    TEMPLATE_PATH = File.absolute_path(File.join __dir__, "rails51_app_template.rb")
    BASE_DIR = File.dirname File.dirname File.dirname __dir__
    TMP_DIR = File.join BASE_DIR, "tmp"
    APP_DIR = File.join TMP_DIR, APP_NAME
    RAILS_OPTIONS = %w(
        --skip-yarn
        --skip-action-mailer
        --skip-active-record
        --skip-action-cable
        --skip-puma
        --skip-sprockets
        --skip-spring
        --skip-listen
        --skip-coffee
        --skip-javascript
        --skip-turbolinks
        --skip-test
        --skip-system-test
        --skip-bundle
      ).join ' '

    class << self
      def create_rails_app
        puts "**** Creating test Rails app..."
        FileUtils.mkdir_p TMP_DIR
        FileUtils.rm_rf APP_DIR
        Dir.chdir TMP_DIR do
          system "bundle exec rails new #{APP_NAME} #{RAILS_OPTIONS} -m #{TEMPLATE_PATH}"
        end
        Dir.chdir APP_DIR do
          Bundler.with_original_env do
            original_gemfile = ENV.delete "BUNDLE_GEMFILE"
            begin
              system "bundle lock"
              system "bundle install --deployment"
            ensure
              ENV["BUNDLE_GEMFILE"] = original_gemfile if original_gemfile
            end
          end
        end
        puts "**** Finished creating test Rails app"
      end

      def run_rails_app timeout: 5
        Dir.chdir APP_DIR do
          Bundler.with_original_env do
            Open3.popen2e "bundle exec rails s -p 3000" do |_in, out, thr|
              begin
                Timeout.timeout timeout do
                  loop do
                    line = out.gets
                    break if !line || line =~ /WEBrick::HTTPServer#start/
                  end
                  yield out if block_given?
                end
              ensure
                Process.kill("INT", thr.pid)
              end
            end
          end
        end
      end

      def capture_in_rails_context cmd, timeout: 6
        result = nil
        Dir.chdir APP_DIR do
          Bundler.with_original_env do
            Timeout.timeout timeout do
              result = `#{cmd}`
            end
          end
        end
        result
      end

      def rails_request path
        resp = Faraday.get "http://localhost:3000#{path}"
        resp.body
      end
    end
  end

  RailsTestHelper.create_rails_app unless ENV["FASTER_TESTS"]

  it "traces incoming requests" do
    skip if ENV["FASTER_TESTS"]
    RailsTestHelper.run_rails_app do |stream|
      result = RailsTestHelper.rails_request "/"
      result.must_equal "OK"
      loop do
        line = stream.gets
        break if !line || line =~ /"trace_id":"\w{32}"/
      end
    end
  end

  it "inserts middleware at the end" do
    skip if ENV["FASTER_TESTS"]
    result = RailsTestHelper.capture_in_rails_context "bundle exec bin/rails middleware"
    result = result.split("\n")
    result[-2].must_equal "use OpenCensus::Trace::Integrations::RackMiddleware"
  end
end
