/* LÖVE for Android's LuaJIT doesn't export luaL_setfuncs, which LuaJIT 2.1's luaL_newlib expands to.
   Built with -DluaL_setfuncs=bc_luaL_setfuncs so the module uses this copy. */
#include "lua.h"
#include "lauxlib.h"

void luaL_setfuncs(lua_State *L, const luaL_Reg *l, int nup)
{
	luaL_checkstack(L, nup, "too many upvalues");
	for (; l->name; l++) {
		int i;
		for (i = 0; i < nup; i++)
			lua_pushvalue(L, -nup);
		lua_pushcclosure(L, l->func, nup);
		lua_setfield(L, -(nup + 2), l->name);
	}
	lua_pop(L, nup);
}
