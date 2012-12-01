#
# Copyright:: Copyright (c) 2008-2012 Opscode, Inc.
# License:: Apache License, Version 2.0
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

require 'chef/log'
require 'chef/rest'
require 'chef/run_list'
require 'forwardable'

module ChefServer
  class RestClient
    extend Forwardable

    attr_reader :rest_client

    def_delegator :@rest_client, :fetch

    def initialize(chef_server_url,
                   client_name,
                   signing_key_filename,
                   options={})
      @rest_client = Chef::REST.new(chef_server_url,
                               client_name,
                               signing_key_filename,
                               options)
    end

    [:get, :post, :put, :delete].each do |method|
      define_method method do |*args|
        begin
          @rest_client.send("#{method}_rest".to_sym, *args)
        rescue => e
          Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
          raise e
        end
      end
    end

    def expand_run_list(environment, run_list_items)
      run_list_items = run_list_items.to_s if run_list_items.kind_of?(Chef::RunList)
      Chef::RunList.new(run_list_items).expand(environment, 'server', :rest => @rest_client)
    end
  end
end
