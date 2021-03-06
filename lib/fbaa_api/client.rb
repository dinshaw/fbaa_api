module FbaaApi
  class Client

    def initialize
      RestClient.log = config.logger
    end

    def get(path, params = {})
      request(:get, path, params)
    end

    def post(path, params = {})
      request(:post, path, params)
    end

    def put(path, params = {})
      request(:put, path, params)
    end

    def delete(path, params = {})
      request(:delete, path, params)
    end

    def create_ad(params = {})
      post 'ads', params
    end

    def update_ad(id, params = {})
      put "ads/#{id}", params
    end

    def get_ad(id, params = {})
      get "ads/#{id}", params
    end

    def validate_image(params = {})
      get "image_validations", params
    end

    private

    def request(method, path, params = {})
      url = "#{fbaa_url}/#{path}"
      config.logger.info("Fbaa::Client - #request url = #{url}")

      opts = {
        url: url,
        headers: headers(method, params),
        method: method
      }
      opts.merge!(payload: params.to_json) if method != :get

      req = RestClient::Request.new(opts)
      signed_req = signed_request(req)

      signed_req.execute do |response, request, result, &block|
        config.logger.info("Fbaa::Client - response code #{response.code}")
        config.logger.info("Fbaa::Client - body #{response.body}")

        case response.code
        when /^2[0-9]{2}$/ # 200 category response
          { status: response.code, body: JSON.parse(response.body) }
        when 401
          { status: 401, body: { 'error_messages' => 'Unauthorized' } }
        else
          body = response.body.empty? ? {}.to_json : response.body
          { status: response.code, body: JSON.parse(body) }
        end
      end
    rescue => e
      log_exception(e)
      raise e
    end

    def signed_request(request)
      ApiAuth.sign!(request, config.access_id, config.secret_key)
    end

    def fbaa_url
      @fbaa_url ||= "#{config.base_url}/api/#{config.api_version}"
    end

    def headers(method, params)
      _params = { 'Content-Type' => "application/json" }
      _params.merge!(params: params) if method == :get
      _params
    end

    def config
      FbaaApi.configuration
    end

    def log_exception(e)
      config.logger.error e.class.to_s
      config.logger.error e.message
      config.logger.error e.backtrace.join("\n")
    end

  end
end

