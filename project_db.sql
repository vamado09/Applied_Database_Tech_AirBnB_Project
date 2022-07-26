CREATE DATABASE project;

DROP TABLE IF EXISTS location;
DROP TABLE IF EXISTS user;
DROP TABLE IF EXISTS host;
DROP TABLE IF EXISTS listing;
DROP TABLE IF EXISTS specification;
DROP TABLE IF EXISTS review;

DROP TABLE IF EXISTS exploratory;

Error Code: 3730. Cannot drop table 'listing' referenced by a foreign key constraint 'fk_listing_id' on table 'review'.
Error Code: 3730. Cannot drop table 'listing' referenced by a foreign key constraint 'f_k_listing_id' on table 'specification'.



alter table specification
drop foreign key f_k_listing_id;


CREATE TABLE IF NOT EXISTS location(
	location_id INT auto_increment PRIMARY KEY, -- PRIMARY KEY,
	neighbourhood_group_cleansed VARCHAR(100),
	neighbourhood_cleansed VARCHAR(100),
	latitude VARCHAR(100), #Varchar instead of decimals because of MySQL error 1264 out of range value
	longitude VARCHAR(100)
);

# Insert values from listings into location
INSERT INTO location (neighbourhood_group_cleansed, neighbourhood_cleansed, latitude, longitude)
SELECT neighbourhood_group_cleansed, neighbourhood_cleansed, latitude, longitude
FROM listings;

CREATE TABLE IF NOT EXISTS user(
user_id INT auto_increment PRIMARY KEY, -- PRIMARY KEY,
username VARCHAR(100),
email VARCHAR(100),
password VARCHAR(100),
phone VARCHAR(100)
);

## insert values into user table using shiny?

CREATE TABLE IF NOT EXISTS host(
host_id INT PRIMARY KEY, -- PRIMARY KEY,
host_url LONGTEXT,
host_name VARCHAR(100),
host_since VARCHAR(100),
host_location VARCHAR(100),
host_response_time VARCHAR(100),
host_acceptance_rate VARCHAR(100),
host_is_superhost CHAR(1) CHECK(host_is_superhost IN ('t', 'f')), 
host_thumbnail_url LONGTEXT,
host_neighbourhood VARCHAR(100),
host_total_listings_count int,
host_has_profile_pic CHAR(1) CHECK(host_has_profile_pic IN ('t', 'f')), 
host_identity_verified CHAR(1) CHECK(host_identity_verified IN ('t', 'f')) 
);


INSERT INTO host (host_id, host_url, host_name, host_since, host_location, host_response_time, host_acceptance_rate, host_is_superhost, host_thumbnail_url, host_neighbourhood, host_total_listings_count, host_has_profile_pic, host_identity_verified)
SELECT DISTINCT host_id, host_url, host_name, host_since, host_location, host_response_time, host_acceptance_rate, host_is_superhost, host_thumbnail_url, host_neighbourhood, host_total_listings_count, host_has_profile_pic, host_identity_verified
FROM listings 
where host_id <> 2206506 or host_since not like '%/1914%';
commit;


CREATE TABLE IF NOT EXISTS listing(
listing_id INT PRIMARY KEY,
location_id INT auto_increment,
host_id INT,
listing_url LONGTEXT,
#name, description, neighborhood_overview, and amenities are gone
price VARCHAR(100),
minimum_nights INT,
maximum_nights INT,
availability_30 INT,
availability_60 INT,
availability_90 INT,
availability_365 INT,
number_of_reviews INT,
first_review VARCHAR(100),
last_review VARCHAR(100),
CONSTRAINT f_k_location_id FOREIGN KEY (location_id) REFERENCES location (location_id),
CONSTRAINT f_k_host_id FOREIGN KEY (host_id) REFERENCES host (host_id)
);

INSERT INTO listing(listing_id, host_id, listing_url, price, minimum_nights, maximum_nights, availability_30, availability_60, availability_90, availability_365, number_of_reviews, first_review, last_review)
SELECT id, host_id, listing_url, price, minimum_nights, maximum_nights, availability_30, availability_60, availability_90, availability_365, number_of_reviews, first_review, last_review
FROM listings;

CREATE TABLE IF NOT EXISTS specification(
specification_id INT auto_increment PRIMARY KEY, -- PRIMARY KEY
listing_id INT,
room_type VARCHAR(100),
accommodates VARCHAR(100),
bathrooms_text VARCHAR(100),
bedrooms CHAR(2),
beds INT,
CONSTRAINT f_k_listing_id FOREIGN KEY (listing_id) REFERENCES listing (listing_id)
);

INSERT INTO specification (listing_id, room_type, accommodates, bathrooms_text, bedrooms, beds)
SELECT id, room_type, accommodates, bathrooms_text, bedrooms, beds
FROM listings;


CREATE TABLE IF NOT EXISTS review(
review_id INT auto_increment PRIMARY KEY, -- PRIMARY KEY
listing_id INT,
review_scores_rating DECIMAL(3,2),
review_scores_accuracy DECIMAL(3,2),
review_scores_cleanliness DECIMAL(3,2),
review_scores_checkin DECIMAL(3,2),
review_scores_communication DECIMAL(3,2),
review_scores_location DECIMAL(3,2),
review_scores_value DECIMAL(3,2),
CONSTRAINT fk_listing_id FOREIGN KEY (listing_id) REFERENCES listing (listing_id)
);

INSERT INTO review (listing_id, review_scores_rating, review_scores_accuracy, review_scores_cleanliness, review_scores_checkin, review_scores_communication, review_scores_location, review_scores_value)
SELECT id, review_scores_rating, review_scores_accuracy, review_scores_cleanliness, review_scores_checkin, review_scores_communication, review_scores_location, review_scores_value
FROM listings;


# Basic Exploratory Queries ##################

#Created a new table "exploratory" to performed basic analysis
CREATE TABLE IF NOT EXISTS exploratory(
listing_id INT PRIMARY KEY,
listing_url LONGTEXT,
host_id INT,
host_is_superhost CHAR(1), ####
room_type VARCHAR(100),
accommodates VARCHAR(100),
beds INT,
minimum_nights INT,
maximum_nights INT,
review_scores_rating decimal(3,2),
location_id INT,
neighbourhood_group_cleansed VARCHAR(100),
neighbourhood_cleansed VARCHAR(100),
price decimal
);


INSERT INTO exploratory(listing_id, listing_url, host_id, host_is_superhost, room_type, accommodates, beds, minimum_nights, maximum_nights, review_scores_rating, location_id, neighbourhood_group_cleansed, neighbourhood_cleansed, price)
select listing.listing_id, listing.listing_url, listing.host_id, host.host_is_superhost, specification.room_type, specification.accommodates, specification.beds, listing.minimum_nights, listing.maximum_nights, review.review_scores_rating, listing.location_id, location.neighbourhood_group_cleansed, location.neighbourhood_cleansed,replace(replace(listing.price,'$',''),',','')
from listing
left join specification # left join
on listing.listing_id = specification.listing_id
left join review # left join
on listing.listing_id = review.listing_id
left join host # left join
on listing.host_id = host.host_id
left join location #left join
on listing.location_id = location.location_id;

#listing.price

select *
from exploratory;


