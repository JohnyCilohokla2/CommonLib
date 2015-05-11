-- strict.lua
-- Author: Pazyryk
-- DateCreated: 8/13/2014
--
-- Version history:
-- 0.10 (Aut 16, 2014) Release version
--
--------------------------------------------------------------
--
-- Modified and expanded from http://metalua.luaforge.net/src/lib/strict.lua.html
--
-- Checks uses of undeclared global variables or table keys, which often happens due to typos or logical errors.
--
-- If bTestMainBody = false, then global variables can be declared anywhere in your main body code (i.e., not inside
-- functions) by regular assignment. Even assigning nil will work. Assignment or access to an undeclared global
-- elswhere will cause an error (if bAssert = true) or print ERROR! <source, line#> to Lua.log (if
-- bAssert = false; note that assignment and access will still "work" as in normal lua without strict.lua).
--
-- If bTestMainBody = true, then strict.lua will object to globals defined in main body after this file has been
-- included, ignoring global functions declared in the main body if bSkipFunctionsInMainBody = true or global
-- tables declared in the main body if bSkipTablesInMainBody = true. This is a useful way to implement strict.lua
-- becuase it forces you to declare all of your globals (other than "skipped" types) in one place BEFORE you include
-- this file.
-- 
-- Regardless of settings, a global name can be removed from strict.lua scrutiny anywhere at any time (after this file
-- has been included) by use of Globals("globalName1", "globalName2", "globalName3", ...).
--
-- To work, user must enable the debug library by setting EnableLuaDebugLibrary = 1 in their config.ini file. Otherwise,
-- strict.lua is not operating, though it will do no harm and calls to included utility functions will do nothing safely.
-- 
-- Usage: Add this file to your mod, set VFS = true, and then include it from your mod's main body:
--
-- include("strict.lua")
--
-- Strict enforcement only starts after the include statement above. If bTestMainBody = true, then all your global
-- (non-function) values must be declared before the include. If bTestMainBody = false, then globals can be declared
-- anywhere in the main body of your code (i.e., not in a function) even after the include.
--
-- Tables must be made strict explicitely using MakeTableStrict(table), after which access or assignment to nonexistent
-- keys is a strict.lua violation.
--
-- Adds three funcions:
--	
-- Globals("global1", "g2", "g3", ...) allows user to declare globals after this file is included (regadless of settings)
-- MakeTableStrict(table)
-- PrintStrictLuaErrors() if bAssert = false, this will print all non-redundant strict.lua errors that have occured
-- PrintGlobals() allows user to see all globals and their contents in the current environment
--
--------------------------------------------------------------
-- Settings
--------------------------------------------------------------

local bAssert = false					--if false, print violations and save for later retreval with PrintStrictLuaErrors()
local bPrintUniqueErrorsOnly = true		--print each violation once only
local bTestMainBody = false				--see details above

--the next two matter only if bTestMainBody = true:
local bSkipFunctionsInMainBody = true	--don't object to global functions declared in main body after this file included
local bSkipTablesInMainBody = false		--don't object to global tables declared in main body after this file included

--------------------------------------------------------------
-- strict.lua for Civ5
--------------------------------------------------------------
--these functions safely do nothing if debug library not enabled
function Globals() NKPrint("Called Globals but the debug library is not enabled; set EnableLuaDebugLibrary = 1 in config.ini to use strict.lua") end	
function PrintStrictLuaErrors() NKPrint("Called PrintStrictLuaErrors but the debug library is not enabled; set EnableLuaDebugLibrary = 1 in config.ini to use strict.lua") end
function PrintGlobals() NKPrint("Called PrintGlobals but the debug library is not enabled; set EnableLuaDebugLibrary = 1 in config.ini to use strict.lua") end
function MakeTableStrict() NKPrint("Called MakeTableStrict but the debug library is not enabled; set EnableLuaDebugLibrary = 1 in config.ini to use strict.lua") end

--bail out of this file if debug library not enabled (can't do anything)
if not debug then
    NKPrint("The debug library is not enabled! Set EnableLuaDebugLibrary = 1 in config.ini to use strict.lua.")
    return
end

NKPrint("Setting strict.lua!")

--localized stuff
local getinfo = debug.getinfo
local rawset = debug.getfenv(pairs).rawset	--PM me if you have questions
local strictLuaErrors = {}
local numErrors = 0

--get the environment
local _G = debug.getfenv(Globals)

function MakeTableStrict(table)
    local bEnv = table == _G
    NKPrint("(strict.lua) MakeTableStrict ", table, (bEnv and " --this is the environment" or ""))

    --bail out if table has metatable already
    local mt = getmetatable(table)
    if mt then
        NKPrint("ERROR! MakeTableStrict called for a table that already has a metatable; modify strict.lua if you want this to work")
        return
    end

    --add a metatable
    mt = {}
    setmetatable(table, mt)

    --add a place to remember declared globals (and access attempts to keep print statements usable)
    if bEnv then
        mt.__declared = {}
    end

    --intercept undeclared assignments: table(key) = x, for nonexistent key
    mt.__newindex = function (t, k, v)
        if not (bEnv and mt.__declared[k]) then
            local info = getinfo(2, "S")
            if info.what ~= "C" and (not bEnv or info.what ~= "main" or (bTestMainBody
                    and (not bSkipFunctionsInMainBody or type(v) ~= "function")
                    and (not bSkipTablesInMainBody or type(v) ~= "table")  )) then
                numErrors = numErrors + 1
                info = getinfo(2, "Snl")
                local name = info.name or info.what or "<unknown>"
                local str = "(strict.lua) Assigned to an undeclared " .. (bEnv and "global" or "table key") .. " '" .. k .. "' in " .. name
                if bAssert then
                    error(str)
                else
                    str = str .. " at: \n" .. string.format("  %s: %d", (info.source or "nil"), (info.currentline or "-1"))
                    if not strictLuaErrors[str] then
                        strictLuaErrors[str] = numErrors	--use string as key for easy unique handling, numErrors can be used to sort by first occurance
                        NKPrint("ERROR #" .. numErrors .. "\n" .. str .. "\n")
                    elseif not bPrintUniqueErrorsOnly then
                        NKPrint("ERROR #" .. numErrors .. "\n" .. str .. "\n")
                    end
                end
            end
            if bEnv then
                mt.__declared[k] = true
            end
        end
        rawset(t, k, v)
    end

    --intercept undeclared accesses: x = table(key), for nonexistent key
    mt.__index = function (t, k)
        if not (bEnv and mt.__declared[k]) then
            local info = getinfo(2, "S")
            if info.what ~= "C" then
                numErrors = numErrors + 1
                info = getinfo(2, "Snl")
                local name = info.name or info.what or "<unknown>"
                local str = "(strict.lua) Accessed an undeclared " .. (bEnv and "global" or "table key") .. " '" .. k .. "' in " .. name
                if bAssert then
                    error(str)
                else
                    str = str .. " at: \n" .. string.format("  %s: %d", (info.source or "nil"), (info.currentline or "-1"))
                    if not strictLuaErrors[str] then
                        strictLuaErrors[str] = numErrors	--use string as key for easy unique handling, numErrors can be used to sort by first occurance
                        NKPrint("ERROR #" .. numErrors .. "\n" .. str .. "\n")
                    elseif not bPrintUniqueErrorsOnly then
                        NKPrint("ERROR #" .. numErrors .. "\n" .. str .. "\n")
                    end
                end
            end
        end
        return nil
    end
end

MakeTableStrict(_G)


--------------------------------------------------------------
-- utility functions for user
--------------------------------------------------------------

function Globals(...)	--allows declaration of globals after this file included
    local mt = getmetatable(_G)
    for _, name in pairs({...}) do
        NKPrint("(strict.lua) Global name will be ignored: ", name)
        mt.__declared[name] = true
    end
end

function PrintStrictLuaErrors()
    if bAssert then
        NKPrint("(strict.lua) We don't save errors if bAssert = true; check Lua.log for Runtime Errors")
    elseif numErrors == 0 then
        NKPrint("(strict.lua) There have been no errors")
    else
        NKPrint("(strict.lua) Printing non-redundant errors:")
        local n = 0
        local errors = {}
        for k, v in pairs(strictLuaErrors) do
            n = n + 1
            errors[n] = {v, k}		--v is error first occurance number; k is unique error string
        end
        table.sort(errors, function(a, b) return a[1] < b[1] end)
        for i = 1, n do
            local error = errors[i]
            NKPrint("ERROR #" .. error[1] .. " " .. error[2])
        end
        NKPrint("Total number of strict.lua errors including redundant: " .. numErrors)
    end
end

function PrintGlobals()	--try it!
    local n = 0
    local names = {}
    for k, v in pairs(_G) do
        n = n + 1
        names[n] = k
    end
    table.sort(names)
    for i = 1, n do
        local k = names[i]
        NKPrint (k, _G[k])
    end
end

--this one caused in Fire Tuner, so exclude here
Globals("_cmdr")