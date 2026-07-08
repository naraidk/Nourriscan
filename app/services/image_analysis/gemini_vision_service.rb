require "faraday"
require "json"
require "base64"
require "digest"

module ImageAnalysis
  class GeminiVisionService
    MODELS = [
      ENV.fetch("GEMINI_MODEL", "gemini-1.5-flash"),
      "gemini-1.5-pro",
      "gemini-pro-vision"
    ].freeze
    CACHE_TTL = 12.hours
    API_KEY = ENV["GEMINI_API_KEY"]

    def self.call(image_url)
      if API_KEY.to_s.strip.empty?
        Rails.logger.warn("GEMINI_API_KEY not set, returning mock data")
        return CalorieEstimator.call(image_url)
      end

      cache_key = "gemini:#{Digest::SHA256.hexdigest(image_url)}"
      if (cached = Rails.cache.read(cache_key))
        Rails.logger.info("Gemini cache hit for #{image_url}")
        return cached
      end

      result = analyze(image_url)
      Rails.cache.write(cache_key, result, expires_in: CACHE_TTL) if result
      result || CalorieEstimator.call(image_url)
    end

    def self.analyze(image_url)
      Rails.logger.info("Analyzing image with Gemini: #{image_url}")

      file_bytes = Faraday.get(image_url).body
      base64 = Base64.strict_encode64(file_bytes)
      mime = detect_mime_type(image_url)

      MODELS.each do |model|
        Rails.logger.info("Trying Gemini model: #{model}")

        url = "https://generativelanguage.googleapis.com/v1/models/#{model}:generateContent"

        response = Faraday.post(url) do |req|
          req.params["key"] = API_KEY
          req.headers["Content-Type"] = "application/json"

          req.body = {
            contents: [
              {
                role: "user",
                parts: [
                  { text: prompt_text },
                  {
                    inline_data: {
                      mime_type: mime,
                      data: base64
                    }
                  }
                ]
              }
            ]
          }.to_json
        end

        Rails.logger.info("#{model} response status: #{response.status}")

        if response.status == 200
          json = JSON.parse(response.body)
          text = json.dig("candidates", 0, "content", "parts", 0, "text")

          if text
            Rails.logger.debug("Gemini raw response: #{text}")
            return parse_response(text)
          end
        elsif response.status == 429
          Rails.logger.warn("#{model} rate limited (429)")
          next
        else
          Rails.logger.error("#{model} error (#{response.status}): #{response.body[0..200]}")
          next
        end
      end

      Rails.logger.error("All Gemini models failed, falling back to mock")
      nil
    rescue => e
      Rails.logger.error("GeminiVisionService error: #{e.class}: #{e.message}")
      nil
    end

    def self.prompt_text
      "Analyse cette image de nourriture. Retourne UNIQUEMENT du JSON valide (pas de markdown, pas de code blocks) avec ces champs: name (string en francais), calories (entier), proteins (entier en g), carbs (entier en g), fats (entier en g). Exemple: {\"name\": \"Pizza\", \"calories\": 300, \"proteins\": 12, \"carbs\": 40, \"fats\": 10}"
    end

    def self.parse_response(text)
      json_text = text.strip

      json_text = json_text.sub(/^```json\n/, "").sub(/\n```$/, "") if json_text.start_with?("```")
      json_text = json_text.sub(/^```\n/, "").sub(/\n```$/, "") if json_text.start_with?("```")

      parsed = JSON.parse(json_text)

      {
        "name"      => (parsed["name"] || "Plat").to_s,
        "calories"  => (parsed["calories"] || 0).to_i,
        "proteins"  => (parsed["proteins"] || 0).to_i,
        "carbs"     => (parsed["carbs"] || 0).to_i,
        "fats"      => (parsed["fats"] || 0).to_i
      }
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse Gemini JSON: #{e.message}")
      nil
    end

    def self.detect_mime_type(image_url)
      ext = File.extname(URI.parse(image_url).path).downcase
      return "image/png" if ext == ".png"
      return "image/webp" if ext == ".webp"
      return "image/gif" if ext == ".gif"
      "image/jpeg"
    rescue
      "image/jpeg"
    end
  end
end
