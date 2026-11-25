# Dark Eden for Windows
Extract the entire Windows ZIP and open DarkEden.exe. To join a world, enter the host IPv4 address, choose Play, and select fengshen.exe from your extracted game folder on first use. The launcher remembers the folder. Obtain the matching data archive from the upstream client README.

To host, install Docker Desktop with Linux containers, start it, and choose Start server. Use 127.0.0.1 for a private world or your PC's LAN IPv4 for a shared world. First startup downloads the server and database images. Enter an ID and a unique game password, choose Create player, then Play. Friends only need the launcher, game files and your LAN address. Stop server before changing the advertised address.

The original client stores game credentials in a legacy format. Use on a trusted network. Database data survives Stop server. For dedicated hosting see server/standalone/README.md. A source build of the Windows client additionally exposes Server management in the game window's system menu when launched from here.

The Windows launcher can be rebuilt with a MinGW compiler using `x86_64-w64-mingw32-gcc -municode -mwindows -Os launcher.c -o DarkEden.exe`. Place menu.ps1 next to it, and copy standalone and initdb from the matching server fork into server/.
