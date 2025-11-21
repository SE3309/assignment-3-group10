-- Created by: Martin Makaveev

CREATE TABLE `User` (
    user_id INT NOT NULL AUTO_INCREMENT,
    email VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Hashes are long
    username VARCHAR(50) NOT NULL,
    PRIMARY KEY (user_id),
    UNIQUE KEY (email)
);

DESCRIBE `User`;

CREATE TABLE Portfolio (
    portfolio_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    user_id INT NOT NULL,
    base_currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (portfolio_id),
    INDEX (user_id), -- For fast querying
    CONSTRAINT fk_user
        FOREIGN KEY (user_id)
        REFERENCES `User`(user_id)
        ON DELETE CASCADE -- Deletes portfolio if the user is deleted
        ON UPDATE CASCADE
);

DESCRIBE Portfolio;

CREATE TABLE Security (
    security_id INT NOT NULL AUTO_INCREMENT,
    ticker VARCHAR(20) NOT NULL,
    exchange VARCHAR(50) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    PRIMARY KEY (security_id),
    -- It ensures no two securities have the same ticker AND exchange
    UNIQUE KEY ak_ticker_exchange (ticker, exchange)
);

DESCRIBE Security;

CREATE TABLE Trade (
    trade_id INT NOT NULL AUTO_INCREMENT,
    portfolio_id INT NOT NULL,
    security_id INT NOT NULL,
    `side` ENUM('Buy', 'Sell') NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    price DECIMAL(18, 8) NOT NULL,
    settlement_currency VARCHAR(10) NOT NULL,
    fees DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    trade_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `source` VARCHAR(100),
    note TEXT,
    PRIMARY KEY (trade_id),
    INDEX (portfolio_id),
    INDEX (security_id),
    INDEX (trade_time),
    CONSTRAINT fk_trade_portfolio
        FOREIGN KEY (portfolio_id)
        REFERENCES Portfolio(portfolio_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_trade_security
        FOREIGN KEY (security_id)
        REFERENCES Security(security_id)
        ON DELETE RESTRICT
);

DESCRIBE Trade;

--
-- Table structure for table `Position`
-- (This table stores a daily snapshot of positions)
--
CREATE TABLE Position (
    portfolio_id INT NOT NULL,
    security_id INT NOT NULL,
    as_of_date DATE NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    avg_cost DECIMAL(18, 8) NOT NULL,
    PRIMARY KEY (portfolio_id, security_id, as_of_date),
    INDEX (security_id),
    CONSTRAINT fk_pos_portfolio
        FOREIGN KEY (portfolio_id)
        REFERENCES Portfolio(portfolio_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_pos_security
        FOREIGN KEY (security_id)
        REFERENCES Security(security_id)
        ON DELETE RESTRICT
);

DESCRIBE Position;

--
-- Table structure for table `PriceDaily`
-- (Stores daily closing price data for securities)
--
CREATE TABLE PriceDaily (
    security_id INT NOT NULL,
    price_date DATE NOT NULL,
    close_price DECIMAL(18, 8) NOT NULL,
    -- Composite Primary Key: Guarantees only one price entry
    -- per security, per day.
    PRIMARY KEY (security_id, price_date),
        CONSTRAINT fk_price_security
        FOREIGN KEY (security_id)
        REFERENCES Security(security_id)
        ON DELETE CASCADE
);

DESCRIBE PriceDaily;

--
-- Table structure for table `Dividend`
-- (Stores dividend payment information for securities)
--
CREATE TABLE Dividend (
    dividend_id INT NOT NULL AUTO_INCREMENT,
    security_id INT NOT NULL,
    ex_date DATE NOT NULL, -- "Ex-dividend date"
    pay_date DATE NOT NULL, -- Date the dividend is paid
    amount_per_share DECIMAL(18, 8) NOT NULL,
    dividend_currency VARCHAR(10) NOT NULL,
    PRIMARY KEY (dividend_id),
	-- prevent duplicates (security + ex_date should be unique)
    UNIQUE KEY (security_id, ex_date, amount_per_share),
    CONSTRAINT fk_div_security
        FOREIGN KEY (security_id)
        REFERENCES Security(security_id)
        ON DELETE CASCADE
);

DESCRIBE Dividend;

--
-- Table structure for table `PortfolioNAV`
-- (Stores the daily Net Asset Value (NAV) of a portfolio)
--
CREATE TABLE PortfolioNAV (
    portfolio_id INT NOT NULL,
    nav_date DATE NOT NULL,
    cash DECIMAL(18, 2) NOT NULL,
    net_value DECIMAL(18, 2) NOT NULL,
    -- Composite Primary Key: Guarantees only one NAV entry per portfolio, per day.
    PRIMARY KEY (portfolio_id, nav_date),
    CONSTRAINT fk_nav_portfolio
        FOREIGN KEY (portfolio_id)
        REFERENCES Portfolio(portfolio_id)
        ON DELETE CASCADE
);

DESCRIBE PortfolioNAV;

--
-- Table structure for table `PortfolioReturn`
-- (Stores the daily return percentage of a portfolio)
--
CREATE TABLE PortfolioReturn (
    portfolio_id INT NOT NULL,
    `date` DATE NOT NULL,
    daily_return DECIMAL(18, 8) NOT NULL, -- Stored as a decimal (e.g., 0.015 for 1.5%)

    PRIMARY KEY (portfolio_id, `date`),
        CONSTRAINT fk_return_portfolio
        FOREIGN KEY (portfolio_id)
        REFERENCES Portfolio(portfolio_id)
        ON DELETE CASCADE
);

DESCRIBE PortfolioReturn;

--
-- Table structure for table `Import`
-- (Tracks a single "import job" or file upload)
--
CREATE TABLE Import (
    import_id INT NOT NULL AUTO_INCREMENT,
    portfolio_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    `status` ENUM('Pending', 'Processing', 'Failed', 'Completed') NOT NULL DEFAULT 'Pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    error_message TEXT, -- To store any job-level errors
    PRIMARY KEY (import_id),
    INDEX (portfolio_id),
    CONSTRAINT fk_import_portfolio
        FOREIGN KEY (portfolio_id)
        REFERENCES Portfolio(portfolio_id)
        ON DELETE CASCADE
);

DESCRIBE Import;

--
-- Table structure for table `ImportRow`
-- (Tracks each individual row within an import job)
--
CREATE TABLE ImportRow (
    import_row_id INT NOT NULL AUTO_INCREMENT,
    import_id INT NOT NULL,
    -- Using JSON to store all "...raw fields..." from the file
    -- e.g., {"raw_ticker": "AAPL", "date": "2025-11-14", "quantity": "10"}
    raw_data JSON,
    -- The result of normalization. Nullable because it might fail.
    normalized_security_id INT,
    `status` ENUM('Pending', 'Processed', 'Failed') NOT NULL DEFAULT 'Pending',
    error_message TEXT, -- To store any row-level errors
    PRIMARY KEY (import_row_id),
    INDEX (import_id),
    INDEX (normalized_security_id),
    CONSTRAINT fk_row_import
        FOREIGN KEY (import_id)
        REFERENCES Import(import_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_row_security
        FOREIGN KEY (normalized_security_id)
        REFERENCES Security(security_id)
        ON DELETE SET NULL
);

DESCRIBE ImportRow;