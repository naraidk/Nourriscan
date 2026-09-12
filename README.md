<img width="980" height="1348" alt="Image" src="https://github.com/user-attachments/assets/cc4a5953-2950-43ab-ae6f-5783f5557b33" />

## Nourriscan — AI Food Analysis
Nourriscan is a lightweight AI‑powered tool that turns a simple food photo into a quick nutritional breakdown. Upload an image, and the app identifies the food using the Google Gemini Vision API, then estimates calories and macros.
I built Nourriscan to explore how modern AI can enhance everyday tasks inside a Ruby on Rails application.

## Nourriscan — Analyse alimentaire intelligente
Nourriscan est une application simple qui permet d’analyser un plat à partir d’une photo. L’idée est de rendre la nutrition plus accessible : tu prends une image de ton repas, l’IA identifie les aliments et te donne une estimation des calories et des informations nutritionnelles.
C’est un projet que j’ai développé avec l’intégration d’IA dans Ruby on Rails, en utilisant Google Gemini Vision pour la reconnaissance d’images.

## Technologies
- Ruby on Rails
- JavaScript
- PostgreSQL
- Turbo Stream
- Gemini Vision API

## Features
- Image Analysis : Upload a photo and let the AI detect the food
- Calorie Estimation : Automatic calculation of calories and macros
- Meal History : Keep track of previously scanned meals
- Minimal UI : One upload page, one results page
- Clear Output : Clean, readable nutritional results

## The Process
I started by setting up a classic Rails structure with models, controllers, and ActiveStorage for image handling.
From there, I built a dedicated service to communicate with the Gemini Vision API, transforming raw image data into meaningful nutritional information.

The app was developed iteratively: upload → analyze → display.
Every step focused on keeping the experience simple and easy to understand.

## What I Learned
- Integrating AI APIs into a Rails backend
- Building clean Ruby services for external API calls
- Handling uncertain or incomplete AI responses
- Designing around a single, focused user flow
- Improving code quality with Rubocop and GitHub Actions

## Possible Improvements
- More detailed nutrition database
- Better multi‑food detection
- Editable results when the AI misidentifies something
- Favorites or meal‑tracking features
- A more modern UI with animations
- Live camera scanning

## Demo

https://github.com/user-attachments/assets/c319e5b7-dfdf-4d29-a519-8bce897ff3a6
