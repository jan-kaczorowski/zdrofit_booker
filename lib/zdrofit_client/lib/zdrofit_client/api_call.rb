module ZdrofitClient
  class ApiCall
    MAX_RETRIES = 3

    def initialize(client)
      @client = client
    end

    def call(**params)
      raise NotImplementedError
    end

    private

    attr_reader :client

    def post(path, body: {})
      with_retry do
        response = @client.class.post(
          path,
          headers: @client.authenticated_headers,
          body: body.to_json
        )

        raise "API call failed: #{response.body}" unless response.success?
        JSON.parse(response.body)
      end
    end

    def get(path, query: nil)
      with_retry do
        options = { headers: @client.authenticated_headers }
        options[:query] = query if query

        response = @client.class.get(path, options)

        raise "API call failed: #{response.body}" unless response.success?
        JSON.parse(response.body)
      end
    end

    def with_retry
      attempts = 0
      begin
        attempts += 1
        yield
      rescue => e
        if attempts < MAX_RETRIES
          sleep(1 * attempts)
          retry
        end
        raise e
      end
    end
  end
end
