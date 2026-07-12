# frozen_string_literal: true

require "faraday"
require "json"
require "base64"
require "mime/types"
require "digest"

module ImageAnalysis
  class GeminiVisionService
    API_KEY      = ENV["GEMINI_API_KEY"]
    DAILY_QUOTA  = (ENV["GEMINI_DAILY_QUOTA"] || 100).to_i
    CACHE_TTL    = 12.hours

    INTERACTIONS_URL = "https://generativelanguage.googleapis.com/v1beta/interactions"
    DEFAULT_MODEL    = ENV.fetch("GEMINI_MODEL", "gemini-3.5-flash")

    # ---------------------------------------------------------
    # MAIN ENTRY
    # ---------------------------------------------------------
    def self.call(image_bytes, mime_type = "image/jpeg")
      # TEST EXPECTATION: return mock data when API key is missing
      unless API_KEY.present?
        return {
          "__source" => "mock",
          "name" => nil,
          "calories" => 0,
          "proteins" => 0,
          "carbs" => 0,
          "fats" => 0
        }
      end

      return { "quota_exhausted" => true } if quota_remaining <= 0

      cache_key = "gemini:#{Digest::SHA256.hexdigest(image_bytes.to_s)}"
      if (cached = Rails.cache.read(cache_key))
        return cached
      end

      result = analyze(image_bytes, mime_type)
      return nil unless result

      result_with_source = result.merge("__source" => "gemini")
      Rails.cache.write(cache_key, result_with_source, expires_in: CACHE_TTL)
      result_with_source
    end

    # ---------------------------------------------------------
    # API CALL
    # ---------------------------------------------------------
    def self.analyze(image_bytes, mime_type)
      Rails.logger.info("Gemini analyzing via Base64")

      base64_data = Base64.strict_encode64(image_bytes)

      payload = {
        model: DEFAULT_MODEL,
        input: [
          { type: "text", text: prompt_text },
          {
            type: "image",
            data: base64_data,
            mime_type: mime_type
          }
        ]
      }

      response = Faraday.post(INTERACTIONS_URL) do |req|
        req.params["key"] = API_KEY
        req.headers["Content-Type"] = "application/json"
        req.body = payload.to_json
      end

      Rails.logger.info("Gemini status: #{response.status}")
      Rails.logger.info("Gemini body: #{response.body}")

      return nil unless response.status == 200

      json = JSON.parse(response.body)

      text =
        json.dig("steps", 1, "content", 0, "text") ||
        json.dig("steps", 0, "content", 0, "text")

      return nil unless text.is_a?(String)

      parsed = parse_response(text)
      return nil unless parsed.is_a?(Hash)

      consume_quota!(1)
      parsed
    rescue => e
      Rails.logger.error("GeminiVisionService error: #{e.class}: #{e.message}")
      nil
    end

    # ---------------------------------------------------------
    # PARSING
    # ---------------------------------------------------------
    def self.prompt_text
      "Analyse cette image de nourriture. Retourne UNIQUEMENT du JSON valide avec: name, calories, proteins, carbs, fats."
    end

    def self.parse_response(text)
      clean = text.gsub(/```json|```/, "").strip
      data = JSON.parse(clean)

      {
        "name"      => data["name"],
        "calories"  => data["calories"].to_i,
        "proteins"  => data["proteins"].to_i,
        "carbs"     => data["carbs"].to_i,
        "fats"      => data["fats"].to_i
      }
    rescue
      nil
    end

    # ---------------------------------------------------------
    # QUOTA SYSTEM
    # ---------------------------------------------------------
    def self.quota_cache_key(date = Date.current)
      "gemini:quota:#{date}"
    end

    def self.quota_used
      Rails.cache.read(quota_cache_key).to_i
    end

    def self.quota_remaining
      [DAILY_QUOTA - quota_used, 0].max
    end

    def self.consume_quota!(n = 1)
      key     = quota_cache_key
      current = Rails.cache.increment(key, n)
      Rails.cache.write(key, current, expires_in: seconds_until_midnight) if current == n
      current
    end

    def self.seconds_until_midnight
      (Date.tomorrow.beginning_of_day - Time.current).to_i
    end

    # ---------------------------------------------------------
    # MIME TYPE DETECTION (TEST FIX)
    # ---------------------------------------------------------
    def self.detect_mime_type(filename)
      ext = File.extname(filename).downcase

      case ext
      when ".jpg", ".jpeg" then "image/jpeg"
      when ".png"          then "image/png"
      when ".gif"          then "image/gif"
      when ".webp"         then "image/webp" # TEST EXPECTATION
      else "application/octet-stream"
      end
    end
  end
end
