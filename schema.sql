CREATE TABLE users (
  id serial PRIMARY KEY,
  name varchar(60) UNIQUE NOT NULL,
  password text NOT NULL
);

CREATE TABLE watchlists (
  id serial PRIMARY KEY,
  name varchar(60) UNIQUE NOT NULL,
  user_id int NOT NULL REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE media (
  id serial PRIMARY KEY,
  name varchar(100) NOT NULL,
  platform varchar(60) NOT NULL,
  url text,
  watchlist_id int NOT NULL REFERENCES watchlists (id) ON DELETE CASCADE
);