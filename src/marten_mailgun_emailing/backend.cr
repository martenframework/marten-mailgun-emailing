module MartenMailgunEmailing
  # A Mailgun emailing backend.
  class Backend < Marten::Emailing::Backend::Base
    # Raised upon receiving an unsuccessful response from Mailgun.
    class UnexpectedResponseError < Exception; end

    @headers : HTTP::Headers?
    @url : String?

    def initialize(@api_key : String, @sender_domain : String, @api_endpoint : String = DEFAULT_API_ENDPOINT)
    end

    def deliver(email : Marten::Emailing::Email) : Nil
      response = HTTP::Client.post(url, form: data_for_email(email), headers: headers)
      raise UnexpectedResponseError.new(response.body) unless response.success?
    end

    private DEFAULT_API_ENDPOINT = "https://api.mailgun.net"

    private getter api_endpoint
    private getter api_key
    private getter sender_domain

    private def data_for_email(email)
      data = {
        "from"       => mailgun_address(email.from),
        "to"         => mailgun_addresses(email.to),
        "cc"         => email.cc.try { |cc| cc.empty? ? nil : mailgun_addresses(cc) },
        "bcc"        => email.bcc.try { |bcc| bcc.empty? ? nil : mailgun_addresses(bcc) },
        "subject"    => email.subject,
        "html"       => email.html_body,
        "text"       => email.text_body,
        "h:Reply-To" => email.reply_to.try(&.address),
      }

      email.headers.each do |k, v|
        data["h:#{k}"] = v
      end

      data.compact
    end

    private def headers
      @headers ||= HTTP::Headers{
        "Authorization" => "Basic #{Base64.strict_encode("api:#{api_key}")}",
      }
    end

    private def mailgun_address(address)
      address.name ? "#{address.name} <#{address.address}>" : address.address
    end

    private def mailgun_addresses(addresses)
      addresses.compact.map { |address| mailgun_address(address) }.join(',')
    end

    private def url
      @url ||= File.join(api_endpoint, "v3", sender_domain, "messages")
    end
  end
end
