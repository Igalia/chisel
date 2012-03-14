/***
(Non-comprehensive) Binding for the CUPS libraries.

@module cups

@copyright 2012 Adrian Perez <aperez@igalia.com>
@license Distributed under terms of the MIT license.
*/

#include "../lua/lua.h"
#include "../lua/lauxlib.h"
#include <cups/sidechannel.h>
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
@return The IEEE-1284 device identifier for the output device, as a string.
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


static const luaL_Reg cups_funcs[] =
{
    { "get_device_id", cups_get_device_id },
    { NULL, NULL }
};


int
lua_cups_open (lua_State *L)
{
    assert (L);
    luaL_newlib (L, cups_funcs);
    return 1;
}

