
----------------------------

local function load(filename)

    local imgid = nil
    --print(gltfobj.basepath..v.uri)
    local res, err = image.load(sys.load_resource( filename ))
    if(err) then print("[Image Load Error]: "..v.uri.." #:"..err) end 

    -- TODO: This goes into image loader
    if(res.buffer ~= "") then
        rgbcount = 3
        if(res.type == "rgba") then res.format = resource.TEXTURE_FORMAT_RGBA; rgbcount = 4 end
        if(res.type == "rgb") then res.format = resource.TEXTURE_FORMAT_RGB; rgbcount = 3 end

        imgid = nuklear.create_image(res.width, res.height, rgbcount, res.buffer)    
        -- print(string.format("w: %d  h: %d  color: %d", res.width, res.height, rgbcount) )
    end

    return imgid
end


----------------------------

local function loadbuffer(filename)

    local imgid = nil
    local data = nil

    local fh = io.open(filename, "rb")
    if(fh) then 
        data = fh:read("*a")
        fh:close()
    else 
        print("[Error] loadbuffer: Unable to load - "..filename)
        return nil
    end
           
    --print(gltfobj.basepath..v.uri)
    local res, err = image.load(data)
    if(err) then print("[Image Load Error]: "..v.uri.." #:"..err) end 

    -- TODO: This goes into image loader
    if(res.buffer ~= "") then
        rgbcount = 3
        if(res.type == "rgba") then res.format = resource.TEXTURE_FORMAT_RGBA; rgbcount = 4 end
        if(res.type == "rgb") then res.format = resource.TEXTURE_FORMAT_RGB; rgbcount = 3 end

        imgid = nuklear.create_image(res.width, res.height, rgbcount, res.buffer)    
        -- print(string.format("w: %d  h: %d  color: %d", res.width, res.height, rgbcount) )
    end

    return imgid
end


----------------------------

return {
    load = load,
}

----------------------------