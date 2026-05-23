local BGDProxies = {}

-- Proxy MUST provide the same public APIs of SpriteConfigManager.FaceInfo java class does, otherwise the game will crash when trying to access missing methods
function BGDProxies.SpriteConfigManager_FaceInfoProxy(face, cursor)
  local proxy = {}

  function proxy:getFaceName()
    return face:getFaceName()
  end

  function proxy:getWidth()
    if face:getWidth() > 1 then
      return cursor:getGarageSize()
    end

    return face:getWidth()
  end

  function proxy:getHeight()
    if face:getHeight() > 1 then
      return cursor:getGarageSize()
    end

    return face:getHeight()
  end

  function proxy:getzLayers()
    return face:getzLayers()
  end

  function proxy:getMasterX()
    return face:getMasterX()
  end

  function proxy:getMasterY()
    return face:getMasterY()
  end

  function proxy:getMasterZ()
    return face:getMasterZ()
  end

  function proxy:isMasterSet()
    return face:isMasterSet()
  end

  function proxy:isMultiSquare()
    return face:isMultiSquare()
  end

  function proxy:getMasterTileInfo()
    return face:getMasterTileInfo()
  end

  function proxy:verifyObject(x, y, z, object)
    return face:verifyObject(x, y, z, object)
  end

  function proxy:getTileInfo(x, y, z)
    local horizontal = face:getWidth() > 1
    local axis = horizontal and x or y
    local originalSize = horizontal
      and face:getWidth()
      or face:getHeight()

    -- LEFT / TOP
    if axis == 0 then
      return face:getTileInfo(
        horizontal and 0 or x,
        horizontal and y or 0,
        z
      )
    end

    -- RIGHT / BOTTOM
    if axis == cursor:getGarageSize() - 1 then
      return face:getTileInfo(
        horizontal and (originalSize - 1) or x,
        horizontal and y or (originalSize - 1),
        z
      )
    end

    -- MIDDLE
    return face:getTileInfo(
      horizontal and 1 or x,
      horizontal and y or 1,
      z
    )
  end

  function proxy:getTileInfoForSprite(tile)
    return face:getTileInfoForSprite(tile)
  end

  return proxy
end

return BGDProxies
