# Used Car Sales Database Management System

## Overview

A comprehensive PostgreSQL-backed inventory and sales management system for used car dealerships, featuring a Windows Forms client application built with .NET 10. The system implements advanced database design patterns including domain-driven constraints, temporal auditing, materialized views, stored procedures, and event-driven triggers to enforce business logic and maintain data integrity across complex relational structures.

## System Architecture

### Technology Stack

**Backend:**
- **Database**: PostgreSQL 13.6
- **Database Driver**: Npgsql 10.0.1 (high-performance .NET data provider)
- **PL/pgSQL**: Stored procedures and trigger functions

**Frontend:**
- **.NET Framework**: .NET 10.0 Windows
- **UI Framework**: Windows Forms (WinForms)
- **Architecture Pattern**: Two-tier client-server architecture
- **Data Binding**: ADO.NET with DataTable/DataAdapter pattern

### Architectural Paradigm

**Two-Tier Architecture**: Direct database connectivity eliminates middleware layer, providing:
- **Advantages**: Reduced latency, simpler deployment, optimal for desktop applications
- **Trade-offs**: Tight coupling between presentation and data layers, limited scalability for web deployment

**Data Access Layer**: Raw ADO.NET implementation without ORM abstraction
- Direct SQL execution via `NpgsqlCommand`
- Parameterized queries for SQL injection prevention
- Connection-per-operation pattern with `using` blocks for resource management

## Database Schema Design

### Conceptual Model

The database implements a **normalized relational schema** (3NF+) with the following domain entities:

#### Core Entities

**1. Car (Inventory Management)**
```sql
CREATE TABLE public."Car" (
    "ID_car" integer PRIMARY KEY,
    "VIN" varchar(20) NOT NULL UNIQUE,
    "Availability" boolean NOT NULL,
    "Brand" varchar(50),
    "Model" varchar(50),
    "Mileage" public.mileage,           -- Custom domain with constraints
    "Year_of_issue" integer NOT NULL,
    "Price" numeric NOT NULL,
    "ID_technical_data" public."fk-not-null"
);
```

**Key Design Decisions**:
- **VIN (Vehicle Identification Number)**: Unique constraint ensures no duplicate vehicles
- **Availability Flag**: Boolean for rapid filtering (in-stock vs. sold)
- **Separate Technical Data**: Normalization via FK to `Technical_data` table
- **Custom Domain Types**: Encapsulates validation logic at database level

**2. Technical_data (Vehicle Specifications)**
```sql
CREATE TABLE public."Technical_data" (
    "ID_technical_data" integer PRIMARY KEY,
    "Engine_displacement" integer,
    "Color" public."technical-data",
    "ID_body_type" public."fk-not-null",
    "ID_motor_type" public."fk-not-null",
    "ID_car_purpose" public."fk-not-null",
    "ID_drive" public."fk-not-null",
    "ID_gearbox" public."fk-null",
    "ID_suspension" public."fk-null"
);
```

**Normalization Strategy**: Technical specifications decomposed into reference tables:
- `Body_type`: Sedan, SUV, Coupe, etc.
- `Motor_type`: Gasoline, Diesel, Electric, Hybrid
- `Gearbox`: Manual, Automatic, CVT
- `Suspension`: Independent, Dependent, Air
- `Drive`: FWD, RWD, AWD, 4WD
- `Car_purpose`: Passenger, Commercial, Off-road

**Benefits**:
- **Data Consistency**: Standardized terminology across inventory
- **Query Efficiency**: Indexed foreign keys enable fast joins
- **Maintainability**: Centralized reference data management

**3. Individual (Person Entity)**
```sql
CREATE TABLE public."Individual" (
    "ID_individual" integer PRIMARY KEY,
    "Second_name" public."name-or-passport" NOT NULL,
    "Name" public."name-or-passport" NOT NULL,
    "Patronymic" varchar(30),
    "City" public."phone-or-address",
    "Street" public."phone-or-address",
    "House" public."phone-or-address",
    "Flat" public."phone-or-address",
    "Passport_series" public."name-or-passport",
    "Passport_number" public."name-or-passport",
    "When_issued" date,
    "Phone" public."phone-or-address"
);
```

**Entity Hierarchy**: Individual serves as supertype for:
- **Buyer** (customers purchasing vehicles)
- **Manager** (sales staff)
- **Owner** (previous vehicle owners)

**Pattern**: Subtype entities contain only FK to Individual + role-specific attributes
```sql
CREATE TABLE public."Buyer" (
    "ID_buyer" integer PRIMARY KEY,
    "ID_individual" public."fk-not-null"
);
```

**Advantages**:
- **Single Source of Truth**: Contact information stored once
- **Polymorphism Support**: Same person can be buyer, manager, and owner
- **Audit Trail Consolidation**: Changes to Individual propagate to all roles

**4. Contract (Sales Transaction)**
```sql
CREATE TABLE public."Contract" (
    "ID_contract" integer PRIMARY KEY,
    "ID_buyer" public."fk-not-null",
    "ID_manager" public."fk-not-null",
    "ID_car" public."fk-not-null",
    "Date_contract" date NOT NULL,
    "Payment_type" varchar(50) NOT NULL,
    "Requisites" varchar(50)
);
```

**Relationship Semantics**:
- **Many-to-One**: Multiple contracts can reference same buyer/manager
- **One-to-One (conceptual)**: Each contract associated with single car sale
- **Temporal Tracking**: `Date_contract` enables time-series analysis

**5. Owner_car (Ownership History)**
```sql
CREATE TABLE public."Owner_car" (
    "ID_owner_car" integer PRIMARY KEY,
    "ID_owner" public."fk-not-null",
    "ID_car" public."fk-not-null",
    "Date_start" date NOT NULL,
    "Date_stop" date
);
```

**Temporal Modeling**: Tracks vehicle ownership timeline
- `Date_start`: Acquisition date
- `Date_stop`: NULL for current owner, date for past ownership
- Supports provenance queries (e.g., "Find all cars with 3+ previous owners")

### Custom Domain Types

PostgreSQL's domain feature enforces business rules at the database level:

**1. Mileage Domain**
```sql
CREATE DOMAIN public.mileage AS integer NOT NULL
    CONSTRAINT mileage_check CHECK (
        (VALUE > 0) AND (VALUE < 6000000)
    );
```
- **Range Validation**: 1 to 5,999,999 km
- **Rationale**: Prevents data entry errors (negative mileage, unrealistic values)
- **Earth Circumference**: ~40,000 km; constraint allows 150 circumnavigations

**2. Foreign Key Domains**
```sql
CREATE DOMAIN public."fk-not-null" AS integer NOT NULL;
CREATE DOMAIN public."fk-null" AS integer;
```
- **Self-Documenting**: FK column names explicitly indicate nullability
- **Type Safety**: Prevents accidental null assignments to required relationships
- **Consistency**: Uniform FK handling across schema

**3. String Domains**
```sql
CREATE DOMAIN public."name-or-passport" AS varchar(30) NOT NULL;
CREATE DOMAIN public."phone-or-address" AS varchar(30);
CREATE DOMAIN public."technical-data" AS varchar(30) NOT NULL;
```
- **Length Constraints**: Uniform string field sizing
- **Semantic Grouping**: Domain name indicates data category
- **Null Semantics**: Explicit nullable vs. required fields

### Indexing Strategy

**B-Tree Indexes on Foreign Keys**:
```sql
CREATE INDEX fki_car_technical_data_fk 
    ON public."Car" USING btree ("ID_technical_data");

CREATE INDEX fki_buyer_individual_fk 
    ON public."Buyer" USING btree ("ID_individual");
```

**Performance Impact**:
- **Join Acceleration**: Foreign key lookups optimized for nested loop joins
- **Referential Integrity**: Speeds up cascade operations
- **View Materialization**: Indexed FKs improve view refresh performance

**Index Selection Rationale**:
- B-tree chosen over hash due to range query support
- Covers equality and inequality predicates
- Optimal for OLTP workload (frequent point lookups and range scans)

## Database Views

### Analytical Views

**1. AVG_CAR_PRICE**
```sql
CREATE VIEW public."AVG_CAR_PRICE" AS
SELECT "Year_of_issue",
       avg("Price") AS "AVG_Price"
FROM public."Car"
GROUP BY "Year_of_issue"
HAVING (avg("Price") > 8000)
ORDER BY "Year_of_issue" DESC;
```

**Purpose**: Market analysis by vehicle age
**Use Case**: Pricing strategy for different model years
**Filter**: Excludes low-value segments (<$8,000) for focus on mainstream market

**2. FULL_CAR (Denormalized Vehicle Detail)**
```sql
CREATE VIEW public."FULL_CAR" AS
SELECT "Car"."Availability", "Car"."Brand", "Car"."Model", 
       "Car"."Mileage", "Car"."Price",
       "Technical_data"."Engine_displacement", "Technical_data"."Color",
       "Body_type"."Name_body", "Motor_type"."Name_motor",
       "Gearbox"."Type_gearbox", "Car_purpose"."Name_purpose",
       "Suspension"."Type_suspension", "Drive"."Type_drive"
FROM public."Car"
JOIN public."Technical_data" USING ("ID_technical_data")
JOIN public."Body_type" USING ("ID_body_type")
JOIN public."Motor_type" USING ("ID_motor_type")
JOIN public."Car_purpose" USING ("ID_car_purpose")
JOIN public."Drive" USING ("ID_drive")
JOIN public."Gearbox" USING ("ID_gearbox")
JOIN public."Suspension" USING ("ID_suspension");
```

**Design Pattern**: Denormalization via view
- **Performance**: Precomputed joins reduce query complexity
- **Simplicity**: Single-table abstraction for UI data binding
- **Flexibility**: Users can filter/search without understanding schema

**Query Optimization**:
- Joins executed once during view query
- Result set returned to application layer
- Suitable for read-heavy workloads

**3. CONTRACT_INFO (Sales Dashboard)**
```sql
CREATE VIEW public."CONTRACT_INFO" AS
-- Joins Contract, Buyer, Individual, Manager, Car tables
-- Returns: Customer details, Manager info, Car specs, Sale date
```

**Business Intelligence**: Comprehensive sales records
**Aggregation Potential**: Base for revenue reports, manager performance, customer analytics

### Operational Views

**CAR_MODERN**: Filters recent inventory (2019-2022 models)
**CAR_AVAYLABILITY**: Lists sold vehicles (availability = false)
**UNSOLD_CARS**: Available inventory (availability = true)

**Purpose**: Quick access to commonly-filtered datasets
**Benefit**: Reduces WHERE clause duplication across application queries

## Stored Procedures and Functions

### Data Manipulation Functions

**1. Insert_Car**
```sql
CREATE FUNCTION public."Insert_Car"(
    "VIN" varchar, "Availability" boolean, "Brand" varchar,
    "Model" varchar, "Mileage" integer, "Year_of_issue" integer,
    "Price" numeric, "ID_technical_data" integer
) RETURNS SETOF varchar;
```

**Encapsulation Benefits**:
- **Business Logic Centralization**: Validation rules in single location
- **API Stability**: Application code immune to schema changes
- **Transaction Atomicity**: Multi-table inserts wrapped in implicit transaction

**2. Insert_individual**
```sql
CREATE FUNCTION public."Insert_individual"(...) RETURNS integer;
```

**Return Value**: Newly generated `ID_individual`
**Use Case**: Application retrieves ID for subsequent role insertion (Buyer/Manager/Owner)
**Pattern**: Procedure coordination for multi-step workflows

**3. Update_Car** (Two Overloads)
```sql
-- Overload 1: Update by VIN (unique identifier)
CREATE FUNCTION public."Update_Car"(
    "pVIN" varchar, ...
) RETURNS varchar;

-- Overload 2: Update by ID_car (primary key)
CREATE FUNCTION public."Update_Car"(
    "pVIN" varchar, ..., "pID_car" integer
) RETURNS varchar;
```

**Function Overloading**: PostgreSQL supports same name, different signatures
**Rationale**: Flexibility in update semantics (natural key vs. surrogate key)

**4. Update_price**
```sql
CREATE FUNCTION public."Update_price"(
    car_no integer, factor double precision
) RETURNS numeric;
```

**Bulk Pricing Operations**: Multiply price by factor (e.g., 1.1 for 10% increase)
**Return**: New price after update
**Transaction Safety**: Single atomic operation

**5. Delete_contract**
```sql
CREATE FUNCTION public."Delete_contract"(
    contract_no integer
) RETURNS varchar;
```

**Soft Delete Pattern**: Returns status message rather than boolean
**Benefit**: Application can display user-friendly confirmation

### Query Functions

**1. Available_cars_brands**
```sql
CREATE FUNCTION public."Available_cars_brands"(brand varchar)
RETURNS TABLE(
    "Model" varchar, "Mileage" mileage, "Price" numeric,
    "Engine_displacement" integer, "Color" technical-data,
    -- ... additional columns
);
```

**Parameterized View**: Brand-specific inventory lookup
**Exception Handling**: Raises error if brand not found
```sql
IF NOT FOUND THEN
    RAISE EXCEPTION 'Не удалось найти автомобиль с маркой %', $1;
END IF;
```

**2. Finding_the_car_by_price**
```sql
CREATE FUNCTION public."Finding_the_car_by_price"(
    price_input1 numeric, price_input2 numeric
) RETURNS TABLE(...);
```

**Range Query**: Returns all cars within price bounds
**Performance**: Leverages index on `Price` column if present

**3. Contract_information_by_year**
```sql
CREATE FUNCTION public."Contract_information_by_year"(
    contract_date date
) RETURNS TABLE(...);
```

**Temporal Filtering**: Contracts after specified date
**Reporting Use Case**: Year-over-year sales analysis

**4. Number_of_owners**
```sql
CREATE FUNCTION public."Number_of_owners"(
    price_input1 numeric, price_input2 numeric
) RETURNS TABLE("Price" numeric, "Count" integer);
```

**Aggregate Function**: Counts previous owners per vehicle in price range
**Business Intelligence**: Correlate ownership history with pricing

## Trigger System

### Audit Trail Implementation

**1. Car Audit Logging**
```sql
CREATE FUNCTION public.log_car() RETURNS trigger AS $$
DECLARE
    invitation varchar;
    available varchar;
    final_mes varchar;
BEGIN
    IF TG_OP = 'INSERT' THEN
        available := CASE WHEN NEW."Availability" THEN 'available' 
                          ELSE 'not available' END;
        final_mes := 'Add new car and this car is ' || available;
        INSERT INTO car_audits 
            (description, changed, id_car)
        VALUES (final_mes, now(), NEW."ID_car");
    ELSIF TG_OP = 'UPDATE' THEN
        -- Similar logic for updates
    END IF;
    RETURN NEW;
END $$;
```

**Trigger Registration**:
```sql
CREATE TRIGGER car_available 
AFTER INSERT OR UPDATE ON public."Car" 
FOR EACH ROW EXECUTE FUNCTION public.log_car();
```

**Audit Table Schema**:
```sql
CREATE TABLE public.car_audits (
    audit_id serial PRIMARY KEY,
    description varchar,
    changed timestamp,
    id_car integer
);
```

**Audit Capabilities**:
- **Event Tracking**: Insert/update operations timestamped
- **State Logging**: Availability status recorded
- **Non-Intrusive**: Triggers fire transparently

**2. Temporal Audit (Full Car History)**
```sql
CREATE FUNCTION public.log_insert() RETURNS trigger AS $$
BEGIN
    EXECUTE format('INSERT INTO full_car_audits SELECT ($1).*, 
                   current_timestamp, NULL')
    USING NEW;
    RETURN NEW;
END $$;

CREATE FUNCTION public.log_delete() RETURNS trigger AS $$
BEGIN
    EXECUTE format('UPDATE full_car_audits SET end_date = current_timestamp 
                   WHERE "ID_car"=$1 AND end_date IS NULL')
    USING OLD."ID_car";
    RETURN OLD;
END $$;
```

**Temporal Auditing Pattern**:
```sql
CREATE TABLE public.full_car_audits (
    -- All columns from Car table
    start_date timestamp,
    end_date timestamp
);
```

**Versioning Semantics**:
- `start_date`: Record creation timestamp
- `end_date`: NULL for current version, timestamp for historical
- **Bitemporal Tracking**: Captures state at any point in time

**Query Examples**:
```sql
-- Current state (as-is)
SELECT * FROM full_car_audits WHERE end_date IS NULL;

-- Historical state (as-was)
SELECT * FROM full_car_audits 
WHERE start_date <= '2024-01-01' 
  AND (end_date IS NULL OR end_date > '2024-01-01');
```

**3. Individual Surname Changes**
```sql
CREATE FUNCTION public.log_sername_changes() RETURNS trigger AS $$
BEGIN
    IF NEW."Second_name" <> OLD."Second_name" THEN
        INSERT INTO Individual_audits 
            ("sername", "changed_on", "id_individual")
        VALUES (OLD."Second_name", now(), OLD."ID_individual");
    END IF;
    RETURN NEW;
END $$;
```

**Selective Auditing**: Only tracks surname modifications
**Use Case**: Legal compliance (name change documentation), customer service history

**4. Motor Type Logging**
```sql
CREATE FUNCTION public.logs_motor() RETURNS trigger AS $$
-- Logs additions and modifications to motor types
$$;
```

**Reference Data Auditing**: Tracks changes to classification tables
**Rationale**: Motor type affects regulatory compliance, warranty terms

### Data Integrity Triggers

**1. Prevent Car Deletion with Dependencies**
```sql
CREATE FUNCTION public.t_delete_car() RETURNS trigger AS $$
BEGIN
    IF (EXISTS (SELECT "Car"."ID_car" FROM "Car"
                JOIN "Contract" USING ("ID_car")
                WHERE OLD."ID_car" = "Car"."ID_car")
    AND EXISTS (SELECT "Car"."ID_car" FROM "Car"
                JOIN "Owner_car" USING ("ID_car")
                WHERE OLD."ID_car" = "Car"."ID_car"))
    THEN
        RAISE EXCEPTION 'Такой ID используется';
    END IF;
    RETURN OLD;
END $$;
```

**Referential Integrity Enforcement**: 
- Prevents deletion if car has contracts or ownership records
- Stronger than CASCADE (which would delete dependent rows)
- Implements "soft delete" business rule (mark as unavailable instead)

**2. Individual Data Validation**
```sql
CREATE FUNCTION public.t_insert_individual() RETURNS trigger AS $$
DECLARE 
    low_date date := '1900-01-01';
    high_date date := '2030-01-01';
BEGIN
    IF NEW."Second_name" IS NULL THEN
        RAISE EXCEPTION 'Поле "фамилия" не может быть пустым!';
    END IF;
    IF NEW."Name" IS NULL THEN
        RAISE EXCEPTION 'Поле "имя" не может быть пустым!';
    END IF;
    IF ((NEW."When_issued" < low_date) OR 
        (NEW."When_issued" > high_date)) THEN
        RAISE EXCEPTION 'Дата рождения % должна быть реальной!', 
                        NEW."When_issued";
    END IF;
    RETURN NEW;
END $$;
```

**Validation Rules**:
- **Name Fields**: Mandatory (not null)
- **Date Sanity Check**: Passport issue date within reasonable range
- **Error Messages**: Localized Russian text for user feedback

**3. View Update Trigger**
```sql
CREATE FUNCTION public."t_update_MANAGER_INFO"() RETURNS trigger AS $$
BEGIN
    UPDATE "Individual"
    SET "Second_name" = NEW."Managers_sername",
        "Name" = NEW."Managers_name",
        "Patronymic" = NEW."Managers_patronymic",
        "Phone" = NEW."Managers_phone"
    WHERE "ID_individual" = (
        SELECT "ID_individual" FROM "Manager" 
        WHERE "ID_manager" = OLD."ID_manager"
    );
    RETURN NEW;
END $$;
```

**Updatable View Pattern**: 
- `MANAGER_INFO` is a read-only view (join of Manager + Individual)
- Trigger makes it writable by routing updates to base tables
- **Abstraction**: Application treats view as regular table

## Windows Forms Application

### Architecture Overview

**Connection Management**:
```csharp
private string connString = 
    "Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=db_cars_sale";
```

**Connection Pattern**: Connection-per-operation
- Opens connection, executes command, disposes via `using` block
- **Trade-off**: Higher latency vs. simpler concurrency model
- **Suitability**: Desktop application with moderate transaction volume

### Data Access Patterns

**1. DataGridView Binding**
```csharp
private void FillGrid(string sql, DataGridView grid)
{
    using (var conn = new NpgsqlConnection(connString))
    {
        NpgsqlDataAdapter da = new NpgsqlDataAdapter(sql, conn);
        DataTable dt = new DataTable();
        da.Fill(dt);
        grid.DataSource = dt;
    }
}
```

**DataAdapter Pattern**:
- `NpgsqlDataAdapter`: Bridges between database and `DataTable`
- `DataTable`: In-memory representation of query result
- **Data Binding**: `DataGridView.DataSource` automatically renders rows/columns

**Advantages**:
- No manual row iteration
- Built-in sorting, filtering in UI
- Change tracking for updates

**2. Parameterized Commands (SQL Injection Prevention)**
```csharp
private void button1_Click(object sender, EventArgs e)
{
    using (var conn = new NpgsqlConnection(connString))
    {
        conn.Open();
        using (var cmd = new NpgsqlCommand(
            "SELECT \"Insert_Car\"(@vin, @avail, @brand, @model, @mileage, @year, @price, @status)", 
            conn))
        {
            cmd.Parameters.AddWithValue("vin", textBox1.Text);
            cmd.Parameters.AddWithValue("avail", comboBox1.SelectedItem?.ToString() == "Да");
            cmd.Parameters.AddWithValue("brand", textBox4.Text);
            // ... additional parameters
            cmd.ExecuteNonQuery();
        }
    }
    RefreshAllGrids();
}
```

**Security Measures**:
- **Parameterized Queries**: Values passed separately from SQL text
- **Type Safety**: `AddWithValue` performs type conversion
- **No String Concatenation**: Immune to SQL injection

**3. Stored Procedure Invocation**
```csharp
string sql = @"SELECT ""Insert_individual""(
    @p1::""name-or-passport"", 
    @p2::""name-or-passport"", 
    @p3::varchar, 
    // ... additional parameters
)";
using (var cmd = new NpgsqlCommand(sql, conn))
{
    cmd.Parameters.Add("p1", NpgsqlTypes.NpgsqlDbType.Varchar, 30).Value = textBox8.Text;
    // ... parameter configuration
    newProdID = Convert.ToInt32(cmd.ExecuteScalar());
}
```

**Type Casting**: `::""name-or-passport""` explicitly casts to custom domain
**Return Value Handling**: `ExecuteScalar()` retrieves function result
**Multi-Step Transaction**: Returned ID used in subsequent INSERT

**4. Dynamic SQL Construction**
```csharp
private void button5_Click(object sender, EventArgs e)
{
    string sortDir = comboBox5.SelectedItem.ToString() == "По возрастанию" ? "ASC" : "DESC";
    string column = "Customers_sername";
    if (comboBox3.SelectedIndex == 1) column = "Customers_name";
    // ... column selection logic
    string sql = $"SELECT * FROM \"CONTRACT_INFO\" ORDER BY \"{column}\" {sortDir}";
    FillGrid(sql, dataGridView2);
}
```

**Dynamic Sorting**: User-selected column and direction
**Safety Consideration**: Column names validated via whitelist (no user input)
**Alternative**: Could use parameterized `ORDER BY` with CASE statements

**5. LIKE Pattern Search**
```csharp
private void button7_Click(object sender, EventArgs e)
{
    string col = GetColumnName(comboBox6.SelectedItem.ToString());
    string sql = $"SELECT * FROM \"CONTRACT_INFO\" WHERE \"{col}\"::text LIKE @search";
    NpgsqlDataAdapter da = new NpgsqlDataAdapter(sql, conn);
    da.SelectCommand.Parameters.AddWithValue("search", textBox19.Text + "%");
    // ... execute query
}
```

**Prefix Matching**: Appends `%` wildcard for "starts with" search
**Type Casting**: `::text` ensures all columns converted to string for LIKE
**Index Optimization**: Prefix searches can use B-tree indexes

### UI/UX Features

**1. Master-Detail Binding**
```csharp
private void dataGridView1_RowEnter(object sender, DataGridViewCellEventArgs e)
{
    var row = dataGridView1.Rows[e.RowIndex];
    textBox1.Text = row.Cells["vin"].Value?.ToString();
    textBox4.Text = row.Cells["brand"].Value?.ToString();
    // ... populate form fields from selected row
    currenRowID = Convert.ToInt32(row.Cells["ID_car"].Value);
}
```

**Pattern**: Clicking grid row populates edit form
**Update Flow**: User modifies fields → clicks Update → `button3_Click` executes
**State Management**: `currenRowID` tracks selected record

**2. Multi-View Dashboard**
```csharp
private void RefreshAllGrids()
{
    FillGrid("SELECT * FROM \"FULL_CAR\"", dataGridView6);
    FillGrid("SELECT * FROM \"OWNERS_INDIVIDUAL_INFO\"", dataGridView5);
    FillGrid("SELECT * FROM \"CUSTOMERS_INDIVIDUAL_INFO\"", dataGridView4);
    FillGrid("SELECT * FROM \"MANAGERS_INDIVIDUAL_INFO\"", dataGridView3);
    FillGrid("SELECT * FROM \"CONTRACT_INFO\"", dataGridView2);
    FillGrid("SELECT * FROM \"CAR_MODERN\"", dataGridView1);
}
```

**Refresh Strategy**: Re-query all views after data modification
**Consistency**: Ensures UI reflects database state
**Performance**: Acceptable for desktop with moderate data volume

**3. Filter Controls**
```csharp
// Price range filter
private void button8_Click(object sender, EventArgs e)
{
    string sql = "SELECT * FROM \"FULL_CAR\" WHERE \"Price\" > @min AND \"Price\" < @max";
    // ... execute with parameters from textBox21, textBox20
}
```

**Dynamic Filtering**: User-specified criteria applied to views
**Composability**: Multiple filters can be combined

## Advanced Database Techniques

### 1. Phone Number Formatting
```sql
CREATE FUNCTION public."Phone_editing"(INOUT phone varchar) 
RETURNS varchar AS $$
-- Standardizes phone number format
$$;
```

**Data Cleaning**: Normalizes user input (removes spaces, formats consistently)
**INOUT Parameter**: Modifies parameter in-place, returns updated value

### 2. Aggregate Reporting
```sql
CREATE FUNCTION public."Sum_sales_of_brand"(brand varchar)
RETURNS TABLE("Model" varchar, "Count" bigint, "Sum" numeric) AS $$
-- Returns: Model, total units sold, total revenue
$$;
```

**Business Metrics**: Brand-level sales analysis
**Grouping**: Aggregates by model within brand
**Use Case**: Revenue reports, inventory planning

### 3. Dynamic Search
```sql
CREATE FUNCTION public."Finding_the_buyer"(
    search_column varchar, substr varchar
) RETURNS TABLE(...) AS $$
-- Searches buyer by any column (surname, name, city)
$$;
```

**Flexible Querying**: Column name passed as parameter
**Implementation**: Uses dynamic SQL with `EXECUTE` statement
**Security**: Column name validated against whitelist

## Performance Considerations

### Query Optimization

**1. View Materialization**
- Views are **not materialized** by default in this schema
- Queries recompute joins on every execution
- **Optimization Opportunity**: `CREATE MATERIALIZED VIEW` for frequently-accessed aggregates

**2. Index Coverage**
- Foreign keys indexed for join performance
- **Missing**: No indexes on `Price`, `Brand`, `Model` (common filter columns)
- **Recommendation**: Add indexes based on query patterns in application

**3. Connection Pooling**
- Current implementation: Connection-per-operation
- **Optimization**: Npgsql supports connection pooling via connection string parameter
```csharp
"Host=localhost;...;Pooling=true;MinPoolSize=5;MaxPoolSize=20"
```

### Scalability Bottlenecks

**1. Two-Tier Architecture**
- All business logic in database (stored procedures)
- Application merely presents data
- **Limitation**: Difficult to scale horizontally (stateful database connections)

**2. Synchronous Operations**
- UI blocks during database operations
- **User Experience**: Application appears frozen on slow queries
- **Improvement**: Asynchronous data access with `async/await`

```csharp
// Proposed improvement
private async Task FillGridAsync(string sql, DataGridView grid)
{
    using (var conn = new NpgsqlConnection(connString))
    {
        await conn.OpenAsync();
        NpgsqlDataAdapter da = new NpgsqlDataAdapter(sql, conn);
        DataTable dt = new DataTable();
        await Task.Run(() => da.Fill(dt));
        grid.DataSource = dt;
    }
}
```

**3. Full-Table Refreshes**
- `RefreshAllGrids()` re-queries all 6 views
- **Optimization**: Refresh only affected views after mutations

## Security Analysis

### Strengths

**1. Parameterized Queries**
- All user inputs passed as parameters
- **Result**: SQL injection protection

**2. Database-Level Validation**
- Domain constraints, triggers, stored procedures
- **Defense in Depth**: Business rules enforced even if application bypassed

**3. Type Safety**
- Custom domains prevent invalid data
- Foreign key constraints maintain referential integrity

### Vulnerabilities

**1. Hardcoded Credentials**
```csharp
private string connString = "...Password=postgres...";
```
- **Risk**: Credentials visible in source code
- **Mitigation**: Use configuration files, environment variables, or secure credential stores

**2. No Authentication/Authorization**
- Application assumes direct database access
- **Missing**: User roles, row-level security (RLS)
- **Recommendation**: Implement application-level user authentication

**3. No Encryption**
- Connection string uses unencrypted protocol
- **Risk**: Credentials, data transmitted in plaintext
- **Mitigation**: Enable SSL/TLS in PostgreSQL, update connection string

```csharp
"...;SSL Mode=Require;Trust Server Certificate=true"
```

**4. No Input Sanitization**
- Relies entirely on database to reject invalid data
- **Risk**: Poor error messages for users
- **Improvement**: Client-side validation before database submission

## Deployment Architecture

### Prerequisites

**Server Environment**:
- PostgreSQL 13.6+
- Network connectivity (default port 5432)
- Database: `db_cars_sale`
- User: `postgres` with full privileges

**Client Environment**:
- Windows 10/11 (64-bit)
- .NET 10.0 Runtime
- Network access to PostgreSQL server

### Setup Instructions

**1. Database Initialization**
```bash
# Create database
createdb -U postgres db_cars_sale

# Import schema and data
psql -U postgres -d db_cars_sale -f Used-Car-Sales-DB.sql
```

**2. Application Configuration**
```csharp
// Update connection string in MainForm.cs
private string connString = "Host=YOUR_HOST;Port=5432;Username=YOUR_USER;Password=YOUR_PASSWORD;Database=db_cars_sale";
```

**3. Build Application**
```bash
# Using .NET CLI
dotnet build Used-Car-Sales.csproj -c Release

# Output: bin/Release/net10.0-windows/Used-Car-Sales.exe
```

**4. Deployment Options**

**Option A: Direct Deployment**
- Copy `bin/Release` folder to target machine
- Install .NET 10.0 Runtime if not present
- Run `Used-Car-Sales.exe`

**Option B: ClickOnce Deployment**
```xml
<Project>
  <PropertyGroup>
    <PublishUrl>\\network-share\UsedCarSales\</PublishUrl>
    <InstallUrl>\\network-share\UsedCarSales\</InstallUrl>
  </PropertyGroup>
</Project>
```
- Users install from network share
- Automatic updates on application restart

## Testing Strategy

### Database Testing

**1. Unit Tests for Stored Procedures**
```sql
-- Test Insert_Car function
DO $$
DECLARE
    test_vin varchar := 'TEST123456789';
    result varchar;
BEGIN
    SELECT "Insert_Car"(
        test_vin, true, 'Toyota', 'Camry', 50000, 2020, 15000, 1
    ) INTO result;
    
    ASSERT result = 'Success', 'Insert failed';
    
    -- Cleanup
    DELETE FROM "Car" WHERE "VIN" = test_vin;
END $$;
```

**2. Trigger Verification**
```sql
-- Verify audit logging
INSERT INTO "Car" VALUES (...);
SELECT * FROM car_audits WHERE id_car = CURRVAL('car_id_seq');
-- Assert audit record exists
```

**3. Constraint Testing**
```sql
-- Test mileage constraint
DO $$
BEGIN
    INSERT INTO "Car" ("Mileage", ...) VALUES (7000000, ...);
    RAISE EXCEPTION 'Should have failed due to mileage constraint';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'Constraint working correctly';
END $$;
```

### Application Testing

**Manual Test Cases**:
1. **CRUD Operations**: Insert, update, delete cars
2. **View Filtering**: Apply price range, brand filters
3. **Search Functionality**: Test LIKE patterns
4. **Master-Detail Sync**: Verify form population on row selection
5. **Error Handling**: Attempt invalid inputs, observe error messages

**Automated UI Testing** (proposed):
```csharp
[Test]
public void TestCarInsert()
{
    var form = new MainForm();
    form.textBox1.Text = "VIN123";
    form.textBox4.Text = "Honda";
    // ... set all fields
    form.button1.PerformClick();
    
    // Assert: New row appears in dataGridView1
    Assert.IsTrue(form.dataGridView1.Rows.Count > 0);
}
```

## Known Limitations

1. **Single-User Concurrency**: No optimistic/pessimistic locking for concurrent edits
2. **No Soft Delete**: Car deletion is hard delete (mitigated by dependency checks)
3. **Limited Reporting**: No built-in analytics dashboard, chart visualization
4. **Manual Refresh**: User must trigger refresh after external changes
5. **No Data Export**: Missing CSV/Excel export functionality
6. **Hardcoded Locale**: Russian language strings in database, no internationalization

## Future Enhancements

### Technical Improvements

**1. Migrate to Three-Tier Architecture**
- **Web API Layer**: ASP.NET Core RESTful API
- **Benefits**: Multi-platform client support (web, mobile), horizontal scalability

**2. Implement Caching**
- **Redis Integration**: Cache frequently-accessed views
- **Invalidation Strategy**: Trigger-based cache invalidation

**3. Add Full-Text Search**
- **PostgreSQL Extension**: Enable `pg_trgm` for fuzzy matching
```sql
CREATE INDEX idx_car_brand_gin ON "Car" 
USING gin(to_tsvector('english', "Brand"));
```

**4. Reporting Module**
- **Crystal Reports** or **DevExpress**: Rich report designer
- **Scheduled Reports**: Automated email delivery

**5. Real-Time Updates**
- **SignalR**: Push database changes to connected clients
- **Event-Driven**: Triggers publish messages to message queue

### Business Features

**1. Inventory Forecasting**
- Machine learning model predicts optimal stock levels
- Integrates with `AVG_CAR_PRICE`, sales velocity data

**2. Customer Relationship Management (CRM)**
- Track customer interactions, preferences
- Automated follow-up reminders for buyers

**3. Financing Integration**
- Calculate loan payments, interest rates
- Integrate with third-party lending APIs

**4. Photo Management**
- Store vehicle images in blob storage
- Link via `Car` table foreign key

**5. Auction/Bidding System**
- Allow customers to place bids on vehicles
- Trigger-based price updates, bid notifications

## Database Diagram

```
┌─────────────┐         ┌──────────────────┐         ┌──────────────┐
│    Car      │────────▶│ Technical_data   │────────▶│  Body_type   │
│             │         │                  │         │  Motor_type  │
│ ID_car (PK) │         │ ID_technical (PK)│         │  Drive       │
│ VIN (UK)    │         │ Engine_displ     │         │  Gearbox     │
│ Availability│         │ Color            │         │  Suspension  │
│ Mileage     │         └──────────────────┘         │  Car_purpose │
│ Price       │                                      └──────────────┘
└──────┬──────┘
       │
       ├──────▶ Owner_car ────▶ Owner ────▶ Individual
       │                                        │
       │                                        ├──────▶ Buyer
       └──────▶ Contract ────▶ Buyer           │
                    │                           └──────▶ Manager
                    └──────▶ Manager
```

## Contributing

This system demonstrates:
- **Database Design**: Normalization, domain-driven design, referential integrity
- **PL/pgSQL Programming**: Stored procedures, triggers, exception handling
- **ADO.NET**: Parameterized queries, DataAdapter pattern, transaction management
- **Windows Forms**: Data binding, event-driven programming, user input validation

Ideal for educational purposes or as foundation for production dealership management system.

## License

This project is licensed under the MIT License – see the LICENSE file for details.

## Author

This implementation prioritizes pedagogical clarity in database design and desktop application patterns. Production deployments should address security hardening, horizontal scalability, and regulatory compliance requirements.
