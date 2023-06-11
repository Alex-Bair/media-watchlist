# Background

In the modern video streaming environment, there are [multiple platforms](https://en.wikipedia.org/wiki/List_of_streaming_media_services) that offer a wide variety of different media to consume.  Think Netflix, Hulu, Peacock, Crave, YouTube, and so many more.

Each platform typically has functionality to keep track of which media a user wants to watch, but this is limited to only that platform's media. For example, you can't add Letterkenny (available on Hulu) to your My List in Netflix. 

This application aims to address this by providing a centralized location to keep track of which media a user wants to watch on any given platform; it creates cross-platform watchlists.

Users can create a profile, create watchlists based on their needs (ex: Favorites, Movies with Friends, Horror, Comedy, etc.), then populate those watchlists with media. Media must have a name and a platform specified. Media with a URL specified will make the media's name a hyperlink to the provided URL; this can be a handy way to easily start watching a media.

The home page can be viewed by clicking "Watchlist App" in the top left corner or by clicking "HOME" at the bottom of the screen.

## Vocabulary

**Watchlist** - a list of media
**Media** - a video that can be watched online.
**Platform** - the streaming service where a specified media can be watched (ex: Netflix, Hulu, YouTube, etc.)

# Software Requirements

This application was developed using:
Ruby version 3.2.2
Google Chrome version 114.0.5735.110 (Official Build) (64-bit)
PostgreSQL version 9.2.24

# Installation Instructions

Prerequisites:
- Ensure PostgreSQL is installed and running.
- A `media_watchlist` database does not already exist in the PostgreSQL server.
- Ensure Ruby is installed.

To run the application:
1. Unzip the project onto a location on your computer.
2. Run `bundle install` from the project's root directory (`media_watchlist_project`) to ensure the required gems are installed.
	- This only needs done once per installation.
	- Note: If installing on AWS Cloud 9 and the `pg` gem does not install, you may need to run `sudo yum install postgresql-devel` before running `bundle install`.
3. Run `ruby app.rb` from the project's root directory.
4. (Optional): To import seed data, run `ruby lib/import_seed_data.rb` from the project's root directory.
	- WARNING: This will remove all existing data in the database!
	- For the seed data, the created username is `admin` with the password `supersecret`.
	- The Music watchlist contains multiple media to demonstrate pagination between pages of media.

# Assumptions

- The user has installed PostgreSQL and has the database server running.
- The application should automatically create the database and the tables in PostgreSQL upon startup.
	- I was unsure if it was acceptable to have the grader create the database and schema using an SQL file, so I decided to just have the application create the database and tables if they don't already exist.

# Design Decisions

- The `Watchlist` and `Media` classes help encapsulate watchlist and media attributes. Getter methods help read these attributes, making rendering information in ERB view templates relatively straightforward.
- On lines 36 - 44 in `app.rb`, the watchlist id and media id are validated as needed. I decided to validate these ids before creating `Watchlist` and `Media` objects in order to avoid making invalid `Watchlist` and `Media` objects. However, this adds 1-2 additional database queries to check if the ids are valid. If we needed to optimize our database interactions, we could validate watchlist and media ids after creating `Watchlist` and `Media` objects, then check if the `Watchlist` or `Media` object's attributes are `nil` - meaning the database did not have a matching `id`.
- On lines 111 - 115 and lines 184 - 190, `GET` routes are listed that have the same path as the preceding `POST` routes. This is to ensure that any URL that appears in the user's browser is valid. 
	- If the user tries to create a new watchlist with an invalid name, the browser will display the same content with an error message but with a URL with the path `/new_watchlist`. Without lines 111 - 115, if the user then sends a `GET` request with the URL in the browser, there will be an error.
- Only 5 items (watchlists or media) will be displayed per page.
- Providing a URL for a media is optional. This allows users to quickly populate a watchlist without having to navigate to the streaming platform, find the media, and copy the URL. The URL can then be provided later, if at all.
- Media can be deleted, but they cannot be "checked off" as watched. Personally, my watchlists grow faster than I can watch media they contain. It takes a few seconds to add media to a watchlist, but it can take many hours to watch a given media (depending on how many episodes, seasons, etc.). Keeping track of already watched media encourages *re-watching* the same media. The purpose of the app is to track unwatched media and encourage chipping away at an every growing watchlist, not to track already watched media.
- I attempted to use Sinatra's `redirect back` syntax to redirect the user back to the previous page if they are signed in already and send `GET` requests for `/users/sign_in` or `/users/register`. However, this did not work since it relies on the HTTP `referer` header. Many browsers don't automatically send an HTTP `referer` header due to privacy concerns, meaning `redirect back` was not a browser-agnostic solution. Instead, I set `session[:previous_path]` in an `after` filter to achieve the same functionality.
- Some basic CSS was added to make the project a little more visually appealing.