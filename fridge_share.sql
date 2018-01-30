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
	fridge_location VARCHAR(255)
);

CREATE TABLE fridge_user_relationships (
	id SERIAL PRIMARY KEY,
	fridge_id INT,
	user_id INT,
	relationship INT,
	request_expire_date VARCHAR(255),
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
	goods_info_id INTEGER NOT NULL,
	goods_expire_date VARCHAR(255),
	goods_quantity INTEGER DEFAULT 1,
	goods_share_state BOOLEAN DEFAULT FALSE,
	FOREIGN KEY (fridge_id) REFERENCES fridges(id) ON DELETE CASCADE,
	FOREIGN KEY (goods_info_id) REFERENCES goods_infos(id) ON DELETE RESTRICT,
	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

INSERT INTO goods_infos (	
	goods_name,	
	goods_barcode,
	recommend_expire_period,
	category,
	brand,
	description,
	image_url,
	features,
	goods_attributes) VALUES (
	'12 pack 355 mL cans of Vanilla Coke',
	'EAN 0049776369867',
	365,
	'drink',
	'Coke',
	'12 cans of vanilla coke',
	'https://images-na.ssl-images-amazon.com/images/I/21gfuf%2B8-mL.jpg',
	'heavy',
	'{"Length"=>"0.4","Weight"=>"4.65 lbs"}');

	INSERT INTO goods_infos (	
	goods_name,	
	goods_barcode,
	recommend_expire_period,
	category,
	brand,
	description,
	image_url,
	features,
	goods_attributes) VALUES(	
	'Kraft Natural Cheese Finely Shredded Mozzarella Cheese, 8 oz',	
	'EAN 0021000638673',
	30,
	'dairy',
	'Kraft Foods Cheese & Dairy',
	'Low-moisture part-skim mozzarella cheese.',
	'https://images-na.ssl-images-amazon.com/images/I/51aZ3bsynUL.jpg',
	'keep freezing',
	'{"Length"=> "1","Width" => "6.5","Height:"=> "8.75","Weight"=>"599 lbs"}');