# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['console_deck_pro.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[
        'uvicorn.logging',
        'uvicorn.loops',
        'uvicorn.loops.auto',
        'uvicorn.loops.asyncio',
        'uvicorn.protocols',
        'uvicorn.protocols.http',
        'uvicorn.protocols.http.auto',
        'uvicorn.protocols.http.h11_impl',
        'uvicorn.protocols.http.httptools_impl',
        'uvicorn.protocols.websockets',
        'uvicorn.protocols.websockets.auto',
        'uvicorn.lifespan',
        'uvicorn.lifespan.on',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

# One-folder build (exe + _internal folder), not one-file:
# - a one-file exe unpacks itself to %TEMP% at every start, which slows down the
#   start at sign-in and leaves the unpacked copy behind whenever the process is
#   killed (the installer kills it on upgrade/uninstall);
# - the installer copies a folder anyway.
exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='console_deck_pro',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    # Windowed on purpose: the installer starts the backend at sign-in with
    # --background and no console must appear. Started by hand, the backend
    # opens its own console (see _setup_console in console_deck_pro.py).
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name='console_deck_pro',
)
