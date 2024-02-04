
CREATE TABLE subscribers (
	id SERIAL PRIMARY KEY,
	email VARCHAR(512) UNIQUE NOT NULL,
	created_at TIMESTAMP DEFAULT current_timestamp
	updated_at TIMESTAMP DEFAULT current_timestamp
);
