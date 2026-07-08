# Gemini Vision Service Integration

## ✅ Your Setup is Ready

Your Nourriscan app now uses **real Gemini AI** to analyze food images. No more mocks!

### What's Active

1. **Real Gemini API Integration** – `app/services/image_analysis/gemini_vision_service.rb`
2. **Your API Key** – Already set in `.env`
3. **Smart Prompt** – Instructs Gemini to analyze nutritional content
4. **Caching** – Results cached for 12 hours to save API quota
5. **Turbo Streams** – Real-time UI updates as analysis completes

---

## How It Works (Step by Step)

### 1. **User Uploads Image**
```
Browser → Form (data-turbo: false) → Rails Controller
```
- Form submits as **standard HTML** (not Turbo Stream)
- Redirects to `/dishes/:id` show page
- Shows **loading spinner** while analysis runs

### 2. **Background Job Analyzes Image**
```
DishAnalysisJob.perform_later(@dish.id)
  ↓
GeminiVisionService.call(image_url)
  ↓
Gemini API analyzes image
  ↓
Returns: { name, calories, proteins, carbs, fats }
```

**Gemini sees:**
- Food type (pasta, salad, burger, etc.)
- Portion size and plating
- Visible ingredients

**Gemini calculates:**
- Approximate calories for the portion
- Protein content (grams)
- Carbohydrates (grams)
- Fat content (grams)

### 3. **Results Broadcast in Real-Time**
```
Job updates database: dish.update(name:, calories:, proteins:, carbs:, fats:)
  ↓
Turbo Streams broadcast to connected browsers
  ↓
Browser replaces:
  - #dish-title → Shows dish name
  - #analysis-results → Shows nutrition facts
  - #analysis-loading → Removes spinner
```

---

## Expected Results

When you upload an image of **Spaghetti Bolognese**, Gemini will return:

```json
{
  "name": "Spaghetti Bolognese",
  "calories": 450,
  "proteins": 15,
  "carbs": 55,
  "fats": 18
}
```

Your UI will display:
```
Spaghetti Bolognese

Analyse en cours…  ← Spinner (loading)
  ↓ (After ~5-10 seconds)
Calories : 450
Protéines : 15 g
Glucides : 55 g
Lipides : 18 g
```

---

## API Quota & Caching

- **Gemini API**: Free tier = 15 requests/minute, 1.5M tokens/month
- **Caching**: Same image analyzed once, cached for 12 hours
- **Cost**: Mostly free (unless you hit enterprise limits)

---

## Debugging

### If analysis returns 0s or mock data:

1. **Check your API key:**
   ```bash
   echo $GEMINI_API_KEY
   ```
   Should print your key, not empty.

2. **Check logs:**
   ```bash
   tail -f log/development.log | grep -i gemini
   ```

3. **Check Gemini status:**
   - Go to: https://status.cloud.google.com/
   - Verify Generative Language API is running

4. **Test API directly:**
   ```bash
   rails console
   ImageAnalysis::GeminiVisionService.call("https://your-image-url.jpg")
   ```

---

## File Reference

| File | Purpose |
|------|---------|
| `app/services/image_analysis/gemini_vision_service.rb` | Real Gemini API integration |
| `app/services/image_analysis/calorie_estimator.rb` | Fallback mock (when API fails) |
| `app/jobs/dish_analysis_job.rb` | Background job that calls service + broadcasts |
| `app/controllers/dishes_controller.rb` | Handles form submission, redirects to show |
| `app/views/dishes/new.html.erb` | Form with `data-turbo: false` for HTML submission |
| `app/views/dishes/show.html.erb` | Page with turbo_stream subscription + spinner |
| `app/views/dishes/_analysis_results.html.erb` | Partial that displays nutrition facts |
| `.env` | Your GEMINI_API_KEY credential |

---

## Testing

Tests verify the service correctly:
- ✅ Parses Gemini JSON responses
- ✅ Handles markdown-wrapped JSON
- ✅ Converts string numbers to integers
- ✅ Provides defaults for missing fields
- ✅ Detects image MIME types

Run tests:
```bash
rails test test/services/image_analysis/gemini_vision_service_test.rb
```

---

## Next Steps

1. **Upload a real food image** and watch it analyze in real-time
2. **Monitor logs** to see Gemini responses
3. **Tweak the prompt** in `gemini_vision_service.rb` if results aren't accurate
4. **Consider language**: Change "analyse cette image de nourriture" if needed

---

## Prompt Customization

If you want more specific analysis, edit the prompt in `gemini_vision_service.rb`:

```ruby
def self.prompt_text
  <<~TEXT
    # Add more specific instructions here
    # E.g.: "Assume standard restaurant portion sizes"
    # E.g.: "Include estimated fiber content"
  TEXT
end
```

Then restart your server for changes to take effect.

---

## More Info

- [Gemini API Docs](https://ai.google.dev/docs)
- [Vision Capabilities](https://ai.google.dev/docs/vision_api)
- [Get API Key](https://ai.google.dev/)
