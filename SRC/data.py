import csv
import json
import random
import string
from datetime import datetime, timedelta, date
from pathlib import Path


NUM_USERS = 60
NUM_SECURITIES = 300
NUM_PORTFOLIOS = 150


NUM_TRADES = 8000 # First big table
NUM_POSITIONS = 2000
NUM_PRICES = 6000 # Second big table
NUM_DIVIDENDS = 250
NUM_NAV_ROWS = 2000
NUM_RETURN_ROWS = 2000
NUM_IMPORTS = 80
NUM_IMPORT_ROWS = 9000 # Third big table


OUTPUT_DIR = Path(".") # current folder


random.seed(42)




def random_date(start: date, end: date) -> date:
    """Random date between start and end inclusive."""
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))




def random_datetime(start: datetime, end: datetime) -> datetime:
    delta = end - start
    seconds = random.randint(0, int(delta.total_seconds()))
    return start + timedelta(seconds=seconds)




def random_hash(length=40):
    chars = string.ascii_letters + string.digits
    return "hash_" + "".join(random.choice(chars) for _ in range(length))




# 1) USER TABLE
users = []
for uid in range(1, NUM_USERS + 1):
    email = f"user{uid}@example.com"
    username = f"user_{uid:03d}"
    password_hash = random_hash(32)
    users.append((uid, email, password_hash, username))


with (OUTPUT_DIR / "User.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["user_id", "email", "password_hash", "username"])
    writer.writerows(users)


print(f"Wrote {len(users)} users")




# 2) SECURITY TABLE
exchanges = ["NYSE", "NASDAQ", "TSX"]
currencies = ["USD", "CAD", "EUR"]


securities = []
for sid in range(1, NUM_SECURITIES + 1):
    ticker = f"STK{sid:04d}"
    exchange = random.choice(exchanges)
    name = f"Company {ticker}"
    currency = random.choice(currencies)
    securities.append((sid, ticker, exchange, name, currency))


with (OUTPUT_DIR / "Security.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["security_id", "ticker", "exchange", "name", "currency"])
    writer.writerows(securities)


print(f"Wrote {len(securities)} securities")




# 3) PORTFOLIO TABLE
start_dt = datetime(2020, 1, 1)
end_dt = datetime(2024, 12, 31)


portfolios = []
for pid in range(1, NUM_PORTFOLIOS + 1):
    name = f"Portfolio {pid:03d}"
    user_id = random.randint(1, NUM_USERS)
    base_currency = random.choice(currencies)
    creation_date = random_datetime(start_dt, end_dt).strftime("%Y-%m-%d %H:%M:%S")
    portfolios.append((pid, name, user_id, base_currency, creation_date))


with (OUTPUT_DIR / "Portfolio.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["portfolio_id", "name", "user_id", "base_currency", "creation_date"])
    writer.writerows(portfolios)


print(f"Wrote {len(portfolios)} portfolios")




# 4) TRADE TABLE (big)
sides = ["Buy", "Sell"]
sources = ["Manual", "Import", "API"]


trades = []
for tid in range(1, NUM_TRADES + 1):
    portfolio_id = random.randint(1, NUM_PORTFOLIOS)
    security_id = random.randint(1, NUM_SECURITIES)
    side = random.choice(sides)
    quantity = round(random.uniform(1, 1000), 4)
    price = round(random.uniform(5, 500), 4)
    settlement_currency = random.choice(currencies)
    fees = round(random.uniform(0, 25), 2)
    trade_time = random_datetime(start_dt, end_dt).strftime("%Y-%m-%d %H:%M:%S")
    source = random.choice(sources)
    note = ""
    trades.append(
        (
            tid,
            portfolio_id,
            security_id,
            side,
            f"{quantity:.4f}",
            f"{price:.4f}",
            settlement_currency,
            f"{fees:.2f}",
            trade_time,
            source,
            note,
        )
    )


with (OUTPUT_DIR / "Trade.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(
        [
            "trade_id",
            "portfolio_id",
            "security_id",
            "side",
            "quantity",
            "price",
            "settlement_currency",
            "fees",
            "trade_time",
            "source",
            "note",
        ]
    )
    writer.writerows(trades)


print(f"Wrote {len(trades)} trades")




# 5) POSITION TABLE
positions = []
seen_pos_keys = set()


while len(positions) < NUM_POSITIONS:
    portfolio_id = random.randint(1, NUM_PORTFOLIOS)
    security_id = random.randint(1, NUM_SECURITIES)
    as_of_date = random_date(date(2022, 1, 1), date(2024, 12, 31)).strftime("%Y-%m-%d")
    key = (portfolio_id, security_id, as_of_date)
    if key in seen_pos_keys:
        continue
    seen_pos_keys.add(key)
    quantity = round(random.uniform(1, 2000), 4)
    avg_cost = round(random.uniform(5, 500), 4)
    positions.append(
        (portfolio_id, security_id, as_of_date, f"{quantity:.4f}", f"{avg_cost:.4f}")
    )


with (OUTPUT_DIR / "Position.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["portfolio_id", "security_id", "as_of_date", "quantity", "avg_cost"])
    writer.writerows(positions)


print(f"Wrote {len(positions)} positions")




# 6) PRICEDAILY TABLE
prices = []
seen_price_keys = set()


while len(prices) < NUM_PRICES:
    security_id = random.randint(1, NUM_SECURITIES)
    price_date = random_date(date(2022, 1, 1), date(2024, 12, 31)).strftime("%Y-%m-%d")
    key = (security_id, price_date)
    if key in seen_price_keys:
        continue
    seen_price_keys.add(key)
    close_price = round(random.uniform(5, 500), 4)
    prices.append((security_id, price_date, f"{close_price:.4f}"))


with (OUTPUT_DIR / "PriceDaily.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["security_id", "price_date", "close_price"])
    writer.writerows(prices)


print(f"Wrote {len(prices)} daily prices")




# 7) DIVIDEND TABLE
dividends = []
for did in range(1, NUM_DIVIDENDS + 1):
    security_id = random.randint(1, NUM_SECURITIES)
    ex_dt = random_date(date(2022, 1, 1), date(2024, 12, 31))
    pay_dt = ex_dt + timedelta(days=random.randint(7, 60))
    amount = round(random.uniform(0.05, 3.00), 4)
    div_currency = random.choice(currencies)
    dividends.append(
        (
            did,
            security_id,
            ex_dt.strftime("%Y-%m-%d"),
            pay_dt.strftime("%Y-%m-%d"),
            f"{amount:.4f}",
            div_currency,
        )
    )


with (OUTPUT_DIR / "Dividend.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(
        ["dividend_id", "security_id", "ex_date", "pay_date", "amount_per_share", "dividend_currency"]
    )
    writer.writerows(dividends)


print(f"Wrote {len(dividends)} dividends")




# 8) PORTFOLIONAV TABLE
nav_rows = []
seen_nav_keys = set()


while len(nav_rows) < NUM_NAV_ROWS:
    portfolio_id = random.randint(1, NUM_PORTFOLIOS)
    nav_date = random_date(date(2022, 1, 1), date(2024, 12, 31)).strftime("%Y-%m-%d")
    key = (portfolio_id, nav_date)
    if key in seen_nav_keys:
        continue
    seen_nav_keys.add(key)
    cash = round(random.uniform(0, 1_000_000), 2)
    net_value = round(cash + random.uniform(-200_000, 2_000_000), 2)
    nav_rows.append((portfolio_id, nav_date, f"{cash:.2f}", f"{net_value:.2f}"))


with (OUTPUT_DIR / "PortfolioNAV.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["portfolio_id", "nav_date", "cash", "net_value"])
    writer.writerows(nav_rows)


print(f"Wrote {len(nav_rows)} portfolio NAV rows")




# 9) PORTFOLIORETURN TABLE
return_rows = []
seen_ret_keys = set()


while len(return_rows) < NUM_RETURN_ROWS:
    portfolio_id = random.randint(1, NUM_PORTFOLIOS)
    ret_date = random_date(date(2022, 1, 1), date(2024, 12, 31)).strftime("%Y-%m-%d")
    key = (portfolio_id, ret_date)
    if key in seen_ret_keys:
        continue
    seen_ret_keys.add(key)
    daily_return = round(random.uniform(-0.05, 0.05), 6)  # -5% to +5%
    return_rows.append((portfolio_id, ret_date, f"{daily_return:.6f}"))


with (OUTPUT_DIR / "PortfolioReturn.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["portfolio_id", "date", "daily_return"])
    writer.writerows(return_rows)


print(f"Wrote {len(return_rows)} portfolio return rows")




# 10) IMPORT TABLE
statuses_import = ["Pending", "Processing", "Failed", "Completed"]


imports = []
for iid in range(1, NUM_IMPORTS + 1):
    portfolio_id = random.randint(1, NUM_PORTFOLIOS)
    filename = f"import_{iid:03d}.csv"
    status = random.choice(statuses_import)
    created_at = random_datetime(start_dt, end_dt).strftime("%Y-%m-%d %H:%M:%S")
    error_message = ""
    if status == "Failed":
        error_message = "Random failure while processing file."
    imports.append((iid, portfolio_id, filename, status, created_at, error_message))


with (OUTPUT_DIR / "Import.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(
        ["import_id", "portfolio_id", "filename", "status", "created_at", "error_message"]
    )
    writer.writerows(imports)


print(f"Wrote {len(imports)} imports")




# 11) IMPORTROW TABLE (big)
statuses_row = ["Pending", "Processed", "Failed"]


import_rows = []
for rid in range(1, NUM_IMPORT_ROWS + 1):
    import_id = random.randint(1, NUM_IMPORTS)
    # sometimes we can't normalize the security
    # Roughly 20% of the rows will not be accepted upon import in SQL, realistic.
    if random.random() < 0.8:
        normalized_security_id = random.randint(1, NUM_SECURITIES)
    else:
        normalized_security_id = ""  # NULL, leave empty in CSV


    status = random.choice(statuses_row)
    error_message = ""
    if status == "Failed":
        error_message = "Could not parse row."


    # build raw_data JSON with some plausible fields
    raw_obj = {
        "raw_ticker": f"STK{random.randint(1, NUM_SECURITIES):04d}",
        "date": random_date(date(2022, 1, 1), date(2024, 12, 31)).strftime("%Y-%m-%d"),
        "quantity": str(round(random.uniform(1, 1000), 2)),
        "price": str(round(random.uniform(5, 500), 2)),
    }
    raw_data = json.dumps(raw_obj)


    import_rows.append(
        (rid, import_id, raw_data, normalized_security_id, status, error_message)
    )


with (OUTPUT_DIR / "ImportRow.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(
        [
            "import_row_id",
            "import_id",
            "raw_data",
            "normalized_security_id",
            "status",
            "error_message",
        ]
    )
    writer.writerows(import_rows)
