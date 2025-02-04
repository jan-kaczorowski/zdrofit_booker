module ZdrofitClient
  class ApiCall
    def initialize(client)
      @client = client
    end

    def call(**params)
      raise NotImplementedError
    end

    private

    attr_reader :client

    def post(path, body: {})
      response = @client.class.post(
        path,
        headers: @client.authenticated_headers,
        body: body.to_json
      )

      raise "API call failed: #{response.body}" unless response.success?
      JSON.parse(response.body)
    end

    def get(path, query: nil)
      options = { headers: @client.authenticated_headers }
      options[:query] = query if query

      response = @client.class.get(path, options)

      raise "API call failed: #{response.body}" unless response.success?
      JSON.parse(response.body)
    end
  end
end
