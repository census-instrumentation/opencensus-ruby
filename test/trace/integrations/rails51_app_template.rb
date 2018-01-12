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

base_dir = File.absolute_path File.dirname File.dirname File.dirname __dir__
gem "opencensus", path: base_dir

application "require 'opencensus/trace/integrations/rails'"
application "OpenCensus::Trace.configure.exporter = OpenCensus::Trace::Exporters::Logger.new(::Logger.new(STDERR, ::Logger::INFO))"

route "root to: 'home#index'"

file "app/controllers/home_controller.rb", <<-CODE
  class HomeController < ApplicationController
    def index
      render plain: "OK"
    end
  end
CODE
