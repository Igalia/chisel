/***
File system utilities.

@module fs

@copyright 2012 Adrian Perez <aperez@igalia.com>
@license Distributed under terms of the MIT license.
*/

#include "../lua/lua.h"
#include "../lua/lauxlib.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/dir.h>
#include <unistd.h>
#include <string.h>
#include <assert.h>
#include <errno.h>


static int
fs_push_error (lua_State *L, const char *message)
{
    int err = errno;

    assert (L);

    lua_pushnil (L);
    if (message)
        lua_pushfstring (L, "%s: %s", message, strerror (err));
    else
        lua_pushstring (L, strerror (err));
    lua_pushinteger (L, err);

    return 3;
}


/***
Lists the items in a directory.

If no argument is given, the current directory is listed. Returns a
list of strings and a number with the number of elements in the list.

@function listdir
@param path Path to the directory (optional).
@return List and count of elements in the list.
*/
static int
fs_listdir (lua_State *L)
{
    struct dirent *de;
    const char *path;
    long idx;
    DIR *d;

    assert (L);

    path = luaL_optstring (L, 1, ".");
    if ((d = opendir (path)) == NULL)
        return fs_push_error (L, path);

    lua_newtable (L);
    for (idx = 1; (de = readdir (d)) != NULL; idx++) {
        lua_pushstring (L, de->d_name);
        lua_rawseti (L, -2, idx);
    }

    closedir (d);
    lua_pushinteger (L, idx - 1);
    return 2;
}


/***
Checks whether a file exists.

@function exists
@param path Path to the file.
@return Whether the file exists.
*/
static int
fs_exists (lua_State *L)
{
    const char *path;
    struct stat sb;

    assert (L);

    path = luaL_checkstring (L, 1);

    if (lstat (path, &sb) == 0)
        lua_pushboolean (L, 1);
    else if (errno == ENOENT)
        lua_pushboolean (L, 0);
    else
        return fs_push_error (L, path);

    return 1;
}


static const luaL_Reg fs_funcs[] =
{
#define REG_ITEM(_name)  { #_name, fs_ ## _name }
    REG_ITEM (listdir),
    REG_ITEM (exists),
#undef REG_ITEM
    { NULL, NULL }
};


int
lua_fs_open (lua_State *L)
{
    assert (L);
    luaL_newlib (L, fs_funcs);
    return 1;
}

