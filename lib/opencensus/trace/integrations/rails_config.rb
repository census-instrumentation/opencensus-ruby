# Copyright 2019 OpenCensus Authors
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
#

##
# The ActiveSupport notifications that will be reported as spans by
# default. To change this list, update the value of the
# `trace.notifications.events` configuration.
#
DEFAULT_NOTIFICATION_EVENTS = [
  "sql.active_record",
  "render_template.action_view",
  "send_file.action_controller",
  "send_data.action_controller",
  "deliver.action_mailer"
].freeze

OpenCensus::Trace.configure do |c|
  c.add_config! :notifications do |rc|
    rc.add_option! :attribute_namespace, "rails/"
    rc.add_option! :events, DEFAULT_NOTIFICATION_EVENTS.dup
  end
end
