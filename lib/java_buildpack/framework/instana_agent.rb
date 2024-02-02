# frozen_string_literal: true

# Cloud Foundry Java Buildpack
# Copyright 2024 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module JavaBuildpack
  module Framework
    class InstanaAgent < JavaBuildpack::Component::VersionedDependencyComponent

      # Creates an instance
      #
      # @param [Hash] context a collection of utilities used the component
      def initialize(context)
        @application = context[:application]
        @component_name = self.class.to_s.space_case
        @configuration = context[:configuration]
        @droplet = context[:droplet]

        @version, @uri = standalone_agent_download_url if supports?
        @logger = JavaBuildpack::Logging::LoggerFactory.instance.get_logger InstanaAgent
      end

      def compile
        download_jar
      rescue StandardError => e
        @logger.warn('Instana Download failed :' + e.to_s)
      end

      def release
        @droplet.java_opts.add_javaagent(agent_path)
        setup_variables
      end

      def supports?
        @application.services.one_service? FILTER, AGENT_KEY, ENDPOINT_URL
      end

      def agent_path
        @droplet.sandbox + jar_name
      end

      def credentials
        @application.services.find_service(FILTER, AGENT_KEY, ENDPOINT_URL)['credentials']
      end

      private

      FILTER = /instana/.freeze
      AGENT_KEY = 'agentkey'
      ENDPOINT_URL = 'endpointurl'
      INSTANA_AGENT_KEY = 'INSTANA_AGENT_KEY'
      INSTANA_ENDPOINT_URL = 'INSTANA_ENDPOINT_URL'

      def standalone_agent_download_url
        # download_uri = "https://_:#{credentials[AGENT_KEY]}@artifact-public.instana.io/artifactory/rel-generic-instana-virtual/com/instana/standalone-collector-jvm/1.264.1/standalone-collector-jvm-1.264.1.jar"
        download_uri = 'https://imagestorage04.blob.core.windows.net/pub/standalone-collector-jvm-1.264.1.jar'
        ['latest', download_uri]
      end

      def setup_variables
        environment_variables = @droplet.environment_variables
        environment_variables
          .add_environment_variable(INSTANA_AGENT_KEY, credentials[AGENT_KEY])
          .add_environment_variable(INSTANA_ENDPOINT_URL, credentials[ENDPOINT_URL])
      end

    end
  end
end
