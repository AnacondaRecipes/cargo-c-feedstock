@echo on
setlocal EnableExtensions EnableDelayedExpansion

REM --- Isolate Cargo from conda-build generated .cargo.win/config (duplicate key issue)
set "CARGO_HOME=%SRC_DIR%\.cargo-home"
if exist "%CARGO_HOME%" rmdir /S /Q "%CARGO_HOME%"
mkdir "%CARGO_HOME%"

REM Minimal Cargo config (avoid any duplicated [target.*] blocks)
> "%CARGO_HOME%\config.toml" echo [net]
>>"%CARGO_HOME%\config.toml" echo git-fetch-with-cli = true

REM --- Make pkg-config find .pc files in the env
set "PKG_CONFIG_PATH=%LIBRARY_LIB%\pkgconfig;%LIBRARY_PREFIX%\share\pkgconfig;%PKG_CONFIG_PATH%"

REM --- Ensure rust can find native libs from the env (libcurl/openssl/zlib, etc.)
set "RUSTFLAGS=%RUSTFLAGS% -L native=%LIBRARY_LIB%"

REM Optional: keep build artifacts in source tree (more predictable)
set "CARGO_TARGET_DIR=%SRC_DIR%\target"

cargo install --path . --root "%LIBRARY_PREFIX%" --locked --verbose
if errorlevel 1 exit 1

cargo-bundle-licenses --format yaml --output THIRDPARTY.yml
if errorlevel 1 exit 1

REM Clean up (cargo sometimes drops this at PREFIX root on some platforms)
del /f /q "%PREFIX%\.crates.toml" 2>nul

endlocal