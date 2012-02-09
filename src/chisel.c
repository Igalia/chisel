/*
 * chisel.c
 * Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
 *
 * Distributed under terms of the MIT license.
 */


#include "../lua/lauxlib.h"
#include "../lua/lualib.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>

#ifndef CHSL_LUA_LIBDIR
#define CHSL_LUA_LIBDIR "src/"
#endif /* !CHSL_LUA_LIBDIR */

#define CHSL_VERSION "0.1"

#define HELP_TEXT \
    "Usage: %s [options]\n\n"                                        \
    "   -L PATH   Set library path (default: " CHSL_LUA_LIBDIR ")\n" \
    "   -S NAME   Script to run (default: same as program name)\n"   \
    "   -v        Be verbose. Use twice for debugging output\n"      \
    "   -i        Run an interactive Lua interpreter.\n"             \
    "\n"

#define BOOT_SCRIPT \
    "package.cpath = \"\"\n" \
    "package.path = chisel.libdir .. \"/?.lua\"\n" \
    "require \"_boot\""


static char *g_libdir = CHSL_LUA_LIBDIR;
static char *g_script = NULL;
static int   g_loglvl = 0;
static int   g_cli    = 0;


static int
chisel_lua_init (lua_State *L)
{
    assert (L);
    lua_newtable (L);

    lua_pushstring (L, g_libdir);
    lua_setfield   (L, -2, "libdir");
    lua_pushstring (L, CHSL_VERSION);
    lua_setfield   (L, -2, "version");
    lua_pushnumber (L, g_loglvl);
    lua_setfield   (L, -2, "loglevel");
    lua_pushnumber (L, g_cli);
    lua_setfield   (L, -2, "interactive");
    lua_setglobal  (L, "chisel");

    if (luaL_dostring (L, BOOT_SCRIPT))
        return luaL_error (L, "Could not initialize chisel in '%s'", g_libdir);

    return 0;
}


static int
lua_main (lua_State *L)
{
    int    argc = (int)    lua_tointeger (L, 1);
    char **argv = (char**) lua_touserdata (L, 2);

    (void) argc;
    (void) argv;

    /* Open libraries, pausing the collector during initialization */
    luaL_checkversion (L);
    lua_gc (L, LUA_GCSTOP, 0);
    luaL_openlibs (L);
    chisel_lua_init (L);
    lua_gc (L, LUA_GCRESTART, 0);

    if (luaL_loadfile (L, g_cli ? NULL : g_script) != LUA_OK) {
        lua_error (L);
    }

    lua_call (L, 0, 0);
    return 0;
}


static int
find_script (void)
{
    char filename[PATH_MAX];
    const char *progname;
    struct stat sb;

    progname = strrchr (g_script, '/');
    if (progname && progname[1] != '\0')
        progname++;
    else
        progname = g_script;

    strcpy (filename, g_libdir);
    strcat (filename, "/");
    strcat (filename, progname);
    strcat (filename, ".lua");

    if (stat (filename, &sb) == 0 &&
        S_ISREG(sb.st_mode) &&
        sb.st_mode & (S_IRUSR | S_IRGRP | S_IROTH))
    {
        g_script = strdup (filename);
        return 0;
    }

    if (stat (g_script, &sb) == 0 &&
        S_ISREG(sb.st_mode) &&
        sb.st_mode & (S_IRUSR | S_IRGRP | S_IROTH))
    {
        g_script = strdup (g_script);
        return 0;
    }

    return 1;
}


int
main (int argc, char *argv[])
{
    lua_State *L = NULL;
    int status;

    while ((status = getopt (argc, argv, "viS:L:h")) != -1) {
        switch (status) {
            case 'i': /* Interactive interpreter. */
                g_cli = 1;
                break;

            case 'v': /* Increase verbosity level. */
                g_loglvl++;
                break;

            case 'L': /* Set library path. */
                g_libdir = optarg;
                break;

            case 'S': /* Script to run. */
                g_script = optarg;
                break;

            case '?':
                fprintf (stderr,
                         "%s: invalid command line option '%s'\n",
                         argv[0],
                         argv[optind]);
                /* Fall-through */

            case 'h':
                fprintf (stderr,
                         HELP_TEXT,
                         argv[0]);
                exit ((status == 'h') ? EXIT_SUCCESS : EXIT_FAILURE);

            case ':':
                fprintf (stderr,
                         "%s: missing argument to option '%s'\n",
                         argv[0],
                         argv[optind]);
                exit (EXIT_FAILURE);
        }
    }

    if (!g_script)
        g_script = argv[0];

    if (!g_cli && find_script ()) {
        fprintf (stderr,
                 "%s: could not find script '%s', checked locations:\n"
                 "    - %s/%s.lua\n"
                 "    - %s\n",
                 argv[0],
                 g_script,
                 g_libdir,
                 g_script,
                 g_script);
        exit (EXIT_FAILURE);
    }

    if ((L = luaL_newstate ()) == NULL) {
        fprintf (stderr,
                 "%s: could not initialize Lua VM.\n",
                 argv[0]);
        exit (EXIT_FAILURE);
    }

    /* Push arguments, and do a protected call to lua_main above */
    lua_pushcfunction (L, lua_main);
    lua_pushinteger (L, argc);
    lua_pushlightuserdata (L, argv);

    if ((status = lua_pcall(L, 2, 0, 0)) != LUA_OK) {
        const char *msg = (lua_type (L, -1) == LUA_TSTRING) ? lua_tostring (L, -1)
                                                            : NULL;
        if (msg == NULL)
            msg = "(error object is not a string)";
        luai_writestringerror ("%s: ", argv[0]);
        luai_writestringerror ("%s\n", msg);
    }
    lua_close (L);
    return (status == LUA_OK) ? EXIT_SUCCESS : EXIT_FAILURE;
}

