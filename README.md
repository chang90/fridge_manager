# ![alt text](https://github.com/hiby90hou/MyShoppingList/blob/master/graphic%20design/logo_v1/mipmap-hdpi/ic_launcher.png "MyShoppingList Logo") Fridge Manager
## Introduction
Fridge manager app can help people to record food storage information in their fridge.

You can click [this link](https://cryptic-ocean-77629.herokuapp.com/) to see a demo.

## User story
### Story one
I am a young person who share house with others, and I also need to share fridge with my roommate. However, when I brought some food and put them to fridge, I always forgot which item is belong to me. In some case, when I eat my roommate's food, he is not happy. In other case, no one can remember the food is belong to who, and we just let it expired in the fridge because all of us think this item belong to other people. I need a app to 
remind me which item in the fridge is belong to me, and its expired date.

### Story two
I am a house wife who lives in a big house and has many children, so I have many fridges in my house. I cannot findout the right item in a short time, because I need to open each fridge to find this item. I need a record list to remind me which item stay in which fridge, without open all the fridge.

## The technologies used
* Bootstrap -- frontend
* Sinatra -- backend server
* ActiveRecord -- backend server
* Psql -- backend server
* Heroku -- hoster

## The approach taken
1. Make a simple UX wireframes design to make sure the user can login, manage fridge and the item in this fridge.

2. Create [database design draft](https://github.com/hiby90hou/fridge_manager/blob/master/database_design.jpg?raw=true) base on my UX design.

3. Create a user management system base on a database table called users, which can sign up and sign in user.

4. Create a fridge management system base on a database table called fridges, which can store fridge's information. Connect this database with user database by using a join table called fridge_user_relationships.

5. Create a food record list base on a database table called goods_stores. This food record list connect to user information and fridge information. So a front end table can be shown to the user and remind them the food is belong to who and in which fridge base on this database.

## Installation instructions

1. Clone git to local
```
$ git clone https://github.com/hiby90hou/fridge_manager.git
```

2. Create a database called "fridge_db" in psql and init 5 tables in it

Terminal:
```
$ psql

```

Psql:
```
CREATE DATABASE fridge_db;
\q
```

Terminal:
```
$ psql -d fridge_db < fridge_share.sql

```

3. Install gems
```
$ bundle install
```

4. Run this app
```
$ ruby main.rb
```
5. Check the browser in localhost:4567

## Unsolved problems

1. Missing a function to highlight the expired item

2. Missing a function to sort the food list in each fridge by food expired date

3. The email verification is incomplete due to heroku has a different add-on
