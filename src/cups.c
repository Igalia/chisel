/***
(Non-comprehensive) Binding for the CUPS libraries.

@module cups

@copyright 2012 Adrian Perez <aperez@igalia.com>
@license Distributed under terms of the MIT license.
*/

#include "../lua/lua.h"
#include "../lua/lauxlib.h"
#include <cups/sidechannel.h>
#include <cups/cups.h>
#include <assert.h>

#define IEEE1284_ID_LENGTH 512


static int
cups_push_error (lua_State *L, cups_sc_status_t status)
{
    assert (L);

    lua_pushnil (L);

    switch (status) {
#define ITEM(x) case x : lua_pushstring (L, #x); break
        ITEM (CUPS_SC_STATUS_NOT_IMPLEMENTED);
        ITEM (CUPS_SC_STATUS_NO_RESPONSE);
        ITEM (CUPS_SC_STATUS_BAD_MESSAGE);
        ITEM (CUPS_SC_STATUS_IO_ERROR);
        ITEM (CUPS_SC_STATUS_TIMEOUT);
        ITEM (CUPS_SC_STATUS_TOO_BIG);
        ITEM (CUPS_SC_STATUS_NONE);
        ITEM (CUPS_SC_STATUS_OK);
#undef ITEM
    }

    return 2;
}


/***
Obtains the IEEE-1284 device identifier for the current output device.

@return The IEEE-1284 device identifier, as a string.
@function cups.get_device_id
*/
static int
cups_get_device_id (lua_State *L)
{
    char buffer[IEEE1284_ID_LENGTH];
    int buflen = IEEE1284_ID_LENGTH;
    cups_sc_status_t status;

    assert (L);

    if ((status = cupsSideChannelDoRequest (CUPS_SC_CMD_GET_DEVICE_ID,
                                            buffer,
                                            &buflen,
                                            0.0)) != CUPS_SC_STATUS_OK)
        return cups_push_error (L, status);

    lua_pushlstring (L, buffer, buflen);
    return 1;
}


/***
Obtains the name of the default printer.

@return Name of the default printer (string), or `nil` if there is no default.
@function cups.get_default
*/
int
cups_get_default (lua_State *L)
{
    const char *destname = NULL;
    cups_dest_t *destinations;
    int nitems = cupsGetDests (&destinations);
    int i;

    for (i = 0; i < nitems; i++) {
        if (destinations[i].is_default) {
            destname = destinations[i].name;
            break;
        }
    }

    if (!destname)
        destname = cupsGetDefault ();

    if (destname)
        lua_pushstring (L, destname);
    else
        lua_pushnil (L);

    cupsFreeDests (nitems, destinations);
    return 1;
}


/***
Obtains the PPD file for a printer given its name.

@param printername Name of the printer. If not given, the default
printer is used.

@return File name for the PPD file. Once the file is no longer needed,
it should be removed.

@function cups.get_ppd
*/
static int
cups_get_ppd (lua_State *L)
{
    const char *printername;
    assert (L);

    if (!(printername = luaL_optstring (L, 1, NULL))) {
        cups_get_default (L);
        printername = lua_tostring (L, -1);
    }

    lua_pushstring (L, cupsGetPPD (printername));
    return 1;
}


static void
push_opts (lua_State *L, int nitems, const cups_option_t *options)
{
    int i;

    assert (L);
    assert (options);

    lua_newtable (L); /*: opts */
    for (i = 0; i < nitems; i++) {
        lua_pushstring (L, options[i].value);  /*: opts value */
        lua_setfield (L, -2, options[i].name); /*: opts */
    }
}


static void
push_dest (lua_State *L, const cups_dest_t *dest)
{
    assert (L);
    assert (dest);

    lua_newtable (L); /*: dest */

    /* Destination name */
    lua_pushstring  (L, dest->name); /*: dest name */
    lua_setfield    (L, -2, "name"); /*: dest */

    /* Default printer? */
    lua_pushboolean (L, dest->is_default); /*: dest is_default */
    lua_setfield    (L, -2, "is_default"); /*: dest */

    /* Options */
    push_opts (L, dest->num_options, dest->options); /*: dest opts */
    lua_setfield (L, -2, "options");                 /*: dest */
}


/***
Obtains all possible destinations supported by CUPS and their attributes.

@return Table with names of destinations as keys, and a table describing
the destination as value.

@function cups.get_destinations
*/
static int
cups_get_destinations (lua_State *L)
{
    cups_dest_t *destinations = NULL;
    int nitems = cupsGetDests (&destinations);
    int i;

    lua_newtable (L); /*: dests */
    for (i = 0; i < nitems; i++) {
        push_dest (L, &destinations[i]);            /*: dests dest */
        lua_setfield (L, -2, destinations[i].name); /*: dests */
    }
    cupsFreeDests (nitems, destinations);

    return 1;
}


static const luaL_Reg cups_funcs[] =
{
    { "get_destinations", cups_get_destinations },
    { "get_device_id",    cups_get_device_id    },
    { "get_default",      cups_get_default      },
    { "get_ppd",          cups_get_ppd          },
    { NULL, NULL }
};


int
lua_cups_open (lua_State *L)
{
    assert (L);
    luaL_newlib (L, cups_funcs);
    return 1;
}

