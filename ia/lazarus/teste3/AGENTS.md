# SGT API - Lazarus/Free Pascal REST API

## Build & Run

**Build (Debug):**
```bash
cd src && lazbuild sgtapi.lpi
```

**Build (Release):**
```bash
cd src && lazbuild sgtapi.lpi -B -r
```

**Output:** `../build/sgtapi` (Linux) or `../build/sgtapi.exe` (Windows)

**Run:**
```bash
cd build && ./sgtapi
```
Requires `application.ini` in executable directory or environment variables.

## Configuration

Configuration loaded from `application.ini` (beside executable) with fallback to env vars:

```ini
[database]
driver=Firebird|PostgreSQL|MySQL|etc
host=localhost
port=3050
dbfile=/path/to/database.fdb
user=SYSDBA
password=masterkey
libraryClient=/path/to/fbclient.so
charset=UTF8

[credential]
database=sgt_cred

[log]
location=./log

[api]
port=5000
```

**Env vars (override INI):** `DB_DRIVER`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`, `DB_LIB`, `DB_CHARSET`, `CRED_DB`, `LOG_DIR`, `API_PORT`

## Project Structure

```
src/
├── sgtapi.lpr              # Program entry point
├── main.pas                # Server setup, middleware, Horse config
├── system.config.pas       # App-wide config (product pricing rules)
├── connectors/             # DB abstraction (UniDAC, Zeos, SQLDB, FireDAC)
├── adapters/               # Query/JSON adapters
├── controllers/            # HTTP route handlers
├── services/               # Business logic, SQL for DQL/DML
├── security/               # JWT, cipher
├── utils/                  # Helpers (logging, parsing, SQL values)
├── constants/              # Common constants
├── db/                     # DataModule for DB connection
└── .modules/               # Vendored dependencies (Horse, JWT, HashLib, etc.)
```

## Architecture

- **Controllers** → register routes, handle HTTP, call Services
- **Services** → business rules, SQL queries (DQL/DML)
- **Connectors** → database driver abstraction
- **Adapters** → query building, JSON serialization

## Dependencies (in `.modules/`)

Core: `horse`, `jhonson` (JSON), `horse-cors`, `handle-exception`, `horse-logger`, `horse-logger-provider-logfile`, `horse-jwt`, `horse-utils-clientip`

Crypto: `HashLib4Pascal` (FPC), `delphi-jose-jwt` (Delphi), `dcpcrypt`

DB: `unidac10`, `ibprovider10`, `zcomponent` (Zeos), `sqldb` (FPC)

Install via Lazarus Package Manager (`.lpk` files in each module).

## Build Modes (from .lpi)

- **Debug** (default): `-dHORSE_LCL`, debug info, range/overflow checks, heaptrc
- **Release**: `-dHORSE_LCL -dHORSE_DAEMON`, optimization level 3, smart linking, no debug info

## Key Quirks

- FPC/Delphi compatible via `{$ifdef FPC}` / `{$else}` blocks
- Uses `unidac10` / `ibprovider10` packages - must be installed in Lazarus
- `HORSE_LCL` define required for console/daemon detection
- Logs written to `./logs` by default (configurable)
- JWT secret `SERVER_SK` defined in `security/JWT.pas`
- DataModules (`dmConn`, `dmProdutoService`) have `.lfm` resources