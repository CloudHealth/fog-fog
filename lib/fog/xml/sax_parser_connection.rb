module Fog
  module XML
    class SAXParserConnection < Fog::Core::Connection

      # Makes a request using the connection using Excon
      #
      # @param [Hash] params
      # @option params [String] :body text to be sent over a socket
      # @option params [Hash<Symbol, String>] :headers The default headers to supply in a request
      # @option params [String] :host The destination host's reachable DNS name or IP, in the form of a String
      # @option params [String] :path appears after 'scheme://host:port/'
      # @option params [Fixnum] :port The port on which to connect, to the destination host
      # @option params [Hash]   :query appended to the 'scheme://host:port/path/' in the form of '?key=value'
      # @option params [String] :scheme The protocol; 'https' causes OpenSSL to be used
      # @option params [Proc] :response_block
      # @option params [Nokogiri::XML::SAX::Document] :parser
      #
      # @return [Excon::Response]
      #
      # @raise [Excon::Errors::StubNotFound]
      # @raise [Excon::Errors::Timeout]
      # @raise [Excon::Errors::SocketError]
      #
      def request(parser, params)
        reset unless @persistent

        begin
          # Prepare the SAX parser
          data_stream = Nokogiri::XML::SAX::PushParser.new(parser)
          response_string = ""
          params[:response_block] = lambda do |chunk, remaining, total|
            response_string << chunk if ENV['DEBUG_RESPONSE']
            data_stream << chunk
          end

          # Make request which read chunks into parser
          response = @excon.request(params)
          Fog::Logger.debug "\n#{response_string}" if ENV['DEBUG_RESPONSE']
        ensure
          # Make sure to always call finish to prevent a memory leak in JRuby
          data_stream.finish rescue nil
        end
        # Override response.body with parsed data
        response.body = parser.response
        response
      end
    end
  end
end
