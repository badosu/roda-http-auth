# Roda Http Authorization

[![Build Status](https://travis-ci.org/badosu/roda-http-auth.png)](https://travis-ci.org/badosu/roda-http-auth)

Add http authorization methods to Roda.

## Configuration

Configure your Roda application to use this plugin:

```ruby
plugin :http_auth
```

You can pass global options, in this context they'll be shared between all
`http_auth` calls.

```ruby
plugin :http_auth, authenticator: ->(user, pass) { [user, pass] == %w[foo bar] },
                   realm: 'Restricted Area', # default
                   schemes: %w[basic] # default
```

## Usage

Call `http_auth` inside the routes you want to authenticate the user, it will halt
the request with an empty response with status 401 if the authenticator is false.

You can provide an `unauthorized` block to be invoked whenever the user is
unathorized, it's executed in the context of the instance:

```ruby
plugin :http_auth, unauthorized: -> { view('401.html') }

# ...

r.root do
  http_auth {|u, p| [u, p] == %w[foo bar] }

  "If you can see this you were authorized! \
   Otherwise you'll be served with the 401.html.erb template"
end
```

### Basic Auth

Basic authorization is the default method:

```ruby
# Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==
http_auth { |user, pass| [user, pass] == ['Aladdin', 'open sesame'] }
```

### Schemes

By default authorization schemes are whitelisted, so if you want to use one
that is not basic auth you must configure it:

```ruby
plugin :http_auth, schemes: %w[bearer]
```

You can also whitelist schemes for a specific route:

```ruby
http_auth(schemes: %w[bearer]) { |token| token == '4t0k3n' }
```

### Scheme: Bearer

When the `Bearer` scheme is passed, if whitelisted, the token is passed to
the authenticator:

```ruby
# Authorization: Bearer 4t0k3n
http_auth { |token| token == '4t0k3n' }
```

### Schemes with formatted parameters

For schemes that require formatted params authorization header, like `Digest`,
the scheme and the parsed params are passed to the authenticator:

```
# Request
Authorization: Digest username="Mufasa",
                      realm="http-auth@example.org",
                      uri="/dir/index.html",
                      algorithm=MD5,
                      nonce="7ypf/xlj9XXwfDPEoM4URrv/xwf94BcCAzFZH4GiTo0v",
                      nc=00000001,
                      cnonce="f2/wE4q74E6zIJEtWaHKaf5wv/H5QzzpXusqGemxURZJ",
                      qop=auth,
                      response="8ca523f5e9506fed4657c9700eebdbec",
                      opaque="FQhe/qaU925kfnzjCev0ciny7QMkPqMAFRtzCUYo5tdS"
```

```ruby
http_auth { |s, p| [s, p['username']] == ['digest', 'Mufasa'] }
```

## Warden

To avoid having your 401 responses intercepted by warden, you need to configure
the unauthenticated callback that is called just before the request is halted:

```ruby
plugin :http_auth, unauthorized: -> { env['warden'].custom_failure! }
```

## Additional Configuration

The header sent when the user is unauthorized can be configured via
`unauthorized_headers` and `realm` options, globally or locally:

```ruby
unauthorized_headers: ->(opts) do
  { 'WWW-Authenticate' => ('Basic realm="%s"' % opts[:realm]) }
end, # default
realm: "Restricted Area", # default
```

## Test

```sh
bundle exec ruby spec/*_spec.rb
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/badosu/roda-http-auth.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
