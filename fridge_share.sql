-- CREATE DATABASE fridge_db;

CREATE TABLE users (
	id SERIAL PRIMARY KEY,
	username VARCHAR(255),
	email VARCHAR(1024),
	password_digest VARCHAR(1024)
);

CREATE TABLE fridges (
	id SERIAL PRIMARY KEY,
	fridge_name VARCHAR(255),
	fridge_location VARCHAR(255),
	owner_id INT NOT NULL
);

CREATE TABLE fridge_user_relationships (
	id SERIAL PRIMARY KEY,
	fridge_id int,
	user_id int,
	relationship INT,
	FOREIGN KEY (fridge_id) REFERENCES fridges(id) ON DELETE CASCADE,
	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE goods_infos (
	id SERIAL PRIMARY KEY,
	goods_name VARCHAR(255),
	goods_barcode VARCHAR(255),
	recommend_expire_period INT,
	category VARCHAR(1024),
	brand VARCHAR(255),
	description VARCHAR(65536),
	image_url VARCHAR(1024),
	features VARCHAR(1024),
	goods_attributes VARCHAR(65536),
	reviews VARCHAR(65536)
);

CREATE TABLE goods_stores (
	id SERIAL PRIMARY KEY,
	user_id INTEGER NOT NULL,
	fridge_id INTEGER NOT NULL,
	goods_id INTEGER NOT NULL,
	goods_expire_date VARCHAR(255),
	goods_quantity INT,
	FOREIGN KEY (fridge_id) REFERENCES fridges(id) ON DELETE CASCADE,
	FOREIGN KEY (goods_id) REFERENCES goods_infos(id) ON DELETE RESTRICT,
	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);
