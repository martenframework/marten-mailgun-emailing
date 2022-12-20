ENV["MARTEN_ENV"] = "test"

require "spec"

require "marten"
require "marten/spec"
require "webmock"

require "../src/marten_mailgun_emailing"

Spec.before_each &->WebMock.reset
