# Recipe Scraper Skill

Extract a complete, accurate recipe from a YouTube video or Short.

## Instructions

The user will provide a YouTube URL. Run the recipe scraper script and display the result.

1. Extract the YouTube URL from the user's message
2. Run: `python3 ~/recipe_scraper.py <url>`
3. If they want JSON output: `python3 ~/recipe_scraper.py <url> --json`
4. If they want to save it: `python3 ~/recipe_scraper.py <url> --save`

Display the full output to the user. If confidence is "low" or missing_info is non-empty, flag that clearly so the user knows to double-check those parts.

## Usage examples the user might say
- `/recipe https://youtube.com/watch?v=...`
- `/recipe https://youtu.be/...`
- `/recipe https://youtube.com/shorts/...`
- `/recipe <url> --json`
- `/recipe <url> --save`
