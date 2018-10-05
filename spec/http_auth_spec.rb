require File.expand_path("spec_helper", File.dirname(__FILE__))

describe 'Roda::RodaPlugins::HttpAuth' do
  describe 'when unauthorized block is provided' do
    before do
      roda do |r|
        r.plugin :http_auth, authenticator: ->(u, p) { [u, p] == %w[foo bar] }
        r.plugin :render, views: 'spec/views'
      end

      error_root(unauthorized: ->(r) { render('403') })

      basic_authorize(*credentials)
    end

    describe 'and authenticator matches' do
      let(:credentials) { %w[notfoo notbar] }

      it 'is performed' do
        get '/'

        assert_match 'You were unauthorized!', last_response.body
        assert_unauthorized
      end
    end

    describe 'and authenticator matches' do
      let(:credentials) { %w[foo bar] }

      it 'proceeds with the request' do
        assert_raises('This code path should not have been reached') do
          get '/'
        end
      end
    end
  end

  describe 'when global authenticator is configured' do
    before do
      roda do |r|
        r.plugin :http_auth, authenticator: ->(u, p) { [u, p] == %w[foo bar] }
      end
    end

    describe 'and local authenticator is set' do
      before do
        app_root { |u, p| [u, p] == %w[baz inga] }

        basic_authorize(*credentials)

        get '/'
      end

      describe 'and new authenticator matches' do
        let(:credentials) { %w[baz inga] }

        it 'is authorized' do
          assert_authorized
        end
      end

      describe 'and new authenticator does not match' do
        let(:credentials) { %w[foo bar] }

        it 'is unauthorized' do
          assert_unauthorized
        end
      end
    end

    describe 'when no local authenticator is set' do
      before { app_root }

      describe 'and no credentials are passed' do
        before { get '/' }

        it('is unauthorized') { assert_unauthorized }
      end

      describe 'and credentials are passed' do
        before do
          basic_authorize(*credentials)

          get '/'
        end

        describe 'and they match the global authenticator' do
          let(:credentials) { %w[foo bar] }

          it('is authorized') { assert_authorized }
        end

        describe 'and they do not match the global authenticator' do
          let(:credentials) { %w[foo baz] }

          it('is unauthorized') { assert_unauthorized }
        end
      end
    end
  end

  describe 'when no global authenticator is configured' do
    before { roda { |r| r.plugin :http_auth } }

    describe 'and local authenticator is configured' do
      before do
        app_root { |u, p| [u, p] == %w[baz inga] }

        basic_authorize(*credentials)

        get '/'
      end

      describe 'and local authenticator matches' do
        let(:credentials) { %w[baz inga] }

        it('is authorized') { assert_authorized }
      end

      describe 'and local authenticator does not match' do
        let(:credentials) { %w[foo bar] }

        it('is unauthorized') { assert_unauthorized }
      end
    end

    describe 'and no local authenticator is configured' do
      it 'raises an error' do
        app_root

        exception = assert_raises(RuntimeError) { get '/' }

        assert_equal("Must provide an authenticator block", exception.message)
      end
    end
  end

  describe 'when realm is configured globally' do
    before { roda { |r| r.plugin :http_auth, realm: "NetherRealm" } }

    it 'is sent on WWW-Authenticate on unauthorization' do
      app_root { |u, p| [u, p] == %w[baz inga] }

      get '/'

      assert_unauthorized

      assert_equal("Basic realm=\"NetherRealm\"",
                   last_response['WWW-Authenticate'])
    end
  end

  describe 'when realm is configured locally' do
    before { roda { |r| r.plugin :http_auth } }

    it 'is sent on WWW-Authenticate on unauthorization' do
      app_root(realm: "NoetherRealm") { |u, p| [u, p] == %w[baz inga] }

      get '/'

      assert_unauthorized(realm: "NoetherRealm")
    end
  end

  describe 'when realm is not configured' do
    before { roda { |r| r.plugin :http_auth } }

    it 'sends "Restricted Area" on WWW-Authenticate on unauthorization' do
      app_root { |u, p| [u, p] == %w[baz inga] }

      get '/'

      assert_unauthorized

      assert_equal('Basic realm="Restricted Area"',
                   last_response['WWW-Authenticate'])
    end
  end

  describe 'when auth scheme is Bearer' do
    before do
      roda { |r| r.plugin :http_auth, schemes: %[bearer] }

      post_auth { |t| t == '4t0k3n' }

      header 'Authorization', "Bearer #{credentials}"

      post '/auth'
    end

    describe 'and local authenticator matches' do
      let(:credentials) { '4t0k3n' }

      it('is authorized') { assert_authorized }
    end

    describe 'and local authenticator does not match' do
      let(:credentials) { 'nottoken' }

      it('is unauthorized') { assert_unauthorized }
    end
  end

  describe 'when auth scheme is not Basic or Bearer' do
    it 'passes the scheme and parsed options if params formatted' do
      roda { |r| r.plugin :http_auth, schemes: %w[digest] }

      post_auth { |s, o| [s, o['username']] == ['digest', 'Mufasa'] }

      header 'Authorization', <<~HEREDOC
        Digest username="Mufasa",
               realm="http-auth@example.org",
               uri="/dir/index.html",
               algorithm=MD5,
               nonce="7ypf/xlj9XXwfDPEoM4URrv/xwf94BcCAzFZH4GiTo0v",
               nc=00000001,
               cnonce="f2/wE4q74E6zIJEtWaHKaf5wv/H5QzzpXusqGemxURZJ",
               qop=auth,
               response="8ca523f5e9506fed4657c9700eebdbec",
               opaque="FQhe/qaU925kfnzjCev0ciny7QMkPqMAFRtzCUYo5tdS"
      HEREDOC

      post '/auth'

      assert_authorized
    end

    it 'passes the whole authorization block if not params formatted' do
      roda { |r| r.plugin :http_auth, schemes: %w[token] }

      post_auth { |s, t| [s, t] == ['token', '4t0k3n'] }

      header 'Authorization', 'Token 4t0k3n'

      post '/auth'

      assert_authorized
    end

    it 'is unauthorized if the scheme is not whitelisted' do
      roda { |r| r.plugin :http_auth }

      post_auth { |s, t| [s, t] == ['token', '4t0k3n'] }

      header 'Authorization', 'Token 4t0k3n'

      post '/auth'

      assert_unauthorized
    end
  end
end
