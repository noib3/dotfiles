{
  fetchurl,
  python313Packages,
  lib,
}:

let
  aiosqlite = python313Packages.aiosqlite.overridePythonAttrs (_old: rec {
    version = "0.22.1";
    src = python313Packages.fetchPypi {
      pname = "aiosqlite";
      inherit version;
      hash = "sha256-BD4L140yiIwKnKkPx4izh5aEM2DIVacmKlMoExM6BlA=";
    };
  });
in
python313Packages.buildPythonApplication rec {
  pname = "codex-lb";
  version = "1.15.0";
  format = "wheel";

  src = fetchurl {
    url = "https://github.com/Soju06/codex-lb/releases/download/v${version}/codex_lb-${version}-py3-none-any.whl";
    hash = "sha256-FLp9IQWDZLGWbcefn1fhSFYOICm9lkwNI+j9lVqgbPY=";
  };

  dependencies = with python313Packages; [
    aiohttp
    aiohttp-retry
    alembic
    aiosqlite
    asyncpg
    bcrypt
    brotli
    cryptography
    fastapi
    greenlet
    psycopg
    pydantic
    pydantic-settings
    pyotp
    python-dotenv
    python-multipart
    segno
    sqlalchemy
    uvicorn
    websockets
    zstandard
  ];

  doCheck = false;

  meta = {
    description = "Codex load balancer and proxy for ChatGPT accounts";
    homepage = "https://github.com/Soju06/codex-lb";
    license = lib.licenses.mit;
    mainProgram = "codex-lb";
  };
}
