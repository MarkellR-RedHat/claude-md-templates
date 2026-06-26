# CLAUDE.md - FastAPI Project

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Replace "myapp" with your actual package name -->
<!-- TODO: Set your Python version (currently 3.11+) -->
<!-- TODO: Set your database and update the SQLAlchemy URL accordingly -->
<!-- TODO: Set your authentication method (JWT, API key, OAuth2) -->
<!-- TODO: Set your deployment target (Kubernetes, OpenShift, bare metal) -->
<!-- TODO: Update test commands to match your Makefile targets -->
<!-- TODO: Set your CI tool (GitHub Actions, Tekton, Jenkins) -->

## Project Overview

This is a FastAPI project. It uses Pydantic v2 for data validation, SQLAlchemy 2.0 for async database access, and Alembic for schema migrations. The codebase prioritizes type safety, testability, and production readiness.

- Target Python 3.11+ unless the project specifies otherwise.
- Use the version specified in `pyproject.toml` or `.python-version`.

## Project Structure

```
project-root/
  src/
    myapp/
      __init__.py
      main.py                # FastAPI app factory and lifespan
      config.py              # Settings via pydantic-settings
      database.py            # SQLAlchemy engine and session factory
      dependencies.py        # Shared dependencies (get_db, get_current_user)
      exceptions.py          # Custom exception classes and handlers
      middleware.py          # Request ID, timing, security headers
      routers/
        v1/
          __init__.py         # v1 router aggregation
          users.py
          items.py
          health.py
        v2/
          __init__.py
      schemas/
        user.py              # Pydantic request/response models
        item.py
        common.py            # Pagination, error response schemas
      models/
        base.py              # Declarative base and mixins
        user.py              # SQLAlchemy ORM models
        item.py
      services/
        user_service.py      # Business logic layer
      repositories/
        user_repo.py         # Data access layer
      auth/
        jwt.py               # Token creation and verification
        dependencies.py      # Auth-specific dependencies
        permissions.py       # Role-based access control
      tasks/
        email.py             # Background task definitions
  alembic/
    versions/
    env.py
  alembic.ini
  tests/
    conftest.py              # Shared fixtures, test database setup
    factories.py             # factory_boy model factories
    unit/
    integration/
  pyproject.toml
  Containerfile
  Makefile
  .env.example
```

### Layout Rules

- Use the `src/` layout to prevent importing from the project root.
- Separate Pydantic schemas from SQLAlchemy models. They serve different purposes.
- The `services/` layer holds business logic. Routers should be thin, delegating to services.
- The `repositories/` layer handles all database queries. Services call repositories, not the ORM directly.

## Pydantic Models

All Pydantic models must use v2 syntax. Do not use v1 patterns.

```python
from pydantic import BaseModel, ConfigDict, Field, field_validator, computed_field

class UserBase(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    username: str = Field(min_length=3, max_length=50, pattern=r"^[a-zA-Z0-9_]+$")
    email: str = Field(max_length=255)

class UserCreate(UserBase):
    password: str = Field(min_length=8, max_length=128)

    @field_validator("email")
    @classmethod
    def validate_email_format(cls, v: str) -> str:
        if "@" not in v:
            raise ValueError("Invalid email format")
        return v.lower()

class UserUpdate(BaseModel):
    """All fields optional for PATCH operations."""
    username: str | None = None
    email: str | None = None

class UserOut(UserBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    is_active: bool
    created_at: datetime
```

### Model Inheritance Pattern

- `XBase`: shared fields and validators
- `XCreate(XBase)`: fields needed at creation time
- `XUpdate(BaseModel)`: all fields optional for partial updates
- `XOut(XBase)`: fields returned to the client, with `from_attributes=True`

### Serialization Aliases

```python
class ItemOut(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    item_id: int = Field(serialization_alias="itemId")
    created_at: datetime = Field(serialization_alias="createdAt")
```

### Discriminated Unions

```python
from typing import Annotated, Literal, Union
from pydantic import Discriminator, Tag

class EmailNotification(BaseModel):
    type: Literal["email"] = "email"
    recipient: str

class SMSNotification(BaseModel):
    type: Literal["sms"] = "sms"
    phone_number: str

Notification = Annotated[
    Union[
        Annotated[EmailNotification, Tag("email")],
        Annotated[SMSNotification, Tag("sms")],
    ],
    Discriminator("type"),
]
```

### Computed Fields

```python
class UserOut(UserBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    first_name: str
    last_name: str

    @computed_field
    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"
```

## Dependency Injection

Use `Annotated` types with `Depends()` to keep route signatures clean.

```python
from typing import Annotated, AsyncGenerator
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        yield session

DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_active_user)]
UserSvc = Annotated[UserService, Depends(get_user_service)]

# Chain dependencies for automatic wiring
def get_user_service(
    repo: Annotated[UserRepository, Depends(get_user_repository)],
) -> UserService:
    return UserService(repo)
```

### Scoped vs Singleton Dependencies

- **Per-request** (use `yield`): database sessions, request-scoped caches.
- **Singleton** (module-level or app state): HTTP clients, connection pools, configuration. Create these in the lifespan handler.

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http_client = httpx.AsyncClient()
    app.state.redis = await aioredis.from_url(settings.redis_url)
    yield
    await app.state.http_client.aclose()
    await app.state.redis.close()
```

### Dependency Overrides for Testing

```python
@pytest.fixture
def client(test_db_session):
    app.dependency_overrides[get_db] = lambda: test_db_session
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
```

## Router Organization

Each resource gets its own router file. Aggregate routers by API version.

```python
# src/myapp/routers/v1/__init__.py
v1_router = APIRouter(prefix="/v1")
v1_router.include_router(users.router, prefix="/users", tags=["users"])
v1_router.include_router(items.router, prefix="/items", tags=["items"])
v1_router.include_router(health.router, prefix="/health", tags=["health"])

# src/myapp/main.py
app = FastAPI(title="My Service", version="1.0.0", lifespan=lifespan)
app.include_router(v1_router)
```

Keep router files thin. They validate input, call services, and return responses:

```python
@router.post("/", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def create_user(user_in: UserCreate, service: UserSvc) -> UserOut:
    existing = await service.get_by_email(user_in.email)
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")
    return await service.create(user_in)
```

- Always set `response_model` on endpoints that return data.
- Use `status_code=201` for creation, `204` for deletion.
- For versioned APIs, create a new `v2/` namespace when introducing breaking changes.

## Database Patterns

### SQLAlchemy 2.0 Async Setup

```python
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

engine = create_async_engine(
    settings.database_url,
    pool_size=20, max_overflow=10,
    pool_pre_ping=True, pool_recycle=3600,
)

async_session_factory = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False,
)
```

### Model Conventions

Use 2.0-style `Mapped` and `mapped_column`. Do not use the legacy `Column()` syntax.

```python
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

class Base(DeclarativeBase):
    pass

class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        server_default=func.now(), onupdate=func.now()
    )

class User(TimestampMixin, Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(default=True)
```

### Alembic Migrations

Configure `alembic/env.py` to import all model modules so autogenerate detects changes.

```bash
alembic revision --autogenerate -m "add users table"   # Autogenerate from models
alembic revision -m "backfill display names"            # Manual/data migration
alembic upgrade head                                    # Apply all pending
alembic downgrade -1                                    # Roll back one
```

For data migrations, combine schema and data changes in a single revision:

```python
def upgrade() -> None:
    op.add_column("users", sa.Column("display_name", sa.String(100)))
    op.execute("UPDATE users SET display_name = username WHERE display_name IS NULL")
    op.alter_column("users", "display_name", nullable=False)
```

### Transaction Management

Use the session context manager for automatic commit/rollback. For operations spanning multiple repositories, manage the transaction at the service level so all changes commit or roll back together.

## Authentication and Authorization

### OAuth2 with JWT

```python
from jose import JWTError, jwt

ALGORITHM = "HS256"

def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.secret_key, algorithm=ALGORITHM)
```

### Auth Dependency Chain

```python
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/v1/auth/token")

async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)], db: DbSession,
) -> User:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
        user_id: int = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user
```

### API Key Authentication

For service-to-service communication:

```python
api_key_header = APIKeyHeader(name="X-API-Key")

async def verify_api_key(api_key: Annotated[str, Depends(api_key_header)]) -> str:
    if api_key not in settings.valid_api_keys:
        raise HTTPException(status_code=401, detail="Invalid API key")
    return api_key
```

### Role-Based Access Control

```python
class Role(StrEnum):
    ADMIN = "admin"
    EDITOR = "editor"
    VIEWER = "viewer"

def require_role(*allowed_roles: Role):
    async def checker(current_user: CurrentUser) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return current_user
    return checker

# Usage
@router.delete("/{user_id}", dependencies=[Depends(require_role(Role.ADMIN))])
```

## Async Patterns

**Use async for**: database queries (asyncpg, aiosqlite), HTTP calls (httpx), WebSockets, file I/O (aiofiles).

**Use sync (run in thread pool) for**: CPU-bound work, libraries without async support.

```python
from starlette.concurrency import run_in_threadpool

@router.post("/process")
async def process(data: ProcessRequest) -> ProcessResponse:
    result = await run_in_threadpool(cpu_heavy_function, data.payload)
    return ProcessResponse(result=result)
```

### Background Tasks

Use `BackgroundTasks` for fire-and-forget work. For long-running jobs with retries, use Celery or ARQ.

```python
@router.post("/users/", status_code=201)
async def create_user(
    user_in: UserCreate, service: UserSvc, background_tasks: BackgroundTasks,
) -> UserOut:
    user = await service.create(user_in)
    background_tasks.add_task(send_welcome_email, user.email, user.username)
    return user
```

### WebSocket Pattern

```python
@router.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await manager.broadcast(f"Client {client_id}: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)
```

## Testing

### Test Setup with httpx AsyncClient

```python
# tests/conftest.py
TEST_DATABASE_URL = "sqlite+aiosqlite:///./test.db"
test_engine = create_async_engine(TEST_DATABASE_URL)
TestSession = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)

@pytest.fixture(scope="session")
async def setup_db():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.fixture
async def db_session(setup_db):
    async with TestSession() as session:
        yield session
        await session.rollback()

@pytest.fixture
async def client(db_session):
    app.dependency_overrides[get_async_session] = lambda: db_session
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()
```

### Writing Tests

```python
@pytest.mark.anyio
async def test_create_user(client: AsyncClient):
    response = await client.post("/v1/users/", json={
        "username": "testuser", "email": "test@example.com", "password": "secure123",
    })
    assert response.status_code == 201
    assert response.json()["username"] == "testuser"
    assert "password" not in response.json()
```

Configure pytest for async in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --strict-markers"
asyncio_mode = "auto"
```

### Factory Patterns

```python
class UserFactory(factory.Factory):
    class Meta:
        model = User
    username = factory.Sequence(lambda n: f"user{n}")
    email = factory.LazyAttribute(lambda obj: f"{obj.username}@example.com")
    hashed_password = "hashed_test_password"
    is_active = True
```

### Mocking External Services

Mock at the boundary. Use `pytest-mock` to patch external calls:

```python
@pytest.mark.anyio
async def test_create_user_sends_email(client: AsyncClient, mocker):
    mock_send = mocker.patch("myapp.tasks.email.send_welcome_email")
    response = await client.post("/v1/users/", json={...})
    assert response.status_code == 201
    mock_send.assert_called_once()
```

### Testing WebSockets

Use Starlette's synchronous `TestClient` for WebSocket tests:

```python
def test_websocket_connect():
    client = TestClient(app)
    with client.websocket_connect("/ws/test-client") as ws:
        ws.send_text("hello")
        assert "hello" in ws.receive_text()
```

## Error Handling

```python
class AppError(Exception):
    def __init__(self, message: str, code: str, status_code: int = 400):
        self.message = message
        self.code = code
        self.status_code = status_code

class NotFoundError(AppError):
    def __init__(self, resource: str, resource_id: str | int):
        super().__init__(f"{resource} '{resource_id}' not found", "NOT_FOUND", 404)

def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def handle_app_error(request: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": {"code": exc.code, "message": exc.message}},
        )
```

All error responses follow a consistent structure: `{"error": {"code": "...", "message": "...", "details": []}}`. Document error responses with the `responses` parameter on route decorators.

## Middleware

### CORS

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,  # Never ["*"] in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Request ID and Timing

```python
class RequestIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response

class TimingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        response.headers["X-Process-Time"] = f"{time.perf_counter() - start:.4f}"
        return response
```

Add middleware in reverse order of execution. The last added runs first (outermost).

## OpenAPI Schema

```python
app = FastAPI(
    title="My Service API", version="1.0.0",
    docs_url="/docs", redoc_url="/redoc", openapi_url="/openapi.json",
    servers=[
        {"url": "https://api.example.com", "description": "Production"},
    ],
)
```

- Use `include_in_schema=False` to hide internal endpoints.
- Add examples via `ConfigDict(json_schema_extra={"examples": [...]})` on Pydantic models.

## Performance

- **Streaming**: Use `StreamingResponse` for large payloads (CSV exports, NDJSON).
- **Caching**: Use Redis with TTL for frequently read, rarely changed data.
- **Connection pooling**: Set `pool_size` >= number of Uvicorn workers. Use `pool_pre_ping=True`.
- **Workers**: Use `gunicorn` with `uvicorn.workers.UvicornWorker`. In containers, set workers explicitly (do not rely on `cpu_count()`).

```python
# gunicorn.conf.py
bind = "0.0.0.0:8000"
workers = 4
worker_class = "uvicorn.workers.UvicornWorker"
timeout = 120
keepalive = 5
```

## Security

- Set `max_length` on all string fields in Pydantic models. Unbounded strings enable DoS.
- Use `Field(ge=0, le=1000)` on numeric fields to set bounds.
- Never interpolate user input into raw SQL. Use SQLAlchemy's parameterized queries.
- Never use `allow_origins=["*"]` in production CORS configuration.
- Add security headers (X-Content-Type-Options, X-Frame-Options, HSTS) via middleware.
- Use `slowapi` for rate limiting on sensitive endpoints like login.
- Run `pip-audit` in CI to catch dependency vulnerabilities.

## Logging and Observability

### Structured Logging

```python
import structlog

structlog.configure(processors=[
    structlog.contextvars.merge_contextvars,
    structlog.processors.add_log_level,
    structlog.processors.TimeStamper(fmt="iso"),
    structlog.processors.JSONRenderer(),
])

# In middleware, bind request context:
structlog.contextvars.bind_contextvars(
    request_id=request.state.request_id,
    method=request.method,
    path=request.url.path,
)
```

### OpenTelemetry

```python
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
FastAPIInstrumentor.instrument_app(app)
```

Configure the OTLP exporter endpoint via `APP_OTLP_ENDPOINT` environment variable.

### Health Check Endpoints

Expose three endpoints under `/v1/health/`:

- `/live` - returns 200 if the process is running (Kubernetes liveness probe)
- `/ready` - checks database connectivity (Kubernetes readiness probe)
- `/` - detailed health with all dependency status

```python
@router.get("/ready")
async def readiness(db: DbSession):
    try:
        await db.execute(text("SELECT 1"))
        return {"status": "ready"}
    except Exception:
        return JSONResponse(status_code=503, content={"status": "not ready"})
```

## Deployment

### Container Image with UBI

```dockerfile
FROM registry.access.redhat.com/ubi9/python-311:latest AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM registry.access.redhat.com/ubi9/python-311:latest
WORKDIR /app
COPY --from=builder /opt/app-root /opt/app-root
COPY src/ src/
COPY alembic/ alembic/
COPY alembic.ini .
USER 1001
EXPOSE 8000
CMD ["gunicorn", "myapp.main:app", \
     "--worker-class", "uvicorn.workers.UvicornWorker", \
     "--workers", "4", "--bind", "0.0.0.0:8000"]
```

### Kubernetes Deployment

Set `livenessProbe` to `/v1/health/live` and `readinessProbe` to `/v1/health/ready`. Set resource requests and limits. Use `envFrom` with Secrets and ConfigMaps for configuration.

### Environment Configuration

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="APP_", env_file=".env")

    debug: bool = False
    database_url: str = "postgresql+asyncpg://localhost:5432/myapp"
    secret_key: str
    cors_origins: list[str] = ["http://localhost:3000"]
    redis_url: str = "redis://localhost:6379/0"
    otlp_endpoint: str = "http://localhost:4317"
```

Provide `.env.example` with placeholder values. Never commit `.env`.

## Common Pitfalls

**Forgetting await on async calls.** You get a coroutine object instead of the result. Enable ruff's `ASYNC` rule set to catch these.

**Sync database drivers in async code.** Using `psycopg2` or `sqlite3` blocks the event loop. Use `asyncpg` (`postgresql+asyncpg://`), `aiosqlite` (`sqlite+aiosqlite://`), or `aiomysql` (`mysql+aiomysql://`).

**Circular imports.** Models importing schemas and schemas importing models. Fix with `TYPE_CHECKING`:

```python
from __future__ import annotations
from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from myapp.models.user import User
```

**Pydantic v1 vs v2 gotchas:**

| v1 Pattern | v2 Replacement |
|---|---|
| `class Config:` | `model_config = ConfigDict(...)` |
| `orm_mode = True` | `from_attributes = True` |
| `@validator` | `@field_validator` |
| `@root_validator` | `@model_validator` |
| `.dict()` | `.model_dump()` |
| `.json()` | `.model_dump_json()` |
| `update_forward_refs()` | `model_rebuild()` |

**Background task error handling.** Exceptions in background tasks are silently swallowed. Always wrap them with try/except and log failures.

**N+1 queries.** Use `selectinload` or `joinedload` to eagerly load relationships instead of accessing them lazily in loops.

## Common Commands

```bash
# Set up development environment
uv venv && source .venv/bin/activate && uv pip install -e ".[dev]"

# Run development server
uvicorn myapp.main:app --reload --host 0.0.0.0 --port 8000

# Database migrations
alembic upgrade head
alembic revision --autogenerate -m "describe the change"
alembic downgrade -1

# Testing
pytest
pytest --cov=src/myapp --cov-report=term-missing
pytest tests/unit/
pytest tests/integration/ -m integration

# Lint, format, type check
ruff check src/ tests/ --fix
ruff format src/ tests/
mypy src/

# Security and build
pip-audit
podman build -t myapp:latest -f Containerfile .
podman run -p 8000:8000 --env-file .env myapp:latest
```

## Common Mistakes Claude Makes

**Using Pydantic v1 patterns.** Claude writes `class Config:` instead of `model_config = ConfigDict(...)`, uses `@validator` instead of `@field_validator`, and calls `.dict()` instead of `.model_dump()`. This project uses Pydantic v2 exclusively.

**Using synchronous database drivers.** Claude imports `psycopg2` or `sqlite3` instead of `asyncpg` or `aiosqlite`. Synchronous drivers block the event loop. Always use async drivers with SQLAlchemy 2.0 async engine.

**Putting business logic in route handlers.** Claude writes database queries and complex logic directly in route functions. Route handlers should validate input, call a service, and return the response. Business logic belongs in the `services/` layer.

**Missing `max_length` on string fields.** Claude creates Pydantic models with `str` fields that have no length constraint. Every string field needs `max_length` to prevent unbounded input.

**Using `allow_origins=["*"]` for CORS.** Claude sets a wildcard CORS origin in middleware. Never use `["*"]` in production. List specific allowed origins.

**Forgetting to await async calls.** Claude writes `result = get_user(user_id)` instead of `result = await get_user(user_id)` in async functions. The result is a coroutine object, not the actual data. Enable ruff's ASYNC rules to catch these.

**Not handling background task failures.** Claude adds background tasks without try/except blocks. Exceptions in background tasks are silently swallowed. Always wrap background task code in error handling and log failures.

**Creating N+1 query patterns.** Claude accesses ORM relationships in loops without eager loading. Use `selectinload()` or `joinedload()` on relationship queries to avoid N+1.

## Review Checklist

Before merging:

- [ ] All tests pass, including integration tests
- [ ] `ruff check` and `ruff format --check` report no issues
- [ ] `mypy` passes in strict mode with pydantic plugin
- [ ] Type hints present on all function signatures
- [ ] No hardcoded credentials, secrets, or configuration values
- [ ] New dependencies justified, pinned, and scanned with `pip-audit`
- [ ] All Pydantic string fields have `max_length` set
- [ ] Async functions properly awaited everywhere
- [ ] Database queries use async drivers
- [ ] New columns have Alembic migrations with both upgrade and downgrade
- [ ] Passwords and tokens never returned in API responses
- [ ] Error responses follow the structured format
- [ ] New endpoints have appropriate auth
- [ ] CORS is restrictive, not `["*"]`
- [ ] Background tasks have error handling
- [ ] Health checks updated if new dependencies added
- [ ] OpenAPI schema renders correctly at /docs
- [ ] `.env.example` updated if new env vars added
- [ ] No em dashes in code, comments, or documentation
