    local M = {}

    local module_tables = {}
    
    function M.set(key, value)
        module_tables[key] = value
    end
    
    function M.get(key)
        return module_tables[key]
    end
    
    function M.getall()
        return module_tables
    end

    return M
