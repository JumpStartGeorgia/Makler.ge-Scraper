# Makler.ge Scraper

This program scrapes real estate data from the site makler.ge and saves it to a database.

## Getting Started

1. `bundle install`
2. `cp .env-example .env`
3. Fill in `.env` variables. Unless you set ENVIRONMENT to production, emails will be sent to mailcatcher and you can use any fake email addresses you want.
4. Create mysql database and database user specified in `.env`
5. Optional: Load data in from compressed database file (`real-estate.sql.gz`). See section [The Data](https://github.com/JumpStartGeorgia/Makler.ge-Scraper/tree/email#the-data) below

## Usage

- `rake scraper:run` -> Run the scraper!
- `rake scraper:schedule:run_daily` -> Schedule a cron job to run `rake scraper:run` every day at 4 AM.

## Testing

No automatic test suite, but you can use

`rake scraper:test_run`

to manually test the scraper. Differences include:
- ENVIRONMENT cannot be set to production
- Only 20 ads will be scraped
- Emails will be sent to mailcatcher
- Database dump and status.json will not be pushed to github

Check [the code](https://github.com/JumpStartGeorgia/Makler.ge-Scraper/blob/email/app/scraper.rb) for further differences. To setup mailcatcher, [see here](http://mailcatcher.me/).

## How it Works

When you run the scraper, the following happens:

1. Choose Ads to Scrape: The scraper checks the status.json for the `last_id_processed`. Requests are sent to makler.ge's lists of ads to gather ids to be scraped. These ids are saved in status.json's `ids_to_process`; this process continues until the last_id_processed ids are found.
2. Scrape Ads: Requests are sent to makler.ge to the ads listed in `ids_to_process` and are saved as `data.json` files in the `data` folder
3. Save Ads to Database: The ad info in the new `data.json` files are saved to the database.
4. Update Github with New Data: The database is dumped to `real-estate.sql.gz` and pushed to github, along with the new `status.json` file.
5. Send Email Report on Scraper Run: A report about the scrape run, including basic statistics and logged errors, is sent to the recipient specified in the `.env` file.

## The Data

The database is pushed with every scrape run to the github repo. That means you can use what others have already scraped to start out your database of makler.ge real estate data. However, because updating github is built into the app, you will have to do one of the following:

1. Setup your own origin repo on github to receive your new scrape data.
2. Disable pushes to github.
