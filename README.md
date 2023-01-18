# Marten Mailgun Emailing

[![CI](https://github.com/martenframework/marten-mailgun-emailing/workflows/Specs/badge.svg)](https://github.com/martenframework/marten-mailgun-emailing/actions)
[![CI](https://github.com/martenframework/marten-mailgun-emailing/workflows/QA/badge.svg)](https://github.com/martenframework/marten-mailgun-emailing/actions)

**Marten Mailgun Emailing** provides a [Mailgun](https://www.mailgun.com/) backend that can be used with Marten web framework's emailing system.

## Installation

Simply add the following entry to your project's `shard.yml`:

```yaml
dependencies:
  marten_mailgun_emailing:
    github: martenframework/marten-mailgun-emailing
```

And run `shards install` afterward.

## Configuration

First, add the following requirement to your project's `src/project.cr` file:

```crystal
require "marten_mailgun_emailing"
```

Then you can configure your project to use the Mailgun backend by setting the corresponding configuration option as follows:

```crystal
Marten.configure do |config|
  config.emailing.backend = MartenMailgunEmailing::Backend.new(
    api_key: ENV.fetch("MAILGUN_API_KEY"),
    sender_domain: ENV.fetch("MAILGUN_SENDER_DOMAIN")
  )
end
```

The `MartenMailgunEmailing::Backend` class needs to be initialized using a [Mailgun API key](https://documentation.mailgun.com/en/latest/api-intro.html#authentication-1) and a [Mailgun sender domain](https://documentation.mailgun.com/en/latest/user_manual.html#verifying-your-domain-1). You should ensure that these values are kept secret and that they are not hardcoded in your config files.

If needed, it should be noted that you can also change the Mailgun API endpoint URL (whose default value is **https://api.mailgun.net**). To do so, you can use set the `api_endpoint` argument accordingly when initializing your backend object:

```crystal
Marten.configure do |config|
  config.emailing.backend = MartenMailgunEmailing::Backend.new(
    api_key: ENV.fetch("MAILGUN_API_KEY"),
    sender_domain: ENV.fetch("MAILGUN_SENDER_DOMAIN"),
    api_endpoint: "https://api.eu.mailgun.net"
  )
end
```

## Authors

Morgan Aubert ([@ellmetha](https://github.com/ellmetha)) and 
[contributors](https://github.com/martenframework/marten/contributors).

## License

MIT. See ``LICENSE`` for more details.
