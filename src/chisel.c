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

#define CHSL_VERSION "0.1"

#ifndef CHSL_LUA_LIBDIR
#define CHSL_LUA_LIBDIR "src/"
#endif /* !CHSL_LUA_LIBDIR */

#ifndef CHSL_REPL_MAXINPUT
#define CHSL_REPL_MAXINPUT 512
#endif /* !CHSL_REPL_MAXINPUT */

#define CHSL_REPL_PROMPT1 "(chisel) "
#define CHSL_REPL_PROMPT2 "    ...) "

#define HELP_TEXT \
    "Usage: %s [flags] [option1=value1 ... [optionN=valueN]]\n\n"    \
    "Available command line flags:\n\n"                              \
    "   -L PATH   Set library path (default: " CHSL_LUA_LIBDIR ")\n" \
    "   -S NAME   Script to run (default: same as program name)\n"   \
    "   -v        Be verbose. Use twice for debugging output\n"      \
    "   -i        Run an interactive Lua interpreter.\n\n"           \
    "Useable options vary depending on the script being run.\n\n"

#define BOOT_SCRIPT \
    "package.cpath = \"\"\n" \
    "package.path = chisel.libdir .. \"/?.lua\"\n" \
    "require \"_boot\""


#ifdef CHSL_READLINE
#include <readline/readline.h>
#include <readline/history.h>
#define repl_readline(L, b, p) \
        ((void) L, ((b) = readline (p)) != NULL)
#define repl_saveline(L, idx) \
        if (lua_rawlen (L, idx) > 0)              /* non-empty line? */ \
            add_history (lua_tostring (L, idx));  /* add it to history */
#define repl_freeline(L, b) \
        ((void)L, free(b))
#else /* !CHSL_READLINE */
#define repl_readline(L, b, p)     \
        ((void) L, fputs (p, stdout), fflush(stdout), /* show prompt */ \
        fgets (b, CHSL_LUA_MAXINPUT, stdin) != NULL)  /* get line */
#define repl_saveline(L,idx) \
        { (void) L; (void) idx; }
#define repl_freeline(L,b) \
        { (void) L; (void) b; }
#endif /* CHSL_READLINE */


static char *g_libdir = CHSL_LUA_LIBDIR;
static char *g_script = NULL;
static int   g_loglvl = 0;
static int   g_repl   = 0;


static int
traceback (lua_State *L)
{
    const char *msg = lua_tostring (L, 1);
    if (msg)
        luaL_traceback (L, L, msg, 1);
    else if (!lua_isnoneornil (L, 1)) {  /* is there an error object? */
        if (!luaL_callmeta (L, 1, "__tostring"))  /* try its 'tostring' metamethod */
            lua_pushliteral (L, "(no error message)");
    }
    return 1;
}


static int
chisel_lua_init (lua_State *L, int argc, char **argv)
{
    long idx;

    assert (L);

    lua_newtable (L); /*: M */

    /* Set some fields... */
    lua_pushstring (L, g_libdir);
    lua_setfield   (L, -2, "libdir");
    lua_pushstring (L, CHSL_VERSION);
    lua_setfield   (L, -2, "version");
    lua_pushstring (L, g_script);
    lua_setfield   (L, -2, "script");
    lua_pushnumber (L, g_loglvl);
    lua_setfield   (L, -2, "loglevel");
    lua_pushnumber (L, g_repl);
    lua_setfield   (L, -2, "interactive");

    /* Set the "argv" and "options" tables */
    lua_newtable (L); /*: M argv */
    lua_newtable (L); /*: M argv options */

    for (idx = 1; argc-- ; argv++, idx++) {
        lua_pushstring (L, *argv);   /*: M argv options "*argv" */
        lua_rawseti    (L, -3, idx); /*: M argv options */

        char *chr = strchr (*argv, '=');
        if (chr == NULL) {
            lua_pushboolean (L, 1);         /*: M argv options true */
            lua_setfield    (L, -2, *argv); /*: M argv options */
        }
        else {
            lua_pushlstring (L, *argv, chr - *argv); /*: M argv options k */
            lua_pushstring  (L, chr + 1);            /*: M argv options k v */
            lua_settable    (L, -3);                 /*: M argv options */
        }
    }
    lua_setfield (L, -3, "options"); /*: M argv */
    lua_setfield (L, -2, "argv");    /*: M */

    /* Set the global "chisel" table */
    lua_setglobal (L, "chisel");     /*: - */

    lua_pushcfunction (L, traceback);
    if (luaL_loadstring (L, BOOT_SCRIPT) != LUA_OK)
        return luaL_error (L, "Could not compile boot code");
    if (lua_pcall (L, 0, 0, -2) != LUA_OK)
        return luaL_error (L, "Could not initialize, libdir = '%s'\n%s",
                           g_libdir, lua_tostring (L, -1));

    lua_pop (L, 1);
    return 0;
}


/* mark in error messages for incomplete statements */
#define REPL_EOFMARK "<eof>"
#define repl_marklen (sizeof (REPL_EOFMARK) / sizeof(char) - 1)


static int
repl_incomplete (lua_State *L, int status)
{
    if (status == LUA_ERRSYNTAX) {
        size_t lmsg;
        const char *msg = lua_tolstring (L, -1, &lmsg);
        if (lmsg >= repl_marklen && strcmp (msg + lmsg - repl_marklen, REPL_EOFMARK) == 0) {
            lua_pop (L, 1);
            return 1;
        }
    }
    return 0; /* else... */
}


static int
repl_pushline (lua_State *L, int firstline)
{
    char buffer[CHSL_REPL_MAXINPUT];
    char *b = buffer;
    size_t l;

    if (repl_readline (L, b, firstline ? CHSL_REPL_PROMPT1
                                       : CHSL_REPL_PROMPT2) == 0)
        return 0;  /* no input */

    l = strlen (b);
    if (l > 0 && b[l-1] == '\n')  /* line ends with newline? */
        b[l-1] = '\0';  /* remove it */

    /*
     * Add a "return" to the first line, to print the result, but only if
     * it is not already there, and the statement is not an assignment.
     */
    if (firstline && strncmp (b, "return", 6) && !strchr (b, '='))
        lua_pushfstring (L, "return %s", b);
    else
        lua_pushstring (L, b);

    repl_freeline (L, b);
    return 1;
}



static int
repl_loadline (lua_State *L)
{
    int status;

    assert (L);
    lua_settop (L, 0);

    if (!repl_pushline (L, 1))
        return -1; /* no input */

    for (;;) {     /* repeat until gets a complete line */
        size_t l;
        const char *line = lua_tolstring (L, 1, &l);
        status = luaL_loadbuffer (L, line, l, "=stdin");

        if (!repl_incomplete (L, status))
            break; /* cannot try to add lines? */

        if (!repl_pushline (L, 0)) /* no more input? */
            return -1;

        lua_pushliteral (L, "\n"); /* add a new line... */
        lua_insert (L, -2); /* ...between the two lines */
        lua_concat (L, 3);             /* and join them */
    }
    repl_saveline (L, 1);
    lua_remove (L, 1);  /* remove line */
    return status;
}


static int
repl_docall (lua_State *L, int narg, int nres)
{
    int status;
    int base = lua_gettop (L) - narg;      /* function index */
    lua_pushcfunction (L, traceback);      /* push traceback function */
    lua_insert (L, base);                  /* put it under chunk and args */

    /* TODO Handle signals so Ctrl-C gets the user back to a prompt. */
    status = lua_pcall (L, narg, nres, base);

    lua_remove (L, base);                  /* remove traceback function */
    return status;
}



static void
repl (lua_State *L)
{
    int status;
    while ((status = repl_loadline (L)) != -1) {
        if (status == LUA_OK) {
            status = repl_docall (L, 0, LUA_MULTRET);
        }
        if (status == LUA_OK && lua_gettop (L) > 0) {  /* any result to print? */
            luaL_checkstack (L, LUA_MINSTACK, "too many results to print");
            lua_getglobal (L, "print");
            lua_insert (L, 1);
            if (lua_pcall (L, lua_gettop (L) - 1, 0, 0) != LUA_OK) {
                fprintf (stderr,
                         "error calling \"print\" (%s)\n",
                         lua_tostring (L, -1));
                fflush (stderr);
            }
        }
        if (status != LUA_OK) {
            const char *msg = lua_tostring (L, -1);
            if (msg == NULL)
                msg = "(error object is not a string)";
            fprintf (stderr, "%s\n", msg);
            fflush (stderr);
            lua_pop (L, 1);
            /* Do a complete garbage collection cycle on error */
            lua_gc (L, LUA_GCCOLLECT, 0);
        }
    }
    lua_settop (L, 0);  /* clear stack */
    putchar ('\n');
    fflush (stdout);
}


/* Additional, chisel-provided Lua libraries */
extern int lua_fs_open (lua_State*);


static int
lua_main (lua_State *L)
{
    int    argc = (int)    lua_tointeger (L, 1);
    char **argv = (char**) lua_touserdata (L, 2);

    /* Open libraries, pausing the collector during initialization */
    luaL_checkversion (L);
    lua_gc (L, LUA_GCSTOP, 0);
    luaL_openlibs (L);
    chisel_lua_init (L, argc, argv);
    luaL_requiref (L, "fs", lua_fs_open, 1);
    lua_gc (L, LUA_GCRESTART, 0);

    if (g_repl && isatty (STDIN_FILENO)) {
        repl (L);
    }
    else {
        if (luaL_loadfile (L, g_repl ? NULL : g_script) != LUA_OK)
            lua_error (L);
        lua_call (L, 0, 0);
    }

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
                g_repl = 1;
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

    if (!g_repl && find_script ()) {
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

    /*
     * Push remanining option arguments, and do a protected call to
     * lua_main above, which will add them to the Lua environment.
     */
    lua_pushcfunction (L, lua_main);
    lua_pushinteger (L, argc - optind);
    lua_pushlightuserdata (L, argv + optind);

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

