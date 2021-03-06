--- set properties table for an existing class.
-- A property P can be fully specified by the class having
-- 'get_P' and 'set_P' methods. If only the setter is specified,
-- then accessing P acesses a private variable '_P'. If no
-- setters are specified, then the class can be notified of any
-- changes by defining an update() method and setting the special field
-- `__update` of `props` to that method.
-- `klass` is a class generated by 'ml.class`
-- `props` property definitions. This assigns each property
-- to a default value.
-- @module ml_properties

local ml = require 'ml'

return function (klass,props)
    local setters,getters,_props,_names,_defs = {},{},{},{},{}
    local rawget = rawget

    local update = props.__update
    props.__update = nil
    for k,t in pairs(props) do
        getters[k] = rawget(klass,'get_'..k)
        if not getters[k] then
            _props['_'..k] = t
            _names[k] = '_'..k
        end
        setters[k] = rawget(klass,'set_'..k)
        if setters[k] then
            _defs[k] = t
        end
    end
    klass._props = props

    -- patch the constructor so it sets property default values
    local kmt = getmetatable(klass)
    local ctor = kmt.__call
    kmt.__call = function(...)
        local newi = klass.__newindex
        klass.__newindex = nil
        local obj = ctor(...)
        ml.import(obj,_props)
        for k,set in pairs(setters) do
            set(obj,_defs[k])
        end
        klass.__newindex = newi
        return obj
    end

    klass.__index = function(t,k)
        local v = rawget(klass,k)
        if v then return v end
        local getter = getters[k]
        if getter then
            return getter(t,k)
        else
            local _name = _names[k]
            if _name then return t[_name]
            else error("unknown readable property: "..k,2)
            end
        end
    end

    klass.__newindex = function(t,k,v)
        local setter = setters[k]
        if setter then
            setter(t,v,k)
        else
            local _name = _names[k]
            if _name then
                t[_name] = v
                if update then update(t,k,v) end
            else error("unknown writeable property: "..k,2)
            end
        end
    end
end
