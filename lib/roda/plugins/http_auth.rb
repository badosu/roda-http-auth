require "roda"
require "roda/plugins/http_auth/version"

module Roda::RodaPlugins
  module HttpAuth
    DEFAULTS = {
      realm: "Restricted Area",
      unauthorized_headers: ->(opts) do
        { 'WWW-Authenticate' => ('Basic realm="%s"' % opts[:realm]) }
      end,
      unauthorized: ->(r) {},
      schemes: %w[basic]
    }

    def self.configure(app, opts={})
      plugin_opts = (app.opts[:http_auth] ||= DEFAULTS)
      app.opts[:http_auth] = plugin_opts.merge(opts)
      app.opts[:http_auth].freeze
    end

    module InstanceMethods
      def http_auth(opts={}, &authenticator)
        auth_opts = request.roda_class.opts[:http_auth].merge(opts)
        authenticator ||= auth_opts[:authenticator]

        raise "Must provide an authenticator block" if authenticator.nil?

        auth = Rack::Auth::Basic::Request.new(env)

        unless auth.provided? && auth_opts[:schemes].include?(auth.scheme)
          unauthorized(auth_opts)
        end

        credentials = if auth.basic?
                        auth.credentials
                      elsif auth.scheme == 'bearer'
                        [env['HTTP_AUTHORIZATION'].split(' ', 2).last]
                      else
                        http_auth = env['HTTP_AUTHORIZATION'].split(' ', 2)
                                                             .last

                        creds = !http_auth.include?('=') ? http_auth :
                                  Rack::Auth::Digest::Params.parse(http_auth)

                        [auth.scheme, creds]
                      end

        if authenticator.call(*credentials)
          env['REMOTE_USER'] = auth.username
        else
          unauthorized(auth_opts)
        end
      end

      private

      def unauthorized(opts)
        response.status = 401
        response.headers.merge!(opts[:unauthorized_headers].call(opts))

        request.block_result(instance_exec(request, &opts[:unauthorized]))
        request.halt response.finish
      end
    end
  end

  register_plugin(:http_auth, HttpAuth)
end
