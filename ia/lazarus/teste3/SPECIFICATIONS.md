# SGT API - Technical Specifications

## Overview

**SGT API** is a REST API built with **Free Pascal / Lazarus** using the **Horse** web framework. It provides multi-tenant access to business entities (products, sales, inventory, fiscal configuration, etc.) backed by Firebird/PostgreSQL databases.

- **Language**: FPC (Delphi-compatible via `{$ifdef FPC}`)
- **Framework**: Horse + Horse.JWT + Horse.CORS + Horse.Logger
- **Database**: UniDAC (default), Zeos, SQLDB, FireDAC (compile-time selectable)
- **Architecture**: Layered — Controllers → Services → Connectors/Adapters

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     HTTP Request                            │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Middleware Pipeline (main.pas)                             │
│  • Request/Response logging                                 │
│  • CORS                                                     │
│  • JSON body parsing (Jhonson)                              │
│  • Exception handling                                       │
│  • JWT authentication (protected routes)                    │
│  • Session injection (EmpresaID from header)                │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Controllers (controller/*.pas)                             │
│  • Route registration (THorse.Get/Post/Put/Delete)          │
│  • Request parsing, param extraction                        │
│  • Call Service, return JSON response                       │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Services (services/*.pas)                                  │
│  • Business logic, SQL (DQL/DML)                            │
│  • TServiceProvider → TServiceProviderCadastros → Entity    │
│  • Soft delete (STATUS = 'C')                               │
│  • Auto ID generation via generators                        │
│  • Child queries for nested JSON (precos, icms, piscofins)  │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Connectors & Adapters                                      │
│  • TConnectionFactory / TQueryFactory (driver abstraction)  │
│  • IQuery interface (fluent API: Select, Insert, Update...) │
│  • DataSet → JSON serialization                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Authentication & Authorization

### JWT Token
- **Algorithm**: HS256
- **Secrets** (in `security/JWT.pas`):
  - `SERVER_SK` — token signing
  - `DATA_SK` — field encryption (ConnectionID, CNPJ, User)
- **Claims** (`TCredentialClaims`):
  - `id` — user ID
  - `cnpj` — client identifier (encrypted)
  - `user` — username (encrypted)
  - `connectionId` — DB connection identifier (encrypted)
  - `empresaId` — tenant ID (set via header)
  - `exp` — 12 hours

### Flow
1. `POST /auth` or `POST /auth/login` → validates `client_id` + `client_secret` (+ optional `usuario`)
2. On success → creates session, returns JWT
3. Protected routes: `THorse.Use('/path', HorseJWT(SERVER_SK, ...))`
4. `EmpresaID` header → `TSessionManager` → decrypted in `TSessionInstance`

### Session Access (in Services)
```pascal
Session.ConnectionID  // decrypted DB name
Session.ID            // user ID
Session.CNPJ          // client CNPJ
Session.User          // username
Session.EmpresaID     // from header
```

---

## Database Layer

### Configuration (`connector.configuration.pas`)
Loaded from `application.ini` (beside executable) with env var overrides:

| Section | Keys |
|---------|------|
| `[database]` | driver, host, port, dbfile, user, password, libraryClient, charset |
| `[credential]` | database (default: `sgt_cred`) |
| `[log]` | location (default: `./log`) |
| `[api]` | port (default: `5000`) |

**Env vars**: `DB_DRIVER`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`, `DB_LIB`, `DB_CHARSET`, `CRED_DB`, `LOG_DIR`, `API_PORT`

### Connection per Request
Each service call creates a `TdmConn` via `TdmConn.CreateConnection(Session.ConnectionID)` — connects to the tenant's database.

### Multi-Driver Support (compile-time)
| Define | Package | Driver |
|--------|---------|--------|
| `USE_UNIDAC` + `DEFAULT_UNIDAC` | `unidac10`, `ibprovider10` | UniDAC (default) |
| `USE_ZEOS` + `DEFAULT_ZEOS` | `zcomponent` | Zeos |
| `USE_SQLDB` + `DEFAULT_SQLDB` | `sqldb` | SQLDB (FPC native) |
| `USE_FIREDAC` | FireDAC | FireDAC (Delphi) |

### Query Interface (`IQuery`)
Fluent API in `adapter.query.intf.pas`:
```pascal
TQueryFactory.New(dmConn, dmConn.dbConnection)
  .Select('SELECT * FROM PRODUTO WHERE ID = :id')
  .SetParamByName('id', '123')
  .Open
  .AsDataSet.ToJSONArrayString
```

Supports: child queries (`SetChildQuery`), JSON insert/update (`InsertJSON`), returning fields, parameter binding.

---

## Service Layer

### Base Classes
| Class | Purpose |
|-------|---------|
| `TServiceProvider` | Connection management, CRUD templates, result handling |
| `TServiceProviderCadastros` | Insert with duplicate/canceled detection |
| `TProdutoService` (example) | Entity-specific queries, nested data |

### Standard Operations
| Method | HTTP | Description |
|--------|------|-------------|
| `listAll(params)` | GET | Filtered list, supports child queries |
| `insert(json)` | POST | Auto-generates ID if missing |
| `update(json)` | PUT | Upsert via `InsertJSON(..., True)` |
| `delete(id)` | DELETE | Soft delete (`STATUS = 'C'`) |

### Response Format
```pascal
TServiceProviderResult = record
  Status: THTTPStatus;
  MessageResponse: String;  // JSON
end;
```

### Error Codes (`TServiceResponseStatus`)
- `PrimaryKeyError` (10) — duplicate key
- `CanceledError` (11) — record is canceled
- `ProductUniqueKeyError` (12) — unique constraint (product description)
- `IdNotDefined` (13) — missing ID on insert

---

## API Endpoints

### Public (no JWT)
| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth` | Authenticate client_id/client_secret |
| POST | `/auth/login` | Authenticate + user login |
| POST | `/decrypt` | Decrypt payload (testing) |
| GET | `/auth/testeconexao` | Test DB connection |

### Protected (JWT required)
All under `THorse.Use('/path', HorseJWT(...))` in `controller.routes.pas`.

#### Core Entities
| Module | Base Path | Key Endpoints |
|--------|-----------|---------------|
| Empresa | `/empresa` | CRUD |
| Usuario | `/usuario` | CRUD |
| Entidade | `/cliente`, `/fornecedor` | CRUD |
| CFOP | `/cfop` | CRUD |
| ICMS | `/icms` | CRUD |
| Unidade | `/unidade` | CRUD |
| Setor | `/setor` | CRUD |
| ProdutoOrigem | `/produtoorigem` | CRUD |
| Modalidade | `/modalidade` | CRUD |
| NaturezaOp | `/naturezaop` | CRUD |
| Cpgto | `/cpgto` | CRUD |

#### Produto (rich entity)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/produto` | List (filters: codigo, descricao, referencia) |
| GET | `/produto/:id` | Single + nested (precos, icms, piscofins) |
| GET | `/produto/:id/full` | Full detail |
| GET | `/produto/codigo/:codigo` | By code |
| GET | `/produto/descricao/:descricao` | By description |
| GET | `/produto/referencia/:referencia` | By reference |
| GET | `/produto/:id/preco` | Prices only |
| GET | `/produto/:id/icms` | ICMS config only |
| GET | `/produto/:id/piscofins` | PIS/COFINS only |
| POST/PUT | `/produto` | Insert/Update (with nested arrays) |
| POST/PUT | `/produto/preco` | Price records |
| POST/PUT | `/produto/icms` | ICMS records |
| POST/PUT | `/produto/piscofins` | PIS/COFINS records |
| DELETE | `/produto/:id` | Soft delete |

#### Transactional
| Module | Base Path |
|--------|-----------|
| Movimento | `/movimento` |
| MovVenda | `/movvenda` |
| MovItem | `/movitem` |
| MovPagamento | `/movpagamento` |
| Estoque | `/estoque` |

---

## Configuration & Build

### Build Modes (from `sgtapi.lpi`)
| Mode | Defines | Output | Notes |
|------|---------|--------|-------|
| **Debug** (default) | `HORSE_LCL` | `../build/sgtapi` | Debug info, range/overflow checks, heaptrc |
| **Release** | `HORSE_LCL`, `HORSE_DAEMON` | `../build/sgtapi` | -O3, smart linking, no debug info |

### Commands
```bash
# Debug
cd src && lazbuild sgtapi.lpi

# Release
cd src && lazbuild sgtapi.lpi -B -r

# Run
cd build && ./sgtapi
```

### Required Lazarus Packages
- `unidac10`, `ibprovider10` (UniDAC)
- `zcomponent` (Zeos)
- `dcpcrypt`, `dcpcrypt_laz` (crypto)
- `zcomponentdesign` (Zeos design-time)

### Vendored Dependencies (`.modules/`)
Core: `horse`, `jhonson`, `horse-cors`, `handle-exception`, `horse-logger`, `horse-logger-provider-logfile`, `horse-jwt`, `horse-utils-clientip`

Crypto: `HashLib4Pascal` (FPC), `delphi-jose-jwt` (Delphi)

---

## Key Conventions

1. **Soft delete**: All entities use `STATUS` field; `'C'` = canceled. Queries filter `STATUS <> 'C'` by default.
2. **Nested JSON**: Related data (precos, icms, piscofins) returned as child arrays via `SetChildQuery`.
3. **Auto ID**: If `id` missing on insert → `getNextAvailableCode()` queries generator.
4. **Connection per tenant**: `Session.ConnectionID` determines which database file to attach.
5. **FPC/Delphi compatible**: All units use `{$ifdef FPC}` / `{$else}` blocks.
6. **Logging**: Request/response logs to `./logs` (configurable via `LOG_DIR` / `[log] location`).
7. **DataModules**: `dmConn`, `dmProdutoService` have `.lfm` resources — must be compiled in.

---

## Extending the API

### Add New Entity
1. Create service: `services/service.novaentidade.pas` extending `TServiceProviderCadastros`
2. Implement `listAll`, `insert`, `update`, `delete` (or inherit)
3. Create controller: `controllers/controller.novaentidade.pas` with `registerRoutes`
4. Register in `controller.routes.pas`:
   ```pascal
   THorse.Use('/novaentidade', HorseJWT(...));
   TNovaEntidadeController.registerRoutes;
   ```
5. Add unit to `sgtapi.lpr` uses clause and `sgtapi.lpi` Units section.

### Add New Database Driver
1. Implement `IQuery` in `adapters/` (see `TUnidacQuery`, `TZeosQuery`)
2. Add connector unit in `connectors/`
3. Register in `connector.factory.pas` with new `{$ifdef USE_NEWDRIVER}` block
4. Add package to `RequiredPackages` in `.lpi`

---

## Common Patterns

### Service Constructor
```pascal
constructor TMyService.Create(Session: TSessionInstance);
begin
  inherited Create(Session);
  FSQLTabela := 'MINHATABELA';
  FSQLSelect := 'SELECT * FROM MINHATABELA';
end;
```

### Custom Query in Service
```pascal
query := TQueryFactory.New(dmConn, dmConn.dbConnection)
             .Select('SELECT * FROM MINHATABELA WHERE ID = :id')
             .SetParamByName('id', id)
             .Open;
SetServiceResult(query.AsDataSet.ToJSONArrayString);
```

### Controller Route
```pascal
class procedure TMyController.registerRoutes;
begin
  THorse.Get('/minhaentidade', onGet);
  THorse.Get('/minhaentidade/:id', onGet);
  THorse.Post('/minhaentidade', onPost);
  THorse.Put('/minhaentidade', onPost);
  THorse.Delete('/minhaentidade/:id', onDelete);
end;
```

---

## Testing & Debugging

- **Connection test**: `GET /auth/testeconexao` (requires valid JWT)
- **Logs**: Check `./logs/req_*.log` (requests) and `./logs/service.*.log` (service errors)
- **Debug mode**: Run from Lazarus IDE with breakpoints; heaptrc enabled
- **Manual token**: Use `JWT.createToken(ID, ClientID, User, ConnectionID)` for testing

---

## File Map (Key Units)

| Layer | Files |
|-------|-------|
| Entry | `sgtapi.lpr`, `main.pas` |
| Config | `connector.configuration.pas`, `system.config.pas` |
| Auth | `security/JWT.pas`, `security/CredentialClaims.pas`, `controller.auth.pas`, `controller.session.pas` |
| DB | `db/connection.pas`, `connectors/connector.factory.pas`, `connectors/connector.unidac.pas` |
| Query | `adapters/adapter.query.intf.pas`, `adapters/adapter.query.impl.pas` |
| Base Services | `services/service.commons.pas`, `services/service.serviceprovider.pas`, `services/service.serviceprovidercadastros.pas` |
| Routes | `controllers/controller.routes.pas` |