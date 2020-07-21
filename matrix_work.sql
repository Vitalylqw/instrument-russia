-- создадим служебную БД
DROP  database test_matrix;

CREATE DATABASE IF NOT EXISTS  test_matrix CHARACTER SET utf8 COLLATE utf8_general_ci;

USE test_matrix;

-- Таблица  import_data в служебной БД 

DROP table IF EXISTS import_data;

CREATE TABLE import_data (
id SERIAL PRIMARY KEY,
model varchar(64) NOT NULL UNIQUE,
name varchar(255) NOT NULL,
quantity int,
manufacturer varchar(64),
minimum int,
price decimal(15,4) NOT NULL,
category_id  int NOT NULL,
width float,
photo varchar(255),
description TEXT NOT NULL,
UNIQUE un_model_idx(model));

-- сколько элементов в таблице import_data
SELECT count(*) FROM import_data; 

-- создадим таблицу с категориями
DROP table IF EXISTS category;

CREATE TABLE category (
id SERIAL PRIMARY KEY,
name varchar(255) NOT NULL,
category_id int NOT NULL UNIQUE,
parentId int NOT NULL,
UNIQUE cat_category_id_idx(category_id));

CREATE INDEX cat__parentId_idx ON category(parentId);

-- Почистим таблицу категорий
SELECT * from category where parentId =3380;

DELETE FROM category 
	WHERE category_id IN (3380) OR parentId IN (3380);

SELECT model,category_id from import_data id where category_id IN (3071,3370,3367,3366,3365,3363,3358,3355,3354,3330,3353);

-- загрузим данные в таблицу os_category
INSERT INTO instr_russia.oc_category 
(
category_id,
parent_id,
top,
`column`,
sort_order,
status,
date_added,
date_modified
)
SELECT
category_id,
parentId,
1,
3,
0,
1,
NOW(),
NOW()
FROM category;

-- загрузим  oc_category_description
TRUNCATE instr_russia.oc_category_description ;

INSERT INTO instr_russia.oc_category_description 
(
category_id,
language_id,
name,
description,
meta_title,
meta_h1,
meta_description,
meta_keyword
)
SELECT
category_id,
1,
name,
CONCAT(name,descr_cat(category_id)),
name,
name,
CONCAT(name,descr_cat(category_id)),
CONCAT(name,descr_cat(category_id))
FROM category;

-- заполним таблицу oc_category_to_store
TRUNCATE instr_russia.oc_category_to_store;
INSERT INTO instr_russia.oc_category_to_store 
	SELECT category_id,0 FROM category;

-- Запрос на вставку в таблицу url_alias для категорий
TRUNCATE instr_russia.oc_manufacturer;

INSERT INTO instr_russia.oc_url_alias (query,keyword)
SELECT CONCAT('category_id=',category_id),translit(name)
FROM category ;

-- Загрузим производителей oc_manufacturer
TRUNCATE instr_russia.oc_manufacturer;

INSERT INTO instr_russia.oc_manufacturer 
	(name,sort_order)
SELECT DISTINCT manufacturer,0 FROM import_data; 


-- заполним таблицу oc_manufacturer_to_store
TRUNCATE instr_russia.oc_manufacturer_to_store;

INSERT INTO instr_russia.oc_manufacturer_to_store 
	SELECT manufacturer_id,0 FROM instr_russia.oc_manufacturer;



-- Загрузим производителей oc_manufacturer_description
INSERT INTO instr_russia.oc_manufacturer_description 
(
manufacturer_id,
language_id,
name,
description,
meta_title,
meta_h1,
meta_description,
meta_keyword
)
SELECT
manufacturer_id,
1,
name,
name ,
name,
name,
name,
name
FROM  instr_russia.oc_manufacturer;


-- Запрос на вставку в таблицу url_alias для производителе	

INSERT INTO instr_russia.oc_url_alias (query,keyword)
SELECT CONCAT('manufacturer_id=',manufacturer_id),translit(name)
FROM instr_russia.oc_manufacturer ;



-- Процедура для формирования описания катеогрии
DROP FUNCTION IF EXISTS descr_cat;

CREATE FUNCTION descr_cat (cat_id int)
RETURNS text No SQL
BEGIN
	DECLARE descr varchar(1024) DEFAULT '' ;
	DECLARE is_end INT DEFAULT 0 ;
	DECLARE names varchar(255) DEFAULT '';
	DECLARE curcat CURSOR FOR (SELECT name  FROM test_matrix.category where parentId= cat_id);
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET is_end = 1 ;
	OPEN curcat;
	cycle : LOOP
		FETCH curcat INTO names;
		IF is_end THEN LEAVE cycle;
		END IF ;
		SET descr = CONCAT(descr ,' : ', names);
	END LOOP cycle ;
CLOSE curcat;
RETURN descr;
END ;

SELECT instr_russia.descr_cat(3295);


-- Загрузим продакт

INSERT INTO instr_russia.oc_product 
(model,
sku,
upc,
ean,
jan,
isbn,
mpn,
location,
quantity,
stock_status_id,
image,
manufacturer_id,
price,
tax_class_id,
width,
weight_class_id,
length_class_id,
minimum,
status,
date_added,
date_modified)
SELECT 
id.model,
'' g,
'' a,
'' b,
'' c,
'' d,
'' e,
'' f,
id.quantity,
5,
id.photo,
(SELECT m.manufacturer_id FROM instr_russia.oc_manufacturer m WHERE m.name = id.manufacturer),
id.price,
0,
id.width,
1,
1,
id.minimum,
1,
now(),
now()
FROM import_data  id;


-- Загрузка в таблицу product_description
INSERT INTO instr_russia.oc_product_description 
SELECT 
product_id,
1,
id.name,
CONCAT(c.name,': ',id.name),
c.name,
id.name,
id.name,
CONCAT(c.name,': ',id.name),
CONCAT(c.name,': ',id.name)
FROM instr_russia.oc_product p
	JOIN import_data id ON p.model =id.model
	JOIN instr_russia.oc_category_description c ON c.category_id=id.category_id;


-- Загрузка в таблицу product_to_store
INSERT INTO instr_russia.oc_product_to_store (product_id)
	SELECT  product_id 
	FROM instr_russia.oc_product;

-- Загрузка в таблицу product_to_category
INSERT INTO instr_russia.oc_product_to_category
	SELECT  product_id, id.category_id,1 
	FROM instr_russia.oc_product p
		JOIN import_data id ON p.model =id.model;
	
-- Запрос на вставку в таблицу url_alias для product
INSERT INTO instr_russia.oc_url_alias (query,keyword)
SELECT CONCAT('product_id=',p.product_id),translit(id.name)
FROM instr_russia.oc_product p
	JOIN import_data id ON p.model =id.model;	


-- создадим таблицу для значений атрибутов
DROP TABLE IF EXISTS atributs;

CREATE TABLE atributs (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
model VARCHAR(64) NOT NULL ,
name VARCHAR(255) NOT NULL,
value TEXT NOT NULL
);

UPDATE atributs
set
hash =MD5(name);


-- cоздадим таблицу для уникальных атрибутов
CREATE TABLE atributs_uniq (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(255) NOT NULL
);


-- Заполним таблицу  atributs_uniq
TRUNCATE atributs_uniq ;
INSERT INTO atributs_uniq (name )
SELECT DISTINCT name FROM atributs;

UPDATE atributs_uniq 
set
hash =MD5(name);

-- Дозаполним таблицу atributs
UPDATE atributs a JOIN atributs_uniq au ON a.hash =au.hash 
SET 
a.id_atr =au.id ;

-- Заполним таблицу  oc_attribute
TRUNCATE instr_russia.oc_attribute ;

INSERT INTO instr_russia.oc_attribute 
SELECT id, 4,1
FROM atributs_uniq;


-- Заполним таблицу  oc_attribute_description 
TRUNCATE  instr_russia.oc_attribute_description;

INSERT INTO instr_russia.oc_attribute_description
SELECT id, 1,name
FROM atributs_uniq;



-- Заполним таблицу product_attribute
TRUNCATE  instr_russia.oc_product_attribute;

INSERT INTO instr_russia.oc_product_attribute 
SELECT product_id ,a.id_atr ,1,value
FROM test_matrix.atributs a 
JOIN instr_russia.oc_product p ON a.model = p.model;


-- создадим таблицу с именами фото
CREATE table	photo_name
(id serial primary key,
model int not null,
name int not null
);


-- вставим фото в таблицу product
UPDATE instr_russia.oc_product p
SET
p.image = CONCAT('catalog/photo/',(SELECT name FROM photo_name i where i.model = p.model limit 1),'.jpg');


-- вставим фото в product_image
INSERT  INTO instr_russia.oc_product_image (product_id,image)
SELECT p.product_id ,CONCAT('catalog/photo/',i.name ,'.jpg')
FROM photo_name i JOIN instr_russia.oc_product p ON p.model = i.model ;


-- Разное
SELECT COUNT(*) FROM import_data;

SELECT COUNT(*) FROM photo_name pn ;

TRUNCATE atributs;
TRUNCATE instr_russia.oc_product_attribute;

SELECT COUNT(*) FROM atributs;


SELECT  COUNT(DISTINCT  id_atr) FROM atributs;
SELECT COUNT(*)  FROM atributs_uniq au ;

SELECT model FROM oc_product where quantity =0;

SELECT COUNT(*) FROM oc_product where quantity =0;

-- список товавров которых нет на сайте
SELECT id.model, id.category_id ,c.category_id FROM 
	test_matrix.import_data id
	LEFT JOIN oc_product p ON id.model = p.model
	LEFT JOIN test_matrix.category c ON id.category_id =c.category_id 
WHERE p.model IS NULL;

-- количесвто товавров которых нет на сайте
SELECT COUNT(*)  FROM 
	test_matrix.import_data id
	LEFT JOIN oc_product p ON id.model = p.model
WHERE p.model IS NULL;

-- создадим таблицу lost_products для товаров которых нет на сайте
CREATE TABLE IF NOT EXISTS lost_products (
id SERIAL PRIMARY KEY,
model varchar(64) NOT NULL UNIQUE,
UNIQUE un_model_idx(model));

DROP TABLE IF EXISTS lost_products;

-- Заполним таблицу lost_products
TRUNCATE  lost_products;

INSERT INTO test_matrix.lost_products (model)
SELECT id.model  FROM 
	test_matrix.import_data id
	LEFT JOIN instr_russia.oc_product p ON id.model = p.model
WHERE p.model IS NULL;

-- создадим таблицу lost_category для товаров которых нет на сайте
CREATE TABLE IF NOT EXISTS lost_category (
id SERIAL PRIMARY KEY,
id_category int NOT NULL UNIQUE);


DROP TABLE IF EXISTS lost_category;

-- Заполним таблицу lost_category
TRUNCATE  lost_category;

INSERT INTO test_matrix.lost_category (id_category)
SELECT c.category_id  FROM 
	test_matrix.category c
	LEFT JOIN instr_russia.oc_category p ON c.category_id = p.category_id 
WHERE p.category_id IS NULL;

-- Проверим есть ли новые производители
SELECT id.manufacturer FROM import_data id 
	LEFT JOIN instr_russia.oc_manufacturer_description m ON id.manufacturer =m.name 
	WHERE m.name IS NULL;


-- загрузим данные в таблицу os_category
INSERT INTO instr_russia.oc_category 
(
category_id,
parent_id,
top,
`column`,
sort_order,
status,
date_added,
date_modified
)
SELECT
c.category_id ,
parentId,
1,
3,
0,
1,
NOW(),
NOW()
FROM test_matrix.category c JOIN test_matrix.lost_category l ON c.category_id =l.id_category;

-- Загрузим oc_category_description
INSERT INTO instr_russia.oc_category_description 
(
category_id,
language_id,
name,
description,
meta_title,
meta_h1,
meta_description,
meta_keyword
)
SELECT
c.category_id,
1,
name,
CONCAT(name,descr_cat(c.category_id)),
name,
name,
CONCAT(name,descr_cat(c.category_id)),
CONCAT(name,descr_cat(c.category_id))
FROM test_matrix.category c JOIN test_matrix.lost_category l ON c.category_id =l.id_category;


-- заполним таблицу oc_category_to_store
INSERT INTO instr_russia.oc_category_to_store 
	SELECT c.category_id,0 
	FROM test_matrix.category c JOIN test_matrix.lost_category l ON c.category_id =l.id_category;

-- Запрос на вставку в таблицу url_alias для категорий
INSERT INTO instr_russia.oc_url_alias (query,keyword)
SELECT CONCAT('category_id=',c.category_id),translit(name)
FROM test_matrix.category c JOIN test_matrix.lost_category l ON c.category_id =l.id_category ;


-- Загрузим продакт
INSERT INTO instr_russia.oc_product 
(model,
sku,
upc,
ean,
jan,
isbn,
mpn,
location,
quantity,
stock_status_id,
image,
manufacturer_id,
price,
tax_class_id,
width,
weight_class_id,
length_class_id,
minimum,
status,
date_added,
date_modified)
SELECT 
id.model,
'' g,
'' a,
'' b,
'' c,
'' d,
'' e,
'' f,
id.quantity,
5,
id.photo,
(SELECT m.manufacturer_id FROM instr_russia.oc_manufacturer m WHERE m.name = id.manufacturer),
id.price,
0,
id.width,
1,
1,
id.minimum,
1,
now(),
now()
FROM test_matrix.import_data  id JOIN test_matrix.lost_products p ON id.model = p.model ;


-- Загрузка в таблицу product_description
INSERT INTO instr_russia.oc_product_description 
SELECT 
product_id,
1,
id.name,
CONCAT(c.name,': ',id.name),
c.name,
id.name,
id.name,
CONCAT(c.name,': ',id.name),
CONCAT(c.name,': ',id.name)
FROM instr_russia.oc_product p
	JOIN test_matrix.import_data id ON p.model =id.model
	JOIN instr_russia.oc_category_description c ON c.category_id=id.category_id
	JOIN test_matrix.lost_products lp ON id.model = lp.model ;


-- Загрузка в таблицу product_to_store
INSERT INTO instr_russia.oc_product_to_store (product_id)
	SELECT  product_id 
	FROM instr_russia.oc_product p
		JOIN test_matrix.lost_products lp ON p.model = lp.model;

-- Загрузка в таблицу product_to_category
INSERT INTO instr_russia.oc_product_to_category
	SELECT  product_id, id.category_id,1 
	FROM instr_russia.oc_product p
		JOIN test_matrix.import_data id ON p.model =id.model
		JOIN test_matrix.lost_products lp ON id.model = lp.model ;
	
-- Запрос на вставку в таблицу url_alias для product
INSERT INTO instr_russia.oc_url_alias (query,keyword)
SELECT CONCAT('product_id=',p.product_id),translit(id.name)
FROM instr_russia.oc_product p
	JOIN test_matrix.import_data id ON p.model =id.model
	JOIN  test_matrix.lost_products lp ON lp.model =id.model;	

	
-- заполим хэш у атрибутов
UPDATE test_matrix.atributs 
set
hash =MD5(name);

-- проверим есть ли новые атрибуты
SELECT  * FROM atributs a 
	LEFT JOIN atributs_uniq au ON a.hash =au.hash 
	WHERE au.id is NULL;
	
SELECT  DISTINCT a.name FROM atributs a 
	LEFT JOIN atributs_uniq au ON a.hash =au.hash 
	WHERE au.id is NULL;

-- Создадим табоицу для отсутвующих атрибутов
CREATE TABLE IF NOT EXISTS lost_atr(
id SERIAL PRIMARY KEY,
name  varchar(255)  NOT NULL,
hash char(32)  NOT NULL UNIQUE
);

-- Заполним таблицу lost_atr
INSERT INTO test_matrix.lost_atr (name,hash )
SELECT  DISTINCT a.name,MD5(a.name) FROM atributs a 
	LEFT JOIN atributs_uniq au ON a.hash =au.hash 
	WHERE au.id is NULL;

-- Добавим новые атрибуты в atributs_uniq
INSERT INTO test_matrix.atributs_uniq (name,hash )
SELECT name,hash FROM test_matrix.lost_atr ;

-- Дозаполним таблицу atributs
UPDATE test_matrix.atributs a JOIN test_matrix.atributs_uniq au ON a.hash =au.hash 
SET 
a.id_atr =au.id ;

-- Заполним таблицу  oc_attribute
INSERT INTO instr_russia.oc_attribute 
SELECT au.id, 4,1
FROM test_matrix.atributs_uniq au
	JOIN test_matrix.lost_atr la ON la.hash =au.hash ;

-- Заполним таблицу  oc_attribute_description 
INSERT INTO instr_russia.oc_attribute_description
SELECT au.id, 1,au.name
FROM test_matrix.atributs_uniq au
	JOIN test_matrix.lost_atr la ON la.hash =au.hash;

-- Заполним таблицу product_attribute
INSERT INTO instr_russia.oc_product_attribute 
SELECT product_id ,a.id_atr ,1,value
FROM test_matrix.atributs a 
JOIN instr_russia.oc_product p ON a.model = p.model
JOIN test_matrix.lost_products lp ON a.model =lp.model ;

SELECT COUNT(*) 
FROM test_matrix.atributs a 
JOIN instr_russia.oc_product p ON a.model = p.model
JOIN test_matrix.lost_products lp ON a.model =lp.model ;

SELECT DISTINCT p.product_id FROM instr_russia.oc_product_attribute pa 
		JOIN instr_russia.oc_product p ON p.product_id = pa.product_id 
		JOIN test_matrix.lost_products lp ON lp.model = p.model ;

SELECT  lp.model ,a.name  FROM test_matrix.atributs a 
	join test_matrix.lost_products lp ON lp.model =a.model
	WHERE lp.model IN (SELECT DISTINCT p.model FROM instr_russia.oc_product_attribute pa 
		JOIN instr_russia.oc_product p ON p.product_id = pa.product_id 
		JOIN test_matrix.lost_products lp ON lp.model = p.model);
	
DELETE 	FROM instr_russia.oc_product_attribute 
	WHERE product_id IN (SELECT DISTINCT p.product_id FROM instr_russia.oc_product_attribute pa 
		JOIN instr_russia.oc_product p ON p.product_id = pa.product_id 
		JOIN test_matrix.lost_products lp ON lp.model = p.model );
	
SELECT pn.model ,url as image FROM test_matrix.photo pn join test_matrix.lost_products lp ON lp.model =pn.model WHERE url <>'None';	
	
	
-- Создадим таблицу для хранения ссылок на фото
CREATE TABLE photo(
id SERIAL PRIMARY KEY,
model varchar(64),
url varchar(250));
	
DROP table photo ;

-- последний номер фото
SELECT * FROM test_matrix.photo_name order by id DESC  limit 1;



-- фото для отсутвующих товаров
SELECT * FROM photo p join lost_products lp ON p.model = lp.model ;

-- вставим фото в таблицу product
UPDATE instr_russia.oc_product p JOIN test_matrix.lost_products lp ON p.model =lp.model 
SET
p.image = CONCAT('catalog/photo/',(SELECT name FROM test_matrix.photo_name i where i.model = p.model limit 1),'.jpg');


-- вставим новые фото в product_image
INSERT  INTO instr_russia.oc_product_image (product_id,image)
SELECT p.product_id ,CONCAT('catalog/photo/',i.name ,'.jpg')
FROM test_matrix.photo_name i JOIN test_matrix.lost_products lp ON lp.model = i.model
	JOIN instr_russia.oc_product p ON p.model = lp.model;




SELECT COUNT(*) FROM instr_russia.oc_product_image;


-- Запрос на вставку в таблицу url_alias для производителе	
INSERT INTO instr_russia.oc_url_alias (query,keyword)
SELECT CONCAT('manufacturer_id=',manufacturer_id),translit(name)
FROM instr_russia.oc_manufacturer ;


-- Функция формирования ЧПУ
CREATE FUNCTION translit(original VARCHAR(512)) 
RETURNS varchar(512) NO SQL
BEGIN
	DECLARE translit VARCHAR(512) DEFAULT '';
	DECLARE len INT(3) DEFAULT 0;
	DECLARE pos INT(3) DEFAULT 1;
	DECLARE letter CHAR(4);
	SET original = TRIM(LOWER(original));
	SET len = CHAR_LENGTH(original);
	WHILE (pos <= len) DO
		SET letter = SUBSTRING(original, pos, 1);
		CASE TRUE
			WHEN letter IN('á','à','â','ä','å','ā','ą','ă','а','а') THEN SET letter = 'a';
			WHEN letter IN('č','ć','ç','ć') THEN SET letter = 'c';
			WHEN letter IN('ď','đ','д','д') THEN SET letter = 'd';
			WHEN letter IN('é','ě','ë','è','ê','ē','ę','е','е') THEN SET letter = 'e';
			WHEN letter IN('ģ','ğ') THEN SET letter = 'g';
			WHEN letter IN('í','î','ï','ī','î','и','і') THEN SET letter = 'i';
			WHEN letter IN('ķ') THEN SET letter = 'k';
			WHEN letter IN('ľ','ĺ','ļ','ł') THEN SET letter = 'l';
			WHEN letter IN('ň','ņ','ń','ñ') THEN SET letter = 'n';
			WHEN letter IN('ó','ö','ø','õ','ô','ő','ơ','о','о') THEN SET letter = 'o';
			WHEN letter IN('ŕ','ř','р','р') THEN SET letter = 'r';
			WHEN letter IN('š','ś','ș','ş','с','с') THEN SET letter = 's';
			WHEN letter IN('ť','ț') THEN SET letter = 't';
			WHEN letter IN('ú','ů','ü','ù','û','ū','ű','ư') THEN SET letter = 'u';
			WHEN letter IN('ý','у','у') THEN SET letter = 'y';
			WHEN letter IN('ž','ź','ż') THEN SET letter = 'z';
			WHEN letter = 'б' THEN SET letter = 'b';
			WHEN letter = 'в' THEN SET letter = 'v';
			WHEN letter = 'г' THEN SET letter = 'g';
			WHEN letter = 'д' THEN SET letter = 'd';
			WHEN letter = 'ж' THEN SET letter = 'zh';
			WHEN letter = 'з' THEN SET letter = 'z';
			WHEN letter = 'и' THEN SET letter = 'i';
			WHEN letter = 'й' THEN SET letter = 'i';
			WHEN letter = 'к' THEN SET letter = 'k';
			WHEN letter = 'л' THEN SET letter = 'l';
			WHEN letter = 'м' THEN SET letter = 'm';
			WHEN letter = 'н' THEN SET letter = 'n';
			WHEN letter = 'п' THEN SET letter = 'p';
			WHEN letter = 'т' THEN SET letter = 't';
			WHEN letter = 'ф' THEN SET letter = 'f';
			WHEN letter = 'х' THEN SET letter = 'ch';
			WHEN letter = 'ц' THEN SET letter = 'c';
			WHEN letter = 'ч' THEN SET letter = 'ch';
			WHEN letter = 'ш' THEN SET letter = 'sh';
			WHEN letter = 'щ' THEN SET letter = 'shch';
			WHEN letter = 'ъ' THEN SET letter = '';
			WHEN letter = 'ы' THEN SET letter = 'y';
			WHEN letter = 'ь' THEN SET letter = '';
			WHEN letter = 'э' THEN SET letter = 'e';
			WHEN letter = 'ю' THEN SET letter = 'ju';
			WHEN letter = 'я' THEN SET letter = 'ja';
			WHEN letter IN ('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o',
			'p','q','r','s','t','u','v','x','y','z','1','2','3','4','5','6','7','8','9','0','-','_')
			THEN SET letter = letter;
		ELSE
			SET letter = '-';
		END CASE;
		SET translit = CONCAT(translit, letter);
		SET pos = pos + 1;
	END WHILE;
	WHILE (translit REGEXP '\-{2,}') DO
		SET translit = REPLACE(translit, '--', '-');
	END WHILE;
	RETURN TRIM(BOTH '-' FROM translit);
END;	


-- Процедура обновления остатков
CREATE PROCEDURE update_price_count()
BEGIN
	START TRANSACTION;
		UPDATE oc_product p JOIN 
			test_matrix.import_data as tp ON p.model = tp.model 
			SET	
				p.quantity=tp.quantity,
				p.price=tp.price;
		UPDATE oc_product  p LEFT JOIN 
			test_matrix.import_data as tp ON p.model = tp.model 
			SET	
				p.quantity=0
		WHERE tp.id IS  NULL;
	COMMIT;
END;

DROP PROCEDURE update_price_count;

CALL update_price_count();
