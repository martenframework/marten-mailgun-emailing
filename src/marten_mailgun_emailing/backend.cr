module MartenMailgunEmailing
  # A Mailgun emailing backend.
  class Backend < Marten::Emailing::Backend::Base
    # Raised upon receiving an unsuccessful response from Mailgun.
    class UnexpectedResponseError < Exception; end

    @url : String?

    def initialize(@api_key : String, @sender_domain : String, @api_endpoint : String = DEFAULT_API_ENDPOINT)
    end

    def deliver(email : Marten::Emailing::Email) : Nil
      response = if email.attachments.empty?
                   HTTP::Client.post(url, form: data_for_email(email), headers: headers)
                 else
                   payload, content_type = multipart_payload_for_email(email)
                   HTTP::Client.post(url, body: payload, headers: headers(content_type))
                 end

      raise UnexpectedResponseError.new(response.body) unless response.success?
    end

    private DEFAULT_API_ENDPOINT = "https://api.mailgun.net"
    private MULTIPART_BOUNDARY   = "marten-mailgun-boundary"

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

    private def headers(content_type : String? = nil)
      HTTP::Headers{
        "Authorization" => "Basic #{Base64.strict_encode("api:#{api_key}")}",
      }.tap do |headers|
        headers["Content-Type"] = content_type.not_nil! unless content_type.nil?
      end
    end

    private def mailgun_address(address)
      address.name ? "#{address.name} <#{address.address}>" : address.address
    end

    private def mailgun_addresses(addresses)
      addresses.compact.map { |address| mailgun_address(address) }.join(',')
    end

    private def multipart_payload_for_email(email : Marten::Emailing::Email)
      io = IO::Memory.new
      builder = HTTP::FormData::Builder.new(io, MULTIPART_BOUNDARY)

      data_for_email(email).each do |key, value|
        builder.field(key, value.to_s)
      end

      email.attachments.each do |attachment|
        builder.file(
          "attachment",
          IO::Memory.new(attachment.content),
          HTTP::FormData::FileMetadata.new(filename: attachment.filename),
          HTTP::Headers{"Content-Type" => attachment.mime_type}
        )
      end

      builder.finish
      {io.to_s, builder.content_type}
    end

    private def url
      @url ||= File.join(api_endpoint, "v3", sender_domain, "messages")
    end
  end
end
