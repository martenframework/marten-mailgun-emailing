require "./spec_helper"

describe MartenMailgunEmailing::Backend do
  describe "#deliver" do
    it "delivers a simple email as expected" do
      WebMock
        .stub(:post, "https://api.mailgun.net/v3/sender.example.com/messages")
        .with(
          body: URI::Params.encode(
            {
              from:    "John Doe <from@example.com>",
              to:      "to@example.com",
              subject: "Hello World!",
              html:    "HTML body",
              text:    "Text body",
            }
          ),
          headers: {
            "Authorization" => "Basic #{Base64.strict_encode("api:api-key")}",
            "Content-Type"  => "application/x-www-form-urlencoded",
          }
        )
        .to_return(body: "")

      backend = MartenMailgunEmailing::Backend.new(api_key: "api-key", sender_domain: "sender.example.com")
      backend.deliver(MartenMailgunEmailing::BackendSpec::TestEmail.new)
    end

    it "delivers a simple email as expected when another API endpoint is specified" do
      WebMock
        .stub(:post, "https://api.eu.mailgun.net/v3/sender.example.com/messages")
        .with(
          body: URI::Params.encode(
            {
              from:    "John Doe <from@example.com>",
              to:      "to@example.com",
              subject: "Hello World!",
              html:    "HTML body",
              text:    "Text body",
            }
          ),
          headers: {
            "Authorization" => "Basic #{Base64.strict_encode("api:api-key")}",
            "Content-Type"  => "application/x-www-form-urlencoded",
          }
        )
        .to_return(body: "")

      backend = MartenMailgunEmailing::Backend.new(
        api_key: "api-key",
        sender_domain: "sender.example.com",
        api_endpoint: "https://api.eu.mailgun.net"
      )
      backend.deliver(MartenMailgunEmailing::BackendSpec::TestEmail.new)
    end

    it "delivers a simple email with CC addresses as expected" do
      WebMock
        .stub(:post, "https://api.mailgun.net/v3/sender.example.com/messages")
        .with(
          body: URI::Params.encode(
            {
              from:    "John Doe <from@example.com>",
              to:      "to@example.com",
              cc:      "cc1@example.com,cc2@example.com",
              subject: "Hello World!",
              html:    "HTML body",
              text:    "Text body",
            }
          ),
          headers: {
            "Authorization" => "Basic #{Base64.strict_encode("api:api-key")}",
            "Content-Type"  => "application/x-www-form-urlencoded",
          }
        )
        .to_return(body: "")

      backend = MartenMailgunEmailing::Backend.new(api_key: "api-key", sender_domain: "sender.example.com")
      backend.deliver(MartenMailgunEmailing::BackendSpec::TestEmailWithCc.new)
    end

    it "delivers a simple email with BCC addresses as expected" do
      WebMock
        .stub(:post, "https://api.mailgun.net/v3/sender.example.com/messages")
        .with(
          body: URI::Params.encode(
            {
              from:    "John Doe <from@example.com>",
              to:      "to@example.com",
              bcc:     "bcc1@example.com,bcc2@example.com",
              subject: "Hello World!",
              html:    "HTML body",
              text:    "Text body",
            }
          ),
          headers: {
            "Authorization" => "Basic #{Base64.strict_encode("api:api-key")}",
            "Content-Type"  => "application/x-www-form-urlencoded",
          }
        )
        .to_return(body: "")

      backend = MartenMailgunEmailing::Backend.new(api_key: "api-key", sender_domain: "sender.example.com")
      backend.deliver(MartenMailgunEmailing::BackendSpec::TestEmailWithBcc.new)
    end

    it "delivers a simple email with a reply-to address as expected" do
      WebMock
        .stub(:post, "https://api.mailgun.net/v3/sender.example.com/messages")
        .with(
          body: URI::Params.encode(
            {
              from:         "John Doe <from@example.com>",
              to:           "to@example.com",
              subject:      "Hello World!",
              html:         "HTML body",
              text:         "Text body",
              "h:Reply-To": "replyto@example.com",
            }
          ),
          headers: {
            "Authorization" => "Basic #{Base64.strict_encode("api:api-key")}",
            "Content-Type"  => "application/x-www-form-urlencoded",
          }
        )
        .to_return(body: "")

      backend = MartenMailgunEmailing::Backend.new(api_key: "api-key", sender_domain: "sender.example.com")
      backend.deliver(MartenMailgunEmailing::BackendSpec::TestEmailWithReplyTo.new)
    end

    it "delivers a simple email with with custom headers as expected" do
      WebMock
        .stub(:post, "https://api.mailgun.net/v3/sender.example.com/messages")
        .with(
          body: URI::Params.encode(
            {
              from:    "John Doe <from@example.com>",
              to:      "to@example.com",
              subject: "Hello World!",
              html:    "HTML body",
              text:    "Text body",
              "h:Foo": "bar",
            }
          ),
          headers: {
            "Authorization" => "Basic #{Base64.strict_encode("api:api-key")}",
            "Content-Type"  => "application/x-www-form-urlencoded",
          }
        )
        .to_return(body: "")

      backend = MartenMailgunEmailing::Backend.new(api_key: "api-key", sender_domain: "sender.example.com")
      backend.deliver(MartenMailgunEmailing::BackendSpec::TestEmailWithHeaders.new({"Foo" => "bar"}))
    end

    it "delivers a simple email with attachments as expected" do
      WebMock
        .stub(:post, "https://api.mailgun.net/v3/sender.example.com/messages")
        .with(
          body: MartenMailgunEmailing::BackendSpec.expected_attachment_body,
          headers: {
            "Authorization" => "Basic #{Base64.strict_encode("api:api-key")}",
            "Content-Type"  => "multipart/form-data; boundary=\"marten-mailgun-boundary\"",
          }
        )
        .to_return(body: "")

      backend = MartenMailgunEmailing::Backend.new(api_key: "api-key", sender_domain: "sender.example.com")
      backend.deliver(MartenMailgunEmailing::BackendSpec::TestEmailWithAttachment.new)
    end

    it "raises as expected if the response is not a success" do
      WebMock.stub(:post, "https://api.mailgun.net/v3/sender.example.com/messages").to_return do
        HTTP::Client::Response.new(400, body: "This is bad!")
      end

      backend = MartenMailgunEmailing::Backend.new(api_key: "api-key", sender_domain: "sender.example.com")

      expect_raises(MartenMailgunEmailing::Backend::UnexpectedResponseError, "This is bad!") do
        backend.deliver(MartenMailgunEmailing::BackendSpec::TestEmail.new)
      end
    end
  end
end

module MartenMailgunEmailing::BackendSpec
  def self.expected_attachment_body : String
    io = IO::Memory.new
    builder = HTTP::FormData::Builder.new(io, "marten-mailgun-boundary")

    builder.field("from", "John Doe <from@example.com>")
    builder.field("to", "to@example.com")
    builder.field("subject", "Hello World!")
    builder.field("html", "HTML body")
    builder.field("text", "Text body")
    builder.file(
      "attachment",
      IO::Memory.new("Attachment content"),
      HTTP::FormData::FileMetadata.new(filename: "test_attachment.txt"),
      HTTP::Headers{"Content-Type" => "text/plain"}
    )
    builder.finish

    io.to_s
  end

  class TestEmail < Marten::Email
    subject "Hello World!"
    to "to@example.com"

    def from
      Marten::Emailing::Address.new(address: "from@example.com", name: "John Doe")
    end

    def html_body
      "HTML body"
    end

    def text_body
      "Text body"
    end
  end

  class TestEmailWithCc < TestEmail
    cc ["cc1@example.com", "cc2@example.com"]
  end

  class TestEmailWithBcc < TestEmail
    bcc ["bcc1@example.com", "bcc2@example.com"]
  end

  class TestEmailWithReplyTo < TestEmail
    reply_to "replyto@example.com"
  end

  class TestEmailWithHeaders < TestEmail
    def initialize(@headers)
    end

    def headers
      @headers
    end
  end

  class TestEmailWithAttachment < TestEmail
    def initialize
      attach(IO::Memory.new("Attachment content"), filename: "test_attachment.txt")
    end
  end
end
