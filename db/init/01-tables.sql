
CREATE TABLE subscribers (
	id SERIAL PRIMARY KEY,
	email VARCHAR(512) UNIQUE NOT NULL,
	created_at TIMESTAMP DEFAULT current_timestamp,
	updated_at TIMESTAMP DEFAULT current_timestamp
);

CREATE TABLE users (
	id SERIAL PRIMARY KEY,
	user VARCHAR(128) UNIQUE NOT NULL,
	password_hash VARCHAR(256) NOT NULL,
	authority SMALLINT NOT NULL, -- Higher authority can do more
	created_at TIMESTAMP DEFAULT current_timestamp,
	updated_at TIMESTAMP DEFAULT current_timestamp	
);

