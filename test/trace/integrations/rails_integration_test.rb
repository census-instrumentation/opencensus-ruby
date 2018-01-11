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
require "test_helper"
require "opencensus/trace/integrations/rails"
require "faraday"

describe "Rails integration" do
  module RailsTestHelper
    APP_NAME = "railstest"
    BASE_DIR = File.absolute_path File.dirname File.dirname File.dirname __dir__
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
          system "bundle exec rails new #{APP_NAME} #{RAILS_OPTIONS}"
        end
        Dir.chdir APP_DIR do
          File.open "Gemfile", "a" do |f|
            f.puts "gem 'opencensus', path: '#{BASE_DIR}'"
          end
          insert_after "config/application.rb", /Bundler\.require/,
                       ["require 'opencensus/trace/integrations/rails'",
                        "OpenCensus::Trace.configure.exporter = ",
                        "  OpenCensus::Trace::Exporters::Logger.new(",
                        "    ::Logger.new(STDERR, ::Logger::INFO))"]
          insert_after "config/routes.rb", /routes\.draw/, "  root 'home#index'"
          File.open "app/controllers/home_controller.rb", "w" do |f|
            f.puts "class HomeController < ApplicationController"
            f.puts "  def index; render plain: 'OK'; end"
            f.puts "end"
          end
          Bundler.with_original_env do
            system "pwd"
            system "env"
            system "bundle config"
            system "bundle lock"
            system "bundle install --deployment"
          end
        end
        puts "**** Finished creating test Rails app"
      end

      def insert_after path, regex, new_lines
        data = File.read path
        File.open path, "w" do |file|
          data.each_line do |line|
            file.puts line
            if regex && regex =~ line
              Array(new_lines).each { |new_line| file.puts new_line }
              regex = nil
            end
          end
        end
        raise "Unable to find #{regex.inspect} in #{path.inspect}" if regex
      end

      def run_rails_app timeout: 5
        Dir.chdir APP_DIR do
          Bundler.with_original_env do
            Open3.popen2e "bundle exec rails s -p 3000" do |_in, out, thr|
              begin
                Timeout.timeout 5 do
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

      def rails_request path
        resp = Faraday.get "http://localhost:3000#{path}"
        resp.body
      end
    end
  end

  RailsTestHelper.create_rails_app

  it "traces incoming requests" do
    RailsTestHelper.run_rails_app do |stream|
      result = RailsTestHelper.rails_request "/"
      result.must_equal "OK"
      loop do
        line = stream.gets
        break if !line || line =~ /"trace_id":"\w{32}"/
      end
    end
  end
end
