--
-- PostgreSQL database dump
--

\restrict cn85ueZeGUu0nUgUO8luWNb9EQovKTm6jCyVg3lLRViV3rYPCv2Um2j1GXTJ3oW

-- Dumped from database version 13.6
-- Dumped by pg_dump version 13.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fk-not-null; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public."fk-not-null" AS integer NOT NULL;


ALTER DOMAIN public."fk-not-null" OWNER TO postgres;

--
-- Name: fk-null; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public."fk-null" AS integer;


ALTER DOMAIN public."fk-null" OWNER TO postgres;

--
-- Name: mileage; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.mileage AS integer NOT NULL
	CONSTRAINT mileage_check CHECK (((VALUE > 0) AND (VALUE < 6000000)));


ALTER DOMAIN public.mileage OWNER TO postgres;

--
-- Name: name-or-passport; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public."name-or-passport" AS character varying(30) NOT NULL;


ALTER DOMAIN public."name-or-passport" OWNER TO postgres;

--
-- Name: phone-or-address; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public."phone-or-address" AS character varying(30);


ALTER DOMAIN public."phone-or-address" OWNER TO postgres;

--
-- Name: technical-data; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public."technical-data" AS character varying(30) NOT NULL;


ALTER DOMAIN public."technical-data" OWNER TO postgres;

--
-- Name: Available_cars_brands(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Available_cars_brands"(brand character varying) RETURNS TABLE("Model" character varying, "Mileage" public.mileage, "Price" numeric, "Engine_displacement" integer, "Color" public."technical-data", "Name_body" public."technical-data", "Name_motor" public."technical-data", "Type_gearbox" public."technical-data", "Name_purpose" public."technical-data", "Type_suspension" public."technical-data", "Type_drive" public."technical-data")
    LANGUAGE plpgsql
    AS $_$
DECLARE var character varying = RTRIM($1);
BEGIN
RETURN QUERY 
SELECT c."Model", c."Mileage", c."Price", t."Engine_displacement", t."Color", b."Name_body", 
m."Name_motor", g."Type_gearbox", p."Name_purpose", s."Type_suspension", d."Type_drive" 
FROM "Car" c
JOIN "Technical_data" t USING ("ID_technical_data") 
JOIN "Body_type" b USING ("ID_body_type") 
JOIN "Motor_type" m USING ("ID_motor_type") 
JOIN "Car_purpose" p USING ("ID_car_purpose") 
JOIN "Drive" d USING ("ID_drive") 
JOIN "Gearbox" g USING ("ID_gearbox") 
JOIN "Suspension" s USING ("ID_suspension")
WHERE c."Brand"=var AND
c."Availability"=true;

IF NOT FOUND THEN
        RAISE EXCEPTION 'Не удалось найти автомобиль с маркой %', $1;
END IF;

END
$_$;


ALTER FUNCTION public."Available_cars_brands"(brand character varying) OWNER TO postgres;

--
-- Name: Cars_engine(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Cars_engine"(engine character varying) RETURNS TABLE("Brand" character varying, "Model" character varying, "Mileage" public.mileage, "Price" numeric, "Color" public."technical-data")
    LANGUAGE plpgsql
    AS $_$
DECLARE engin character varying = RTRIM($1);
BEGIN
RETURN QUERY 
SELECT c."Brand", c."Model", c."Mileage", c."Price", t."Color"
FROM "Car" c
JOIN "Technical_data" t USING ("ID_technical_data") 
JOIN "Motor_type" m USING ("ID_motor_type") 
WHERE m."Name_motor"=engin AND
c."Availability"=true;

IF NOT FOUND THEN
        RAISE EXCEPTION 'Не удалось найти автомобиль с двигателем %', engin;
END IF;

END
$_$;


ALTER FUNCTION public."Cars_engine"(engine character varying) OWNER TO postgres;

--
-- Name: Contract_information_by_year(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Contract_information_by_year"(contract_date date) RETURNS TABLE("Customers_sername" character varying, "Customers_name" character varying, "Customers_city" character varying, "Managers_sername" character varying, "Managers_name" character varying, "Managers_patronymic" character varying, "Managers_phone" character varying, "Brand" character varying, "Model" character varying, "Mileage" integer, "Price" numeric, "Date_contract" date)
    LANGUAGE sql
    AS $$
SELECT * FROM "CONTRACT_INFO" 
WHERE "Date_contract">contract_date;
$$;


ALTER FUNCTION public."Contract_information_by_year"(contract_date date) OWNER TO postgres;

--
-- Name: Delete_contract(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Delete_contract"(contract_no integer) RETURNS character varying
    LANGUAGE sql
    AS $$
DELETE FROM "Contract" 
WHERE "ID_contract" = contract_no 
RETURNING 'Удаление прошло успешно'; 
$$;


ALTER FUNCTION public."Delete_contract"(contract_no integer) OWNER TO postgres;

--
-- Name: Finding_the_buyer(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Finding_the_buyer"(search_column character varying, substr character varying) RETURNS TABLE("Customers_sername" public."name-or-passport", "Customers_name" public."name-or-passport", "Customers_city" public."phone-or-address")
    LANGUAGE plpgsql
    AS $_$
DECLARE var character varying = RTRIM($2);
BEGIN
CASE $1
	WHEN 'Customers_city' THEN
	RETURN QUERY SELECT DISTINCT * FROM "CUSTOMER_INFO" 
	WHERE "CUSTOMER_INFO". "Customers_city"=var;
	
	WHEN 'Customers_sername' THEN
	RETURN QUERY SELECT DISTINCT * FROM "CUSTOMER_INFO" 
	WHERE "CUSTOMER_INFO". "Customers_sername"=var;
	
	WHEN 'Customers_name' THEN
	RETURN QUERY SELECT DISTINCT * FROM "CUSTOMER_INFO" 
	WHERE "CUSTOMER_INFO". "Customers_name"=var;
END CASE;
IF NOT FOUND THEN
        RAISE EXCEPTION 'Не удалось найти строку % в столбце %', $2, $1;
END IF;

EXCEPTION WHEN case_not_found THEN
RAISE EXCEPTION 'Не удалось найти столбец %', $1;

RETURN;
END

$_$;


ALTER FUNCTION public."Finding_the_buyer"(search_column character varying, substr character varying) OWNER TO postgres;

--
-- Name: Finding_the_car_by_price(numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Finding_the_car_by_price"(price_input1 numeric, price_input2 numeric) RETURNS TABLE("Availability" boolean, "Brand" character varying, "Model" character varying, "Mileage" public.mileage, "Price" numeric, "Engine_displacement" integer, "Color" character varying, "Name_body" character varying, "Name_motor" character varying, "Type_gearbox" character varying, "Name_purpose" character varying, "Type_suspension" character varying, "Type_drive" character varying)
    LANGUAGE sql
    AS $$
SELECT "Availability", "Brand", "Model", "Mileage", "Price", "Engine_displacement", "Color", "Name_body", 
"Name_motor", "Type_gearbox", "Name_purpose", "Type_suspension", "Type_drive" 
FROM "Car" 
JOIN "Technical_data" USING ("ID_technical_data") 
JOIN "Body_type" USING ("ID_body_type") 
JOIN "Motor_type" USING ("ID_motor_type") 
JOIN "Car_purpose" USING ("ID_car_purpose") 
JOIN "Drive" USING ("ID_drive") 
JOIN "Gearbox" USING ("ID_gearbox") 
JOIN "Suspension" USING ("ID_suspension") 
WHERE "Price" BETWEEN price_input1 AND price_input2;
$$;


ALTER FUNCTION public."Finding_the_car_by_price"(price_input1 numeric, price_input2 numeric) OWNER TO postgres;

--
-- Name: Insert_Car(character varying, boolean, character varying, character varying, integer, integer, numeric, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Insert_Car"("VIN" character varying, "Availability" boolean, "Brand" character varying, "Model" character varying, "Mileage" integer, "Year_of_issue" integer, "Price" numeric, "ID_technical_data" integer) RETURNS SETOF character varying
    LANGUAGE sql
    AS $$
INSERT INTO "Car" 
("VIN", "Availability", "Brand", "Model", "Mileage", "Year_of_issue", "Price", "ID_technical_data")
VALUES 
("VIN", "Availability", "Brand", "Model", "Mileage", "Year_of_issue", "Price", "ID_technical_data")
RETURNING 'Новая запись успешно добавлена';
$$;


ALTER FUNCTION public."Insert_Car"("VIN" character varying, "Availability" boolean, "Brand" character varying, "Model" character varying, "Mileage" integer, "Year_of_issue" integer, "Price" numeric, "ID_technical_data" integer) OWNER TO postgres;

--
-- Name: Insert_individual(public."name-or-passport", public."name-or-passport", character varying, public."phone-or-address", public."phone-or-address", public."phone-or-address", public."phone-or-address", public."name-or-passport", public."name-or-passport", date, public."phone-or-address"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Insert_individual"("Second_name" public."name-or-passport", "Nameind" public."name-or-passport", "Patronymic" character varying, "City" public."phone-or-address", "Street" public."phone-or-address", "House" public."phone-or-address", "Flat" public."phone-or-address", "Passport_series" public."name-or-passport", "Passport_number" public."name-or-passport", "When_issued" date, "Phone" public."phone-or-address") RETURNS integer
    LANGUAGE sql
    AS $$
INSERT INTO "Individual" 
("Second_name", "Name", "Patronymic", "City", "Street", "House", "Flat", 
"Passport_series", "Passport_number", "When_issued", "Phone")
VALUES 
("Second_name", "Nameind", "Patronymic", "City", "Street", "House", "Flat", 
"Passport_series", "Passport_number", "When_issued", "Phone")
RETURNING "ID_individual";
$$;


ALTER FUNCTION public."Insert_individual"("Second_name" public."name-or-passport", "Nameind" public."name-or-passport", "Patronymic" character varying, "City" public."phone-or-address", "Street" public."phone-or-address", "House" public."phone-or-address", "Flat" public."phone-or-address", "Passport_series" public."name-or-passport", "Passport_number" public."name-or-passport", "When_issued" date, "Phone" public."phone-or-address") OWNER TO postgres;

--
-- Name: Insert_manager(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Insert_manager"(id_manager integer, id_individual integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "Manager" ("ID_manager", "ID_individual")
  VALUES (id_manager, id_individual); 
  RETURN 'Новая запись успешно добавлена';
  EXCEPTION WHEN unique_violation THEN LOOP
  UPDATE "Manager" SET "ID_individual"=id_individual 
  WHERE "ID_manager"=id_manager;
  IF FOUND THEN RETURN 'Запись успешно изменена';
  END IF;
  END LOOP;
END
$$;


ALTER FUNCTION public."Insert_manager"(id_manager integer, id_individual integer) OWNER TO postgres;

--
-- Name: Number_of_owners(numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Number_of_owners"(price_input1 numeric, price_input2 numeric) RETURNS TABLE("Price" numeric, "Count" integer)
    LANGUAGE sql
    AS $$
SELECT "Price", COUNT(EXISTS (SELECT "ID_owner" FROM "Owner_car", "Car" 
WHERE "Owner_car". "ID_car"="Car". "ID_car" AND
"Price" BETWEEN price_input1 AND price_input2))
FROM "Car", "Owner_car" 
WHERE "Owner_car". "ID_car"="Car". "ID_car" AND
"Price" BETWEEN price_input1 AND price_input2
Group by "Price";
$$;


ALTER FUNCTION public."Number_of_owners"(price_input1 numeric, price_input2 numeric) OWNER TO postgres;

--
-- Name: Phone_editing(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Phone_editing"(INOUT phone character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	edit_phone character varying = '+7 ( ' || substring(phone from 1 for 3) || ' ) ' 
	   									   || substring(phone from 4 for 3) || ' - ' 
										   || substring(phone from 7 for 2) || ' - ' 
										   || substring(phone from 9);
BEGIN
	IF phone ~ '^[0-9]*$' AND length(phone) = 10 THEN
		phone = edit_phone;
	ELSE 
		-- phone = NULL;
		RAISE EXCEPTION 'Введите номер состоящий из 10 цифр!';
	END IF;
END
$_$;


ALTER FUNCTION public."Phone_editing"(INOUT phone character varying) OWNER TO postgres;

--
-- Name: Sum_sales_of_brand(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Sum_sales_of_brand"(brand character varying) RETURNS TABLE("Model" character varying, "Count" bigint, "Sum" numeric)
    LANGUAGE plpgsql
    AS $_$
BEGIN
RETURN QUERY SELECT c."Model", COUNT(c."Model"), SUM(c."Price")
FROM "Car" c
JOIN "Contract" USING ("ID_car")
WHERE "Brand"=brand AND
"Availability"=true
GROUP BY c."Model";

IF NOT FOUND THEN
        RAISE EXCEPTION 'Не удалось найти автомобиль с маркой %', $1;
END IF;

END
$_$;


ALTER FUNCTION public."Sum_sales_of_brand"(brand character varying) OWNER TO postgres;

--
-- Name: Update_Car(character varying, boolean, character varying, character varying, integer, integer, numeric, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Update_Car"("VIN" character varying, "Availability" boolean, "Brand" character varying, "Model" character varying, "Mileage" integer, "Year_of_issue" integer, "Price" numeric, "ID_technical_data" integer) RETURNS character varying
    LANGUAGE sql
    AS $$
INSERT INTO "Car" 
("VIN", "Availability", "Brand", "Model", "Mileage", "Year_of_issue", "Price", "ID_technical_data")
VALUES 
("VIN", "Availability", "Brand", "Model", "Mileage", "Year_of_issue", "Price", "ID_technical_data")
RETURNING 'Запись успешно изменена';
$$;


ALTER FUNCTION public."Update_Car"("VIN" character varying, "Availability" boolean, "Brand" character varying, "Model" character varying, "Mileage" integer, "Year_of_issue" integer, "Price" numeric, "ID_technical_data" integer) OWNER TO postgres;

--
-- Name: Update_Car(character varying, boolean, character varying, character varying, integer, integer, numeric, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Update_Car"("pVIN" character varying, "pAvailability" boolean, "pBrand" character varying, "pModel" character varying, "pMileage" integer, "pYear_of_issue" integer, "pPrice" numeric, "pID_technical_data" integer, "pID_car" integer) RETURNS character varying
    LANGUAGE sql
    AS $$
	UPDATE "Car" SET 
	"VIN"="pVIN",
	"Availability"="pAvailability",
	"Brand"="pBrand",
	"Model"="pModel",
	"Mileage"="pMileage", 
	"Year_of_issue"="pYear_of_issue",
	"Price"="pPrice", 
	"ID_technical_data"="pID_technical_data"
	WHERE "ID_car"="pID_car" RETURNING 'Запись успешно изменена';

$$;


ALTER FUNCTION public."Update_Car"("pVIN" character varying, "pAvailability" boolean, "pBrand" character varying, "pModel" character varying, "pMileage" integer, "pYear_of_issue" integer, "pPrice" numeric, "pID_technical_data" integer, "pID_car" integer) OWNER TO postgres;

--
-- Name: Update_price(integer, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."Update_price"(car_no integer, factor double precision) RETURNS numeric
    LANGUAGE sql
    AS $$UPDATE "Car" SET "Price" = "Price" * factor 
WHERE car_no="ID_car" 
RETURNING "Price";$$;


ALTER FUNCTION public."Update_price"(car_no integer, factor double precision) OWNER TO postgres;

--
-- Name: log_car(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_car() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
invitation character varying;
available character varying;
final_mes character varying;
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW."Availability"=true THEN available='available';
        ELSE available='not available';
        END IF;
        invitation = 'Add new car and this car is ';
        final_mes = invitation || available;
        
        INSERT INTO car_audits 
        (description, changed, id_car)
        VALUES
        (final_mes, now(), NEW."ID_car");
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW."Availability"=true THEN available='available';
        ELSE available='not available';
        END IF;
        invitation = 'Update car and this car is ';
        final_mes = invitation || available;
        INSERT INTO car_audits 
        (description, changed, id_car)
        VALUES
        (final_mes, now(), NEW."ID_car");
        RETURN NEW;
    END IF;
END$$;


ALTER FUNCTION public.log_car() OWNER TO postgres;

--
-- Name: log_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
BEGIN
EXECUTE format('UPDATE full_car_audits SET end_date = current_timestamp 
               WHERE "ID_car"=$1 AND end_date IS NULL')
USING OLD."ID_car";
RETURN OLD;
END
$_$;


ALTER FUNCTION public.log_delete() OWNER TO postgres;

--
-- Name: log_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
BEGIN
EXECUTE format('INSERT INTO full_car_audits SELECT ($1).*, 
               current_timestamp, NULL')
USING NEW;
RETURN NEW;
END
$_$;


ALTER FUNCTION public.log_insert() OWNER TO postgres;

--
-- Name: log_sername_changes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_sername_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW."Second_name" <> OLD."Second_name" THEN
        INSERT INTO Individual_audits 
        ("sername", "changed_on", "id_individual")
        VALUES
        (OLD."Second_name", now(), OLD."ID_individual");
    END IF;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.log_sername_changes() OWNER TO postgres;

--
-- Name: logs_motor(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.logs_motor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
invitation character varying;
motors_name character varying;
final_mes character varying;
BEGIN
    IF TG_OP = 'INSERT' THEN
        motors_name = NEW."Name_motor";
        invitation = 'Add new motor';
        final_mes = invitation || motors_name;
        INSERT INTO motor_type_audits 
        (name_motor, added, id_motor)
        VALUES
        (final_mes, now(), NEW."ID_motor_type");
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        motors_name = NEW."Name_motor";
        invitation = 'Update motor';
        final_mes = invitation || motors_name;
        INSERT INTO motor_type_audits 
        (name_motor, added, id_motor)
        VALUES
        (final_mes, now(), NEW."ID_motor_type");
        RETURN NEW;
    END IF;
END
$$;


ALTER FUNCTION public.logs_motor() OWNER TO postgres;

--
-- Name: t_delete_car(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.t_delete_car() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

IF (EXISTS (SELECT "Car"."ID_car" FROM "Car"
 JOIN "Contract" USING ("ID_car")
 WHERE OLD."ID_car" = "Car"."ID_car") = true)
 AND (EXISTS (SELECT "Car"."ID_car" FROM "Car"
 JOIN "Owner_car" USING ("ID_car")
 WHERE OLD."ID_car" = "Car"."ID_car") = true)
THEN
    RAISE EXCEPTION 'Такой ID используется'; END IF;
RETURN OLD;
END
$$;


ALTER FUNCTION public.t_delete_car() OWNER TO postgres;

--
-- Name: t_insert_individual(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.t_insert_individual() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE low_date date = '1900-01-01';
high_date date = '2030-01-01';
BEGIN

-- Проверка "Second_name"=NULL, "Name"=NULL, '2030-01-01' > "When_issued" > '1900-01-01'
IF NEW."Second_name" IS NULL THEN
    RAISE EXCEPTION 'Поле "фамилия" не может быть пустым!'; END IF;
IF NEW."Name" IS NULL THEN
    RAISE EXCEPTION 'Поле "имя" не может быть пустым!'; END IF;
IF ((NEW."When_issued" < low_date) OR (NEW."When_issued" > high_date)) THEN
    RAISE EXCEPTION 'Дата рождения % должна быть реальной!', NEW."When_issued"; END IF;

RETURN NEW;
END
$$;


ALTER FUNCTION public.t_insert_individual() OWNER TO postgres;

--
-- Name: t_update_MANAGER_INFO(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."t_update_MANAGER_INFO"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

UPDATE "Individual"
SET "Phone" = New."Managers_phone"
WHERE "Phone" = OLD."Managers_phone";
IF NOT FOUND THEN
RAISE EXCEPTION 'Не удалось выполнить операцию'; END IF;
RETURN NEW;

END
$$;


ALTER FUNCTION public."t_update_MANAGER_INFO"() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Car; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Car" (
    "ID_car" integer NOT NULL,
    "VIN" character varying(20) NOT NULL,
    "Availability" boolean NOT NULL,
    "Brand" character varying(50),
    "Model" character varying(50),
    "Mileage" public.mileage,
    "Year_of_issue" integer NOT NULL,
    "Price" numeric NOT NULL,
    "ID_technical_data" public."fk-not-null"
);


ALTER TABLE public."Car" OWNER TO postgres;

--
-- Name: AVG_CAR_PRICE; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."AVG_CAR_PRICE" AS
 SELECT "Car"."Year_of_issue",
    avg("Car"."Price") AS "AVG_Price"
   FROM public."Car"
  GROUP BY "Car"."Year_of_issue"
 HAVING (avg("Car"."Price") > (8000)::numeric)
  ORDER BY "Car"."Year_of_issue" DESC;


ALTER VIEW public."AVG_CAR_PRICE" OWNER TO postgres;

--
-- Name: BRANDS; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."BRANDS" AS
 SELECT DISTINCT "Car"."Brand"
   FROM public."Car";


ALTER VIEW public."BRANDS" OWNER TO postgres;

--
-- Name: Body_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Body_type" (
    "ID_body_type" integer NOT NULL,
    "Name_body" public."technical-data"
);


ALTER TABLE public."Body_type" OWNER TO postgres;

--
-- Name: Body_type_ID_body_type_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Body_type_ID_body_type_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Body_type_ID_body_type_seq" OWNER TO postgres;

--
-- Name: Body_type_ID_body_type_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Body_type_ID_body_type_seq" OWNED BY public."Body_type"."ID_body_type";


--
-- Name: Buyer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Buyer" (
    "ID_buyer" integer NOT NULL,
    "ID_individual" public."fk-not-null"
);


ALTER TABLE public."Buyer" OWNER TO postgres;

--
-- Name: Buyer_ID_buyer_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Buyer_ID_buyer_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Buyer_ID_buyer_seq" OWNER TO postgres;

--
-- Name: Buyer_ID_buyer_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Buyer_ID_buyer_seq" OWNED BY public."Buyer"."ID_buyer";


--
-- Name: CAR_AVAYLABILITY; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."CAR_AVAYLABILITY" AS
 SELECT "Car"."Brand",
    "Car"."Model",
    "Car"."Mileage",
    "Car"."Price"
   FROM public."Car"
  WHERE ("Car"."Availability" = false);


ALTER VIEW public."CAR_AVAYLABILITY" OWNER TO postgres;

--
-- Name: CAR_MODERN; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."CAR_MODERN" AS
 SELECT "Car"."ID_car",
    "Car"."VIN",
    "Car"."Availability",
    "Car"."Brand",
    "Car"."Model",
    "Car"."Mileage",
    "Car"."Year_of_issue",
    "Car"."Price"
   FROM public."Car"
  WHERE ("Car"."Year_of_issue" = ANY (ARRAY[2019, 2020, 2021, 2022]));


ALTER VIEW public."CAR_MODERN" OWNER TO postgres;

--
-- Name: CAR_PRICE; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."CAR_PRICE" AS
 SELECT "Car"."Brand",
    "Car"."Model",
    "Car"."Price"
   FROM public."Car"
  WHERE (("Car"."Price" >= (1000)::numeric) AND ("Car"."Price" <= (30000)::numeric))
  ORDER BY "Car"."Price" DESC;


ALTER VIEW public."CAR_PRICE" OWNER TO postgres;

--
-- Name: Contract; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Contract" (
    "ID_contract" integer NOT NULL,
    "ID_buyer" public."fk-not-null",
    "ID_manager" public."fk-not-null",
    "ID_car" public."fk-not-null",
    "Date_contract" date NOT NULL,
    "Payment_type" character varying(50) NOT NULL,
    "Requisites" character varying(50)
);


ALTER TABLE public."Contract" OWNER TO postgres;

--
-- Name: Individual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Individual" (
    "ID_individual" integer NOT NULL,
    "Second_name" public."name-or-passport" NOT NULL,
    "Name" public."name-or-passport" NOT NULL,
    "Patronymic" character varying(30),
    "City" public."phone-or-address",
    "Street" public."phone-or-address",
    "House" public."phone-or-address",
    "Flat" public."phone-or-address",
    "Passport_series" public."name-or-passport",
    "Passport_number" public."name-or-passport",
    "When_issued" date,
    "Phone" public."phone-or-address"
);


ALTER TABLE public."Individual" OWNER TO postgres;

--
-- Name: CUSTOMER_FULL_INFO; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."CUSTOMER_FULL_INFO" AS
 SELECT "Individual"."ID_individual",
    "Buyer"."ID_buyer",
    "Contract"."ID_contract",
    "Contract"."ID_manager",
    "Contract"."ID_car",
    "Contract"."Date_contract",
    "Contract"."Payment_type",
    "Contract"."Requisites",
    "Individual"."Second_name",
    "Individual"."Name",
    "Individual"."Patronymic",
    "Individual"."City",
    "Individual"."Street",
    "Individual"."House",
    "Individual"."Flat",
    "Individual"."Passport_series",
    "Individual"."Passport_number",
    "Individual"."When_issued",
    "Individual"."Phone"
   FROM ((public."Contract"
     JOIN public."Buyer" USING ("ID_buyer"))
     JOIN public."Individual" USING ("ID_individual"));


ALTER VIEW public."CUSTOMER_FULL_INFO" OWNER TO postgres;

--
-- Name: Manager; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Manager" (
    "ID_manager" integer NOT NULL,
    "ID_individual" public."fk-not-null"
);


ALTER TABLE public."Manager" OWNER TO postgres;

--
-- Name: MANAGER_FULL_INFO; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."MANAGER_FULL_INFO" AS
 SELECT "Individual"."ID_individual",
    "Manager"."ID_manager",
    "Contract"."ID_contract",
    "Contract"."ID_buyer",
    "Contract"."ID_car",
    "Contract"."Date_contract",
    "Contract"."Payment_type",
    "Contract"."Requisites",
    "Individual"."Second_name",
    "Individual"."Name",
    "Individual"."Patronymic",
    "Individual"."City",
    "Individual"."Street",
    "Individual"."House",
    "Individual"."Flat",
    "Individual"."Passport_series",
    "Individual"."Passport_number",
    "Individual"."When_issued",
    "Individual"."Phone"
   FROM ((public."Contract"
     JOIN public."Manager" USING ("ID_manager"))
     JOIN public."Individual" USING ("ID_individual"));


ALTER VIEW public."MANAGER_FULL_INFO" OWNER TO postgres;

--
-- Name: CONTRACT_INFO; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."CONTRACT_INFO" AS
 SELECT "CUSTOMER_FULL_INFO"."Second_name" AS "Customers_sername",
    "CUSTOMER_FULL_INFO"."Name" AS "Customers_name",
    "CUSTOMER_FULL_INFO"."City" AS "Customers_city",
    "MANAGER_FULL_INFO"."Second_name" AS "Managers_sername",
    "MANAGER_FULL_INFO"."Name" AS "Managers_name",
    "MANAGER_FULL_INFO"."Patronymic" AS "Managers_patronymic",
    "MANAGER_FULL_INFO"."Phone" AS "Managers_phone",
    "Car"."Brand",
    "Car"."Model",
    "Car"."Mileage",
    "Car"."Price",
    "CUSTOMER_FULL_INFO"."Date_contract"
   FROM public."CUSTOMER_FULL_INFO",
    public."MANAGER_FULL_INFO",
    public."Contract",
    public."Car"
  WHERE (("Car"."ID_car" = ("Contract"."ID_car")::integer) AND ("MANAGER_FULL_INFO"."ID_contract" = "Contract"."ID_contract") AND ("CUSTOMER_FULL_INFO"."ID_contract" = "Contract"."ID_contract"));


ALTER VIEW public."CONTRACT_INFO" OWNER TO postgres;

--
-- Name: CUSTOMERS_INDIVIDUAL_INFO; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."CUSTOMERS_INDIVIDUAL_INFO" AS
 SELECT "Individual"."ID_individual",
    "Buyer"."ID_buyer",
    "Individual"."Second_name",
    "Individual"."Name",
    "Individual"."Patronymic",
    "Individual"."City",
    "Individual"."Street",
    "Individual"."House",
    "Individual"."Flat",
    "Individual"."Passport_series",
    "Individual"."Passport_number",
    "Individual"."When_issued",
    "Individual"."Phone"
   FROM (public."Buyer"
     JOIN public."Individual" USING ("ID_individual"));


ALTER VIEW public."CUSTOMERS_INDIVIDUAL_INFO" OWNER TO postgres;

--
-- Name: CUSTOMER_INFO; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."CUSTOMER_INFO" AS
 SELECT "Individual"."Second_name" AS "Customers_sername",
    "Individual"."Name" AS "Customers_name",
    "Individual"."City" AS "Customers_city"
   FROM ((public."Contract"
     JOIN public."Buyer" USING ("ID_buyer"))
     JOIN public."Individual" USING ("ID_individual"));


ALTER VIEW public."CUSTOMER_INFO" OWNER TO postgres;

--
-- Name: Car_ID_car_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Car_ID_car_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Car_ID_car_seq" OWNER TO postgres;

--
-- Name: Car_ID_car_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Car_ID_car_seq" OWNED BY public."Car"."ID_car";


--
-- Name: Car_purpose; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Car_purpose" (
    "ID_car_purpose" integer NOT NULL,
    "Name_purpose" public."technical-data"
);


ALTER TABLE public."Car_purpose" OWNER TO postgres;

--
-- Name: Car_purpose_ID_car_purpose_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Car_purpose_ID_car_purpose_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Car_purpose_ID_car_purpose_seq" OWNER TO postgres;

--
-- Name: Car_purpose_ID_car_purpose_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Car_purpose_ID_car_purpose_seq" OWNED BY public."Car_purpose"."ID_car_purpose";


--
-- Name: Contract_ID_contract_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Contract_ID_contract_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Contract_ID_contract_seq" OWNER TO postgres;

--
-- Name: Contract_ID_contract_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Contract_ID_contract_seq" OWNED BY public."Contract"."ID_contract";


--
-- Name: Drive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Drive" (
    "ID_drive" integer NOT NULL,
    "Type_drive" public."technical-data"
);


ALTER TABLE public."Drive" OWNER TO postgres;

--
-- Name: Drive_ID_drive_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Drive_ID_drive_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Drive_ID_drive_seq" OWNER TO postgres;

--
-- Name: Drive_ID_drive_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Drive_ID_drive_seq" OWNED BY public."Drive"."ID_drive";


--
-- Name: Gearbox; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Gearbox" (
    "ID_gearbox" integer NOT NULL,
    "Type_gearbox" public."technical-data"
);


ALTER TABLE public."Gearbox" OWNER TO postgres;

--
-- Name: Motor_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Motor_type" (
    "ID_motor_type" integer NOT NULL,
    "Name_motor" public."technical-data"
);


ALTER TABLE public."Motor_type" OWNER TO postgres;

--
-- Name: Suspension; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Suspension" (
    "ID_suspension" integer NOT NULL,
    "Type_suspension" public."technical-data"
);


ALTER TABLE public."Suspension" OWNER TO postgres;

--
-- Name: Technical_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Technical_data" (
    "ID_technical_data" integer NOT NULL,
    "Engine_displacement" integer,
    "Color" public."technical-data",
    "ID_body_type" public."fk-not-null",
    "ID_motor_type" public."fk-not-null",
    "ID_car_purpose" public."fk-not-null",
    "ID_drive" public."fk-not-null",
    "ID_gearbox" public."fk-null",
    "ID_suspension" public."fk-null"
);


ALTER TABLE public."Technical_data" OWNER TO postgres;

--
-- Name: FULL_CAR; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."FULL_CAR" AS
 SELECT "Car"."Availability",
    "Car"."Brand",
    "Car"."Model",
    "Car"."Mileage",
    "Car"."Price",
    "Technical_data"."Engine_displacement",
    "Technical_data"."Color",
    "Body_type"."Name_body",
    "Motor_type"."Name_motor",
    "Gearbox"."Type_gearbox",
    "Car_purpose"."Name_purpose",
    "Suspension"."Type_suspension",
    "Drive"."Type_drive"
   FROM (((((((public."Car"
     JOIN public."Technical_data" USING ("ID_technical_data"))
     JOIN public."Body_type" USING ("ID_body_type"))
     JOIN public."Motor_type" USING ("ID_motor_type"))
     JOIN public."Car_purpose" USING ("ID_car_purpose"))
     JOIN public."Drive" USING ("ID_drive"))
     JOIN public."Gearbox" USING ("ID_gearbox"))
     JOIN public."Suspension" USING ("ID_suspension"));


ALTER VIEW public."FULL_CAR" OWNER TO postgres;

--
-- Name: Gearbox_ID_gearbox_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Gearbox_ID_gearbox_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Gearbox_ID_gearbox_seq" OWNER TO postgres;

--
-- Name: Gearbox_ID_gearbox_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Gearbox_ID_gearbox_seq" OWNED BY public."Gearbox"."ID_gearbox";


--
-- Name: Individual_ID_individual_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Individual_ID_individual_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Individual_ID_individual_seq" OWNER TO postgres;

--
-- Name: Individual_ID_individual_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Individual_ID_individual_seq" OWNED BY public."Individual"."ID_individual";


--
-- Name: MANAGERS_INDIVIDUAL_INFO; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."MANAGERS_INDIVIDUAL_INFO" AS
 SELECT "Individual"."ID_individual",
    "Manager"."ID_manager",
    "Individual"."Second_name",
    "Individual"."Name",
    "Individual"."Patronymic",
    "Individual"."City",
    "Individual"."Street",
    "Individual"."House",
    "Individual"."Flat",
    "Individual"."Passport_series",
    "Individual"."Passport_number",
    "Individual"."When_issued",
    "Individual"."Phone"
   FROM (public."Manager"
     JOIN public."Individual" USING ("ID_individual"));


ALTER VIEW public."MANAGERS_INDIVIDUAL_INFO" OWNER TO postgres;

--
-- Name: MANAGER_INFO; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."MANAGER_INFO" AS
 SELECT DISTINCT "Individual"."Second_name" AS "Managers_sername",
    "Individual"."Name" AS "Managers_name",
    "Individual"."Patronymic" AS "Managers_patronymic",
    "Individual"."Phone" AS "Managers_phone"
   FROM ((public."Contract"
     JOIN public."Manager" ON (("Manager"."ID_manager" = ("Contract"."ID_manager")::integer)))
     JOIN public."Individual" USING ("ID_individual"));


ALTER VIEW public."MANAGER_INFO" OWNER TO postgres;

--
-- Name: Manager_ID_manager_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Manager_ID_manager_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Manager_ID_manager_seq" OWNER TO postgres;

--
-- Name: Manager_ID_manager_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Manager_ID_manager_seq" OWNED BY public."Manager"."ID_manager";


--
-- Name: Motor_type_ID_motor_type_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Motor_type_ID_motor_type_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Motor_type_ID_motor_type_seq" OWNER TO postgres;

--
-- Name: Motor_type_ID_motor_type_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Motor_type_ID_motor_type_seq" OWNED BY public."Motor_type"."ID_motor_type";


--
-- Name: Owner; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Owner" (
    "ID_owner" integer NOT NULL,
    "ID_individual" public."fk-not-null"
);


ALTER TABLE public."Owner" OWNER TO postgres;

--
-- Name: OWNERS_INDIVIDUAL_INFO; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."OWNERS_INDIVIDUAL_INFO" AS
 SELECT "Individual"."ID_individual",
    "Owner"."ID_owner",
    "Individual"."Second_name",
    "Individual"."Name",
    "Individual"."Patronymic",
    "Individual"."City",
    "Individual"."Street",
    "Individual"."House",
    "Individual"."Flat",
    "Individual"."Passport_series",
    "Individual"."Passport_number",
    "Individual"."When_issued",
    "Individual"."Phone"
   FROM (public."Owner"
     JOIN public."Individual" USING ("ID_individual"));


ALTER VIEW public."OWNERS_INDIVIDUAL_INFO" OWNER TO postgres;

--
-- Name: Owner_ID_owner_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Owner_ID_owner_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Owner_ID_owner_seq" OWNER TO postgres;

--
-- Name: Owner_ID_owner_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Owner_ID_owner_seq" OWNED BY public."Owner"."ID_owner";


--
-- Name: Owner_car; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Owner_car" (
    "ID_owner_car" integer NOT NULL,
    "ID_car" public."fk-not-null",
    "ID_owner" public."fk-not-null"
);


ALTER TABLE public."Owner_car" OWNER TO postgres;

--
-- Name: Owner_car_ID_owner_car_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Owner_car_ID_owner_car_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Owner_car_ID_owner_car_seq" OWNER TO postgres;

--
-- Name: Owner_car_ID_owner_car_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Owner_car_ID_owner_car_seq" OWNED BY public."Owner_car"."ID_owner_car";


--
-- Name: Suspension_ID_suspension_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Suspension_ID_suspension_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Suspension_ID_suspension_seq" OWNER TO postgres;

--
-- Name: Suspension_ID_suspension_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Suspension_ID_suspension_seq" OWNED BY public."Suspension"."ID_suspension";


--
-- Name: Technical_data_ID_technical_data_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Technical_data_ID_technical_data_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Technical_data_ID_technical_data_seq" OWNER TO postgres;

--
-- Name: Technical_data_ID_technical_data_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Technical_data_ID_technical_data_seq" OWNED BY public."Technical_data"."ID_technical_data";


--
-- Name: UNSOLD_CARS; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."UNSOLD_CARS" AS
 SELECT "Car"."Availability",
    "Car"."Brand",
    "Car"."Model",
    "Car"."Mileage",
    "Car"."Year_of_issue",
    "Car"."Price"
   FROM public."Car"
  WHERE (NOT (EXISTS ( SELECT 1
           FROM public."Contract"
          WHERE ("Car"."ID_car" = ("Contract"."ID_car")::integer))));


ALTER VIEW public."UNSOLD_CARS" OWNER TO postgres;

--
-- Name: car_audits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.car_audits (
    id integer NOT NULL,
    description character varying,
    changed timestamp without time zone NOT NULL,
    id_car integer NOT NULL
);


ALTER TABLE public.car_audits OWNER TO postgres;

--
-- Name: contract_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contract_audits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.contract_audits_id_seq OWNER TO postgres;

--
-- Name: contract_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contract_audits_id_seq OWNED BY public.car_audits.id;


--
-- Name: full_car_audits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.full_car_audits (
    "ID_car" integer NOT NULL,
    "VIN" character varying(20) NOT NULL,
    "Availability" boolean NOT NULL,
    "Brand" character varying(50),
    "Model" character varying(50),
    "Mileage" public.mileage,
    "Year_of_issue" integer NOT NULL,
    "Price" numeric NOT NULL,
    "ID_technical_data" public."fk-not-null",
    start_date timestamp without time zone,
    end_date timestamp without time zone
);


ALTER TABLE public.full_car_audits OWNER TO postgres;

--
-- Name: individual_audits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.individual_audits (
    id integer NOT NULL,
    sername public."name-or-passport",
    changed_on timestamp without time zone NOT NULL,
    id_individual integer NOT NULL
);


ALTER TABLE public.individual_audits OWNER TO postgres;

--
-- Name: individual_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.individual_audits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.individual_audits_id_seq OWNER TO postgres;

--
-- Name: individual_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.individual_audits_id_seq OWNED BY public.individual_audits.id;


--
-- Name: motor_type_audits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_type_audits (
    id integer NOT NULL,
    name_motor public."technical-data",
    added timestamp without time zone NOT NULL,
    id_motor integer NOT NULL
);


ALTER TABLE public.motor_type_audits OWNER TO postgres;

--
-- Name: motor_type_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_type_audits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_type_audits_id_seq OWNER TO postgres;

--
-- Name: motor_type_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_type_audits_id_seq OWNED BY public.motor_type_audits.id;


--
-- Name: Body_type ID_body_type; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Body_type" ALTER COLUMN "ID_body_type" SET DEFAULT nextval('public."Body_type_ID_body_type_seq"'::regclass);


--
-- Name: Buyer ID_buyer; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Buyer" ALTER COLUMN "ID_buyer" SET DEFAULT nextval('public."Buyer_ID_buyer_seq"'::regclass);


--
-- Name: Car ID_car; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Car" ALTER COLUMN "ID_car" SET DEFAULT nextval('public."Car_ID_car_seq"'::regclass);


--
-- Name: Car_purpose ID_car_purpose; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Car_purpose" ALTER COLUMN "ID_car_purpose" SET DEFAULT nextval('public."Car_purpose_ID_car_purpose_seq"'::regclass);


--
-- Name: Contract ID_contract; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Contract" ALTER COLUMN "ID_contract" SET DEFAULT nextval('public."Contract_ID_contract_seq"'::regclass);


--
-- Name: Drive ID_drive; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Drive" ALTER COLUMN "ID_drive" SET DEFAULT nextval('public."Drive_ID_drive_seq"'::regclass);


--
-- Name: Gearbox ID_gearbox; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Gearbox" ALTER COLUMN "ID_gearbox" SET DEFAULT nextval('public."Gearbox_ID_gearbox_seq"'::regclass);


--
-- Name: Individual ID_individual; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Individual" ALTER COLUMN "ID_individual" SET DEFAULT nextval('public."Individual_ID_individual_seq"'::regclass);


--
-- Name: Manager ID_manager; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Manager" ALTER COLUMN "ID_manager" SET DEFAULT nextval('public."Manager_ID_manager_seq"'::regclass);


--
-- Name: Motor_type ID_motor_type; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Motor_type" ALTER COLUMN "ID_motor_type" SET DEFAULT nextval('public."Motor_type_ID_motor_type_seq"'::regclass);


--
-- Name: Owner ID_owner; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Owner" ALTER COLUMN "ID_owner" SET DEFAULT nextval('public."Owner_ID_owner_seq"'::regclass);


--
-- Name: Owner_car ID_owner_car; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Owner_car" ALTER COLUMN "ID_owner_car" SET DEFAULT nextval('public."Owner_car_ID_owner_car_seq"'::regclass);


--
-- Name: Suspension ID_suspension; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Suspension" ALTER COLUMN "ID_suspension" SET DEFAULT nextval('public."Suspension_ID_suspension_seq"'::regclass);


--
-- Name: Technical_data ID_technical_data; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Technical_data" ALTER COLUMN "ID_technical_data" SET DEFAULT nextval('public."Technical_data_ID_technical_data_seq"'::regclass);


--
-- Name: car_audits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.car_audits ALTER COLUMN id SET DEFAULT nextval('public.contract_audits_id_seq'::regclass);


--
-- Name: individual_audits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.individual_audits ALTER COLUMN id SET DEFAULT nextval('public.individual_audits_id_seq'::regclass);


--
-- Name: motor_type_audits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_type_audits ALTER COLUMN id SET DEFAULT nextval('public.motor_type_audits_id_seq'::regclass);


--
-- Data for Name: Body_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Body_type" ("ID_body_type", "Name_body") FROM stdin;
1	Седан
2	Универсал
3	Хэтчбэк
4	Купе
5	Лимузин
6	Микроавтобус
7	Минивэн
8	Лифтбэк
9	Фастбэк
10	Кабриолет
11	Пикап
12	Фургон
13	Ландо
14	Родстер
15	Фаэтон
16	Хардтоп
\.


--
-- Data for Name: Buyer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Buyer" ("ID_buyer", "ID_individual") FROM stdin;
1	1
2	2
3	3
4	5
5	6
6	7
7	8
8	9
9	10
10	11
11	12
12	16
13	20
14	13
15	14
16	19
17	67
18	69
\.


--
-- Data for Name: Car; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Car" ("ID_car", "VIN", "Availability", "Brand", "Model", "Mileage", "Year_of_issue", "Price", "ID_technical_data") FROM stdin;
2	PM5LJ521698287551	t	Citroen	Niva	47805	2008	21000	2
4	ZT1MJ461118739436	t	Chevrolet	Punto	58000	2007	18260	4
7	NY1BG117593709671	f	Chevrolet	C1	57466	2011	17234	7
8	ZF8NU429753768503	t	Citroen	C2	45004	2004	12374	8
9	AD8SV026674932754	t	Audi	Focus	52701	2012	11000	9
10	YV2FF907687937431	t	Volvo	S40	82064	2001	10631	10
12	AP6EK974486133979	t	Hyundai	EX	91724	2003	20036	12
13	TG3SV505057438747	t	Geely	Emgrand EC7	140000	2013	14440	13
14	DH1JY488929465542	t	Chevrolet	Corvette	72543	2002	16900	14
16	MT1KX660716104886	t	Fiat	Panda	86445	2000	15886	16
17	PG3FE631571316961	t	Daewoo	Magnus	21244	2001	13323	17
21	EB1FL509628216814	t	Daewoo	Lanos	102732	2018	24124	20
22	VF4LE876117082577	t	Volvo	S40	5224	2001	15870	10
23	EV1UP601271951611	t	Audi	A3	40898	2014	20000	5
6	YR0KT422642947405	t	Infiniti	Civic	200000	2015	10597.4	6
1	ZL0FP832971801121	t	Chery	S80	60000	2008	24000	1
15	LU9JH543620286156	t	Audi	A5	172002	2005	9179.5	15
18	ZM2MZ670380950152	t	Audi	A3	125423	2014	12477	5
19	NH7XM501015319270	t	BMW	Explorer	104154	2010	17488	18
64	WVjjjZCAZJC551511	t	Audi	A4	50000	1992	6400	5
5	AA0ZE994341824944	t	Geely	V70	49060	2020	19377	3
11	VN8TV229662060407	t	BMW	C3 Aircross	30452	2019	19000	3
3	YL8RX563018151667	t	Honda	tttyyt	203225	2020	30000	3
\.


--
-- Data for Name: Car_purpose; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Car_purpose" ("ID_car_purpose", "Name_purpose") FROM stdin;
1	Грузовые
2	Легковые
3	Автобусы
4	Грузопассажирские
5	Гоночные
6	Тракторы
7	Бульдозеры
8	Бронемобили
9	Внедорожники
\.


--
-- Data for Name: Contract; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Contract" ("ID_contract", "ID_buyer", "ID_manager", "ID_car", "Date_contract", "Payment_type", "Requisites") FROM stdin;
35	4	2	3	2021-04-30	Наличными в кредит	\N
36	5	3	4	2007-09-17	Наличными сразу	\N
37	6	1	5	2020-04-04	Перечисление	50565453200000002213
38	7	2	6	2016-07-03	Перечисление	40530486100000008938
39	8	3	8	2012-07-15	Наличными сразу	\N
40	9	3	9	2014-10-16	Перечисление	40214885900000004920
41	10	1	10	2019-02-25	Перечисление	50565453200000002213
42	11	3	11	2020-12-29	Наличными сразу	\N
43	12	1	12	2020-03-18	Перечисление	50565453200000002213
44	13	3	13	2016-06-20	Наличными в кредит	\N
45	2	2	14	2021-05-19	Перечисление	40530486100000008938
46	5	3	15	2017-05-13	Перечисление	40214885900000004920
47	12	3	16	2005-05-15	Перечисление	40214885900000004920
48	4	2	17	2009-11-08	Перечисление	40530486100000008938
49	8	3	19	2015-01-05	Перечисление	40214885900000004920
51	13	1	21	2019-08-28	Перечисление	50565453200000002213
52	6	3	14	2014-01-01	Наличные	555544444
50	9	2	19	2021-10-16	Наличными в кредит	\N
\.


--
-- Data for Name: Drive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Drive" ("ID_drive", "Type_drive") FROM stdin;
1	Передний
2	Задний
3	Полный
\.


--
-- Data for Name: Gearbox; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Gearbox" ("ID_gearbox", "Type_gearbox") FROM stdin;
1	Автоматическая
2	Робот
3	Вариатор
4	Механическая
\.


--
-- Data for Name: Individual; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Individual" ("ID_individual", "Second_name", "Name", "Patronymic", "City", "Street", "House", "Flat", "Passport_series", "Passport_number", "When_issued", "Phone") FROM stdin;
1	Андрюхина	Стела	Андрияновна	Раменское	проезд Гагарина	64	38	4437	675506	2019-12-08	+7 (994) 153-96-12
2	Деревскова	Александра	Павеловна	Дмитров	проспект Косиора	68	10	4359	611301	2013-03-26	+7 (980) 642-73-47
3	Фонвизин	Дмитрий	Игоревич	Москва	ул. Будапештсткая	13	\N	4599	316679	2018-04-13	+7 (966) 565-94-68
4	Ёжин	Михаил	Онуфриевич	Балашиха	ул. Бухарестская	28	47	4865	397324	2015-07-13	+7 (909) 914-58-94
5	Евстигнеев	Фадей	Брониславович	Луховицы	шоссе Космонавтов	30	42	4494	264189	2015-10-16	+7 (981) 129-55-14
6	Кузьмич	Евграф	Филимонович	Озёры	спуск Ленина	69	99	4767	815194	2015-12-10	+7 (989) 710-93-72
7	Зюлёв	Артур	Вячеславович	Клин	наб. Домодедовская	33	07	4620	704648	2020-08-07	+7 (920) 238-99-55
8	Прибыльнова	Бронислава	Игоревна	Клин	шоссе Ломоносова	69	90	4310	894977	2021-06-21	\N
9	Хабибова	Раиса	Евгениевна	Щёлково	бульвар Бухарестская	52	\N	4173	938828	2013-02-21	+7 (945) 928-33-63
10	Тимирязев	Тихон	\N	Москва	шоссе Космонавтов	16	\N	4637	886959	2016-04-06	+7 (936) 657-68-71
11	Кашарина	Зоя	Емельяновна	Орехово-Зуево	ул. Сталина	65	53	4393	177835	2012-11-13	+7 (954) 281-95-36
12	Пономарёв	Тарас	Кондратиевич	Воскресенск	вокзал Славы	70	12	4854	689222	2013-07-09	+7 (992) 983-34-71
14	Папанов	Владилен	Ипполитович	\N	\N	\N	49	4977	549186	2020-06-02	+7 (960) 851-82-67
15	Карташёв	Борислав	Аполлинариевич	Луховицы	шоссе Чехова	16	19	4118	571888	2019-06-17	+7 (942) 271-50-31
17	Шапиро	Розалия	Михеевна	Чехов	спуск Гоголя	95	\N	4887	629787	2019-07-15	+7 (954) 393-72-83
18	Яременко	Ярослав	Проклович	Видное	шоссе Домодедовская	81	04	4674	323474	2014-07-24	\N
19	Пономарёва	Розалия	Леонидовна	Волоколамск	ул. Балканская	82	68	4096	354116	2021-12-09	+7 (941) 539-99-62
16	Геннадьев	Гаврила	Викентиевич	Москва	шоссе Сталина	63	80	4358	147753	2014-11-30	+7 (962) 473-24-85
20	Романова	Клара	Антониновна	Дмитров	шоссе Сталина	17	17	4631	660201	2012-04-07	+7 (994) 380-74-30
31	Савельев	Сергей	Михайлович	Москва	ул. Прохоровка	589	4	7856	48256	2014-05-26	+7 (567) 345-56-80
23	Озёров	Максим	Петрович	Санкт-Петербург	ул. Хельсинки	21	8	487T	591252	2010-02-09	+7 (925) 829-19-43
13	Кондучалов	Мирослав	Геннадиевич	Сергиев Посад	ул. Косиора	72	47	4271	553361	2013-10-28	+7 (777) 111-22-90
46	Борис	Борисов	Павлович	Ташкент	Гагарина	2	3	4565	45456	2004-05-03	79300957916
66	Кириллов	Геннадий	Павлович	Прага	36	25	78	154	518955659	1991-05-01	2639175703
67	Некрасов	Гавриил	Романович	Лихтенштейн	24 Гагарина	7	86	42	26594949	1980-06-04	592629419
68	Максимов	Герасим	Валерьевич	Мадрид	Преображенская	8	78	59	82827327	1995-09-03	282327237
69	Артем	Джонсон	Николаевич	Варшава	14 Романова	6	59	96	7327828	1996-08-04	5619494659
70	Орел	Иван	Метисович	Рига	Главная 4	51	36	84	32465985	1998-07-08	95156599
\.


--
-- Data for Name: Manager; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Manager" ("ID_manager", "ID_individual") FROM stdin;
1	4
2	13
3	19
4	16
5	15
6	12
7	11
8	10
9	66
\.


--
-- Data for Name: Motor_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Motor_type" ("ID_motor_type", "Name_motor") FROM stdin;
1	Паровая машина
4	Газовый двигатель
5	Электрический мотор
7	Водородный мотор
8	Магнитный двигатель
2	Бензиновый
3	Дизельный
6	Гибридный
9	Атомный
\.


--
-- Data for Name: Owner; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Owner" ("ID_owner", "ID_individual") FROM stdin;
1	14
2	15
3	17
4	18
5	1
6	6
7	10
8	2
9	7
10	16
11	9
12	8
13	3
14	20
15	70
\.


--
-- Data for Name: Owner_car; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Owner_car" ("ID_owner_car", "ID_car", "ID_owner") FROM stdin;
1	1	1
2	2	2
3	3	3
4	4	4
5	5	9
6	6	10
7	7	5
8	8	6
9	9	7
10	10	8
11	11	11
12	12	13
13	13	12
14	14	4
15	15	5
16	16	6
17	17	6
18	18	10
19	19	6
21	21	11
22	22	1
23	23	2
20	2	6
\.


--
-- Data for Name: Suspension; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Suspension" ("ID_suspension", "Type_suspension") FROM stdin;
1	Активная
2	Спортивная
3	Пневмоподвеска
\.


--
-- Data for Name: Technical_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Technical_data" ("ID_technical_data", "Engine_displacement", "Color", "ID_body_type", "ID_motor_type", "ID_car_purpose", "ID_drive", "ID_gearbox", "ID_suspension") FROM stdin;
1	5	Абрикосовый	8	1	2	1	1	1
2	3	Красный	2	2	1	2	2	2
3	1	Алый	4	2	2	3	2	3
4	\N	Пурпурный	8	8	2	1	3	2
5	4	Розовый	16	2	3	3	1	1
6	8	Серый	1	4	5	3	2	2
7	8	Белый	3	1	1	3	4	1
8	4	Белый	10	2	2	2	1	3
9	1	Черный	11	3	6	1	4	1
10	\N	Зеленый	14	5	2	1	3	3
11	5	Жёлтый	3	2	9	2	1	2
12	3	Белый	7	6	2	3	3	3
13	2	Фиолетовый	9	2	5	3	4	1
14	9	Зеленый	13	2	8	2	4	1
15	6	Коричневый	12	6	4	3	1	2
16	\N	Черный	6	5	3	2	3	1
17	4	Оранжевый	3	3	4	1	2	3
18	5	Синий	4	3	7	2	1	2
19	\N	Черный	15	8	2	1	4	1
20	6	Белый	1	7	2	3	3	3
\.


--
-- Data for Name: car_audits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.car_audits (id, description, changed, id_car) FROM stdin;
1	Update car and this car is available	2022-04-28 19:57:34.945313	15
2	Update car and this car is available	2022-04-28 19:57:34.945313	18
3	Update car and this car is available	2022-04-28 19:57:34.945313	19
4	Add new car and this car is available	2022-04-29 12:42:13.036011	24
5	Add new car and this car is available	2022-04-29 12:43:35.589841	63
6	Update car and this car is available	2022-04-29 12:49:07.377424	25
7	Update car and this car is available	2022-04-29 14:02:12.044797	24
8	Add new car and this car is available	2022-05-24 23:59:20.631585	64
9	Add new car and this car is not available	2022-05-25 00:51:40.074774	65
10	Add new car and this car is not available	2022-05-25 00:51:56.322002	66
11	Add new car and this car is not available	2022-05-25 00:52:14.508527	67
12	Add new car and this car is available	2022-05-25 00:54:59.142686	68
13	Add new car and this car is not available	2022-05-25 00:56:45.814734	69
14	Add new car and this car is not available	2022-05-25 00:59:43.408907	70
15	Add new car and this car is available	2022-05-25 01:09:32.844941	71
16	Add new car and this car is available	2022-05-25 01:35:12.323775	72
17	Update car and this car is available	2022-05-25 04:03:46.828158	5
18	Update car and this car is available	2022-05-25 04:03:49.441815	3
19	Update car and this car is available	2022-05-25 04:03:53.202153	11
20	Update car and this car is available	2022-05-25 04:03:56.610952	20
21	Update car and this car is available	2022-05-25 04:04:21.500797	20
22	Update car and this car is available	2022-05-25 05:14:56.49097	20
23	Add new car and this car is available	2022-05-25 05:15:10.892237	73
24	Add new car and this car is available	2022-05-25 05:34:25.547854	74
25	Add new car and this car is available	2022-05-25 05:34:32.046131	75
26	Add new car and this car is available	2022-05-25 05:34:44.676291	76
27	Add new car and this car is available	2022-05-25 05:34:56.55134	77
28	Update car and this car is available	2022-05-25 05:35:18.886703	74
29	Update car and this car is available	2022-05-25 05:35:28.073738	75
30	Update car and this car is available	2022-05-25 05:35:37.333061	77
31	Add new car and this car is available	2022-05-25 12:26:50.666485	78
32	Update car and this car is available	2022-05-25 12:32:46.447861	3
33	Add new car and this car is available	2022-05-25 15:24:23.137164	79
34	Update car and this car is available	2022-05-25 15:24:52.96209	3
\.


--
-- Data for Name: full_car_audits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.full_car_audits ("ID_car", "VIN", "Availability", "Brand", "Model", "Mileage", "Year_of_issue", "Price", "ID_technical_data", start_date, end_date) FROM stdin;
63	TRV1UPTY71991602	t	BMV	Explorer	40500	2010	18860	18	2022-04-29 12:43:35.589841	2022-04-29 12:49:07.377424
25	TRV1UPTY71991602	t	BMV	Explorer	40500	2010	19500	18	2022-04-29 12:49:07.377424	2022-04-29 12:52:24.995836
24	GV1UP6652732431698	t	BMV	Explorer	52746	2010	18605	18	2022-04-29 12:42:13.036011	2022-04-29 14:02:12.044797
24	GV1UP6652732431698	t	BMW	Explorer	52746	2010	18605	18	2022-04-29 14:02:12.044797	2022-04-29 18:35:54.483264
64	WVjjjZCAZJC551511	t	Audi	A4	50000	1992	6400	5	2022-05-24 23:59:20.631585	\N
71	sfgsdg	t	sdgfdsg	sdgdsg	155	2020	9465	3	2022-05-25 01:09:32.844941	2022-05-25 01:34:37.546406
70	tesgs	f	fsgs	dsgdsg	8574	2020	7411	3	2022-05-25 00:59:43.408907	2022-05-25 01:34:41.626144
69	bhdghh	f	ghdf	fghdh	4141	2019	4142525	3	2022-05-25 00:56:45.814734	2022-05-25 01:34:45.220816
68	sfgsdfg	t	sdg	sdfgd	2582	2020	54245	3	2022-05-25 00:54:59.142686	2022-05-25 01:34:48.723776
72	sgdsgd	t	dsfg	dsgds	10550	2020	5000	3	2022-05-25 01:35:12.323775	2022-05-25 01:35:22.798689
5	AA0ZE994341824944	t	Geely	V70	49060	2020	19377	3	2022-05-25 04:03:46.828158	\N
11	VN8TV229662060407	t	BMW	C3 Aircross	30452	2019	19000	3	2022-05-25 04:03:53.202153	\N
20	ZL0EY723168248711	t	Volvo	Epica	13858	2020	11231	3	2022-05-25 04:03:56.610952	2022-05-25 04:04:21.500797
20	0	t	Volvo	Epica	13858	2020	11231	3	2022-05-25 04:04:21.500797	2022-05-25 05:14:56.49097
73	85858	t	Volvo	Epica	13858	2020	11231	3	2022-05-25 05:15:10.892237	2022-05-25 05:16:01.645022
76	3	t	Volvo	Epica	13858	2020	11231	3	2022-05-25 05:34:44.676291	2022-05-25 05:35:09.297951
74	1	t	Geely	V70	49060	2020	19377	3	2022-05-25 05:34:25.547854	2022-05-25 05:35:18.886703
75	2	t	Volvo	Epica	13858	2020	11231	3	2022-05-25 05:34:32.046131	2022-05-25 05:35:28.073738
77	4	t	Geely	V70	49060	2020	19377	3	2022-05-25 05:34:56.55134	2022-05-25 05:35:37.333061
75	23	t	Volvo	Epica	13858	2020	11231	3	2022-05-25 05:35:28.073738	2022-05-25 05:35:52.321135
77	400	t	Geely	V70	49060	2020	19377	3	2022-05-25 05:35:37.333061	2022-05-25 05:36:08.349887
74	1	t	Geely	V70	49060	2020	19377	3	2022-05-25 05:35:18.886703	2022-05-25 11:43:25.673039
66	hgjghj	f	gf	dfgd	5525	0	5242	3	2022-05-25 00:51:56.322002	2022-05-25 11:43:25.673039
67	dsgdsg	f	fdg	dfgsgsdf	543463	0	522524	3	2022-05-25 00:52:14.508527	2022-05-25 11:43:25.673039
20	5555	t	Volvo	Epica	13858	2020	11231	3	2022-05-25 05:14:56.49097	2022-05-25 11:43:25.673039
65	ffgdgf	f	bmv	fgd	25	1	4525	3	2022-05-25 00:51:40.074774	2022-05-25 11:44:49.14175
78	JHFI25RG548	t	BMV	O90	100000	2021	23000	3	2022-05-25 12:26:50.666485	2022-05-25 12:29:31.122998
3	YL8RX563018151667	t	Honda	City	203225	2020	10300	3	2022-05-25 04:03:49.441815	2022-05-25 12:32:46.447861
79	55253	t	BMV	City	50000	2021	40000	3	2022-05-25 15:24:23.137164	2022-05-25 15:24:31.952176
3	YL8RX563018151667	t	Honda	City	203225	2020	30000	3	2022-05-25 12:32:46.447861	2022-05-25 15:24:52.96209
3	YL8RX563018151667	t	Honda	tttyyt	203225	2020	30000	3	2022-05-25 15:24:52.96209	\N
\.


--
-- Data for Name: individual_audits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.individual_audits (id, sername, changed_on, id_individual) FROM stdin;
1	Никифоров	2022-04-28 17:37:49.282149	30
2	Норин	2022-04-28 17:39:56.630638	16
3	Клокова	2022-04-28 17:39:56.630638	20
4	Романов	2022-04-28 17:39:56.630638	30
5	Фадеев	2022-04-28 21:31:05.515541	31
6	Филимонов	2022-04-28 21:51:45.032713	31
7	Филимоновl	2022-04-28 21:52:17.117428	31
8	Филимонов	2022-04-28 21:54:00.15329	31
9	Филимоновl	2022-04-28 21:55:41.027761	31
10	Филимонов	2022-04-28 21:57:56.060173	31
11	Савелий	2022-04-28 22:26:41.832649	31
12	Савельев	2022-04-28 22:38:22.75885	31
13	Иван	2022-04-28 22:39:20.789632	31
\.


--
-- Data for Name: motor_type_audits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_type_audits (id, name_motor, added, id_motor) FROM stdin;
11	Update motorБензиновый	2022-04-28 18:49:18.63492	2
12	Update motorДизельный	2022-04-28 18:51:06.560718	3
13	Update motorГибридный	2022-04-28 18:51:06.560718	6
14	Add new motorАтомный	2022-04-28 18:54:48.418231	9
\.


--
-- Name: Body_type_ID_body_type_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Body_type_ID_body_type_seq"', 16, true);


--
-- Name: Buyer_ID_buyer_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Buyer_ID_buyer_seq"', 18, true);


--
-- Name: Car_ID_car_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Car_ID_car_seq"', 79, true);


--
-- Name: Car_purpose_ID_car_purpose_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Car_purpose_ID_car_purpose_seq"', 9, true);


--
-- Name: Contract_ID_contract_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Contract_ID_contract_seq"', 54, true);


--
-- Name: Drive_ID_drive_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Drive_ID_drive_seq"', 3, true);


--
-- Name: Gearbox_ID_gearbox_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Gearbox_ID_gearbox_seq"', 4, true);


--
-- Name: Individual_ID_individual_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Individual_ID_individual_seq"', 70, true);


--
-- Name: Manager_ID_manager_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Manager_ID_manager_seq"', 9, true);


--
-- Name: Motor_type_ID_motor_type_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Motor_type_ID_motor_type_seq"', 8, true);


--
-- Name: Owner_ID_owner_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Owner_ID_owner_seq"', 15, true);


--
-- Name: Owner_car_ID_owner_car_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Owner_car_ID_owner_car_seq"', 23, true);


--
-- Name: Suspension_ID_suspension_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Suspension_ID_suspension_seq"', 3, true);


--
-- Name: Technical_data_ID_technical_data_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Technical_data_ID_technical_data_seq"', 23, true);


--
-- Name: contract_audits_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.contract_audits_id_seq', 34, true);


--
-- Name: individual_audits_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.individual_audits_id_seq', 13, true);


--
-- Name: motor_type_audits_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_type_audits_id_seq', 14, true);


--
-- Name: Body_type Body_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Body_type"
    ADD CONSTRAINT "Body_type_pkey" PRIMARY KEY ("ID_body_type");


--
-- Name: Buyer Buyer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Buyer"
    ADD CONSTRAINT "Buyer_pkey" PRIMARY KEY ("ID_buyer");


--
-- Name: Car Car_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Car"
    ADD CONSTRAINT "Car_pkey" PRIMARY KEY ("ID_car");


--
-- Name: Car_purpose Car_purpose_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Car_purpose"
    ADD CONSTRAINT "Car_purpose_pkey" PRIMARY KEY ("ID_car_purpose");


--
-- Name: Contract Contract_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Contract"
    ADD CONSTRAINT "Contract_pkey" PRIMARY KEY ("ID_contract");


--
-- Name: Drive Drive_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Drive"
    ADD CONSTRAINT "Drive_pkey" PRIMARY KEY ("ID_drive");


--
-- Name: Gearbox Gearbox_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Gearbox"
    ADD CONSTRAINT "Gearbox_pkey" PRIMARY KEY ("ID_gearbox");


--
-- Name: Individual Individual_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Individual"
    ADD CONSTRAINT "Individual_pkey" PRIMARY KEY ("ID_individual");


--
-- Name: Manager Manager_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Manager"
    ADD CONSTRAINT "Manager_pkey" PRIMARY KEY ("ID_manager");


--
-- Name: Motor_type Motor_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Motor_type"
    ADD CONSTRAINT "Motor_type_pkey" PRIMARY KEY ("ID_motor_type");


--
-- Name: Owner_car Owner_car_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Owner_car"
    ADD CONSTRAINT "Owner_car_pkey" PRIMARY KEY ("ID_owner_car");


--
-- Name: Owner Owner_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Owner"
    ADD CONSTRAINT "Owner_pkey" PRIMARY KEY ("ID_owner");


--
-- Name: Suspension Suspension_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Suspension"
    ADD CONSTRAINT "Suspension_pkey" PRIMARY KEY ("ID_suspension");


--
-- Name: Technical_data Technical_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Technical_data"
    ADD CONSTRAINT "Technical_data_pkey" PRIMARY KEY ("ID_technical_data");


--
-- Name: car_audits contract_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.car_audits
    ADD CONSTRAINT contract_audits_pkey PRIMARY KEY (id);


--
-- Name: individual_audits individual_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.individual_audits
    ADD CONSTRAINT individual_audits_pkey PRIMARY KEY (id);


--
-- Name: motor_type_audits motor_type_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_type_audits
    ADD CONSTRAINT motor_type_audits_pkey PRIMARY KEY (id);


--
-- Name: VIN_ui; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "VIN_ui" ON public."Car" USING btree ("VIN");


--
-- Name: fki_I; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "fki_I" ON public."Technical_data" USING btree ("ID_car_purpose");


--
-- Name: fki_S; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "fki_S" ON public."Technical_data" USING btree ("ID_suspension");


--
-- Name: fki_buyer_individ_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_buyer_individ_fk ON public."Buyer" USING btree ("ID_individual");


--
-- Name: fki_buyer_individual_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_buyer_individual_fk ON public."Buyer" USING btree ("ID_individual");


--
-- Name: fki_car_technical_data_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_car_technical_data_fk ON public."Car" USING btree ("ID_technical_data");


--
-- Name: fki_contract_buyer_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_contract_buyer_fk ON public."Contract" USING btree ("ID_buyer");


--
-- Name: fki_contract_car_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_contract_car_fk ON public."Contract" USING btree ("ID_car");


--
-- Name: fki_contract_manager_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_contract_manager_fk ON public."Contract" USING btree ("ID_manager");


--
-- Name: fki_manager_individ_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_manager_individ_fk ON public."Manager" USING btree ("ID_individual");


--
-- Name: fki_owner_car_car_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_owner_car_car_fk ON public."Owner_car" USING btree ("ID_car");


--
-- Name: fki_owner_car_owner_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_owner_car_owner_fk ON public."Owner_car" USING btree ("ID_owner");


--
-- Name: fki_owner_individ_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_owner_individ_fk ON public."Owner" USING btree ("ID_individual");


--
-- Name: fki_technical_data_body_type_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_technical_data_body_type_fk ON public."Technical_data" USING btree ("ID_body_type");


--
-- Name: fki_technical_data_drive_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_technical_data_drive_fk ON public."Technical_data" USING btree ("ID_drive");


--
-- Name: fki_technical_data_gearbox_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_technical_data_gearbox_fk ON public."Technical_data" USING btree ("ID_gearbox");


--
-- Name: fki_technical_data_motor_type_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_technical_data_motor_type_fk ON public."Technical_data" USING btree ("ID_motor_type");


--
-- Name: Car car_audits_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER car_audits_delete AFTER DELETE OR UPDATE ON public."Car" FOR EACH ROW EXECUTE FUNCTION public.log_delete();


--
-- Name: Car car_audits_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER car_audits_insert AFTER INSERT OR UPDATE ON public."Car" FOR EACH ROW EXECUTE FUNCTION public.log_insert();


--
-- Name: Car car_available; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER car_available AFTER INSERT OR UPDATE ON public."Car" FOR EACH ROW EXECUTE FUNCTION public.log_car();


--
-- Name: Car delete_car; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER delete_car BEFORE DELETE ON public."Car" FOR EACH ROW EXECUTE FUNCTION public.t_delete_car();


--
-- Name: Individual insert_individual; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER insert_individual BEFORE INSERT OR UPDATE ON public."Individual" FOR EACH ROW EXECUTE FUNCTION public.t_insert_individual();


--
-- Name: Motor_type motor; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER motor AFTER INSERT OR UPDATE ON public."Motor_type" FOR EACH ROW EXECUTE FUNCTION public.logs_motor();


--
-- Name: Individual sername_changes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER sername_changes BEFORE UPDATE ON public."Individual" FOR EACH ROW EXECUTE FUNCTION public.log_sername_changes();


--
-- Name: MANAGER_INFO update_phone; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_phone INSTEAD OF UPDATE ON public."MANAGER_INFO" FOR EACH ROW EXECUTE FUNCTION public."t_update_MANAGER_INFO"();


--
-- Name: Buyer buyer_individ_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Buyer"
    ADD CONSTRAINT buyer_individ_fk FOREIGN KEY ("ID_individual") REFERENCES public."Individual"("ID_individual") NOT VALID;


--
-- Name: Car car_technical_data_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Car"
    ADD CONSTRAINT car_technical_data_fk FOREIGN KEY ("ID_technical_data") REFERENCES public."Technical_data"("ID_technical_data") NOT VALID;


--
-- Name: Contract contract_buyer_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Contract"
    ADD CONSTRAINT contract_buyer_fk FOREIGN KEY ("ID_buyer") REFERENCES public."Buyer"("ID_buyer") NOT VALID;


--
-- Name: Contract contract_car_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Contract"
    ADD CONSTRAINT contract_car_fk FOREIGN KEY ("ID_car") REFERENCES public."Car"("ID_car") NOT VALID;


--
-- Name: Contract contract_manager_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Contract"
    ADD CONSTRAINT contract_manager_fk FOREIGN KEY ("ID_manager") REFERENCES public."Manager"("ID_manager") NOT VALID;


--
-- Name: Manager manager_individ_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Manager"
    ADD CONSTRAINT manager_individ_fk FOREIGN KEY ("ID_individual") REFERENCES public."Individual"("ID_individual") NOT VALID;


--
-- Name: Owner_car owner_car_car_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Owner_car"
    ADD CONSTRAINT owner_car_car_fk FOREIGN KEY ("ID_car") REFERENCES public."Car"("ID_car") NOT VALID;


--
-- Name: Owner_car owner_car_owner_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Owner_car"
    ADD CONSTRAINT owner_car_owner_fk FOREIGN KEY ("ID_owner") REFERENCES public."Owner"("ID_owner") NOT VALID;


--
-- Name: Owner owner_individ_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Owner"
    ADD CONSTRAINT owner_individ_fk FOREIGN KEY ("ID_individual") REFERENCES public."Individual"("ID_individual") NOT VALID;


--
-- Name: Technical_data technical_data_body_type_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Technical_data"
    ADD CONSTRAINT technical_data_body_type_fk FOREIGN KEY ("ID_body_type") REFERENCES public."Body_type"("ID_body_type") NOT VALID;


--
-- Name: Technical_data technical_data_car_purpose_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Technical_data"
    ADD CONSTRAINT technical_data_car_purpose_fk FOREIGN KEY ("ID_car_purpose") REFERENCES public."Car_purpose"("ID_car_purpose") NOT VALID;


--
-- Name: Technical_data technical_data_drive_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Technical_data"
    ADD CONSTRAINT technical_data_drive_fk FOREIGN KEY ("ID_drive") REFERENCES public."Drive"("ID_drive") NOT VALID;


--
-- Name: Technical_data technical_data_gearbox_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Technical_data"
    ADD CONSTRAINT technical_data_gearbox_fk FOREIGN KEY ("ID_gearbox") REFERENCES public."Gearbox"("ID_gearbox") NOT VALID;


--
-- Name: Technical_data technical_data_motor_type_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Technical_data"
    ADD CONSTRAINT technical_data_motor_type_fk FOREIGN KEY ("ID_motor_type") REFERENCES public."Motor_type"("ID_motor_type") NOT VALID;


--
-- Name: Technical_data technical_data_suspension_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Technical_data"
    ADD CONSTRAINT technical_data_suspension_fk FOREIGN KEY ("ID_suspension") REFERENCES public."Suspension"("ID_suspension") NOT VALID;


--
-- PostgreSQL database dump complete
--

\unrestrict cn85ueZeGUu0nUgUO8luWNb9EQovKTm6jCyVg3lLRViV3rYPCv2Um2j1GXTJ3oW

