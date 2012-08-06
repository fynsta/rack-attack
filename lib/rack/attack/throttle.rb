module Rack
  module Attack
    class Throttle
      attr_reader :name, :limit, :period, :block
      def initialize(name, options, block)
        @name, @block = name, block
        [:limit, :period].each do |opt|
          raise ArgumentError.new("Must pass #{opt.inspect} option") unless options[opt]
        end
        @limit  = options[:limit]
        @period = options[:period]
      end

      def cache
        Rack::Attack.cache
      end

      def [](req)
        discriminator = block[req]
        return false unless discriminator

        key = "#{name}:#{discriminator}"
        count = cache.count(key, period)
        (count > limit).tap do |throttled|
          if throttled
            req.env['rack.attack.matched']    = name
            req.env['rack.attack.match_type'] = :throttle
            req.env['rack.attack.match_data'] = {:count => count, :period => period, :limit => limit}
            Rack::Attack.instrument(req)
          end
        end
      end

    end
  end
end