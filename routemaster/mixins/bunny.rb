require 'routemaster/mixins'
require 'routemaster/models/bunny_channel'

module Routemaster
  module Mixins
    module Bunny
      def self.included(by)
        by.extend(self)
        by.send(:protected, :bunny)
      end

      def bunny
        Models::BunnyChannel.instance
      end

      def _bunny_name(string)
        "routemaster.#{ENV.fetch('RACK_ENV', 'development')}.#{string}"
      end
    end
  end
end
