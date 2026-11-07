local BGDProxies = {}

local FaceInfoProxy = {}
FaceInfoProxy.__index = FaceInfoProxy

-- Both references are weak because each proxy holds its cursor as a field.
local faceInfoProxies = setmetatable({}, { __mode = "kv" })

-- Proxy MUST provide the same public APIs of SpriteConfigManager.FaceInfo java class does, otherwise the game will crash when trying to access missing methods
function BGDProxies.SpriteConfigManager_FaceInfoProxy(face, cursor)
  local proxy = faceInfoProxies[cursor]
  if proxy and proxy.face == face then
    return proxy
  end

  proxy = setmetatable({ face = face, cursor = cursor }, FaceInfoProxy)
  faceInfoProxies[cursor] = proxy

  return proxy
end

function FaceInfoProxy:getFaceName()
  return self.face:getFaceName()
end

function FaceInfoProxy:getWidth()
  if self.face:getWidth() > 1 then
    return self.cursor:getGarageSize()
  end

  return self.face:getWidth()
end

function FaceInfoProxy:getHeight()
  if self.face:getHeight() > 1 then
    return self.cursor:getGarageSize()
  end

  return self.face:getHeight()
end

function FaceInfoProxy:getzLayers()
  return self.face:getzLayers()
end

function FaceInfoProxy:getMasterX()
  return self.face:getMasterX()
end

function FaceInfoProxy:getMasterY()
  return self.face:getMasterY()
end

function FaceInfoProxy:getMasterZ()
  return self.face:getMasterZ()
end

function FaceInfoProxy:isMasterSet()
  return self.face:isMasterSet()
end

function FaceInfoProxy:isMultiSquare()
  return self.face:isMultiSquare()
end

function FaceInfoProxy:getMasterTileInfo()
  return self.face:getMasterTileInfo()
end

function FaceInfoProxy:verifyObject(x, y, z, object)
  return self.face:verifyObject(x, y, z, object)
end

function FaceInfoProxy:getTileInfo(x, y, z)
  local horizontal = self.face:getWidth() > 1
  local axis = horizontal and x or y
  local originalSize = horizontal
    and self.face:getWidth()
    or self.face:getHeight()

  -- LEFT / TOP
  if axis == 0 then
    return self.face:getTileInfo(
      horizontal and 0 or x,
      horizontal and y or 0,
      z
    )
  end

  -- RIGHT / BOTTOM
  if axis == self.cursor:getGarageSize() - 1 then
    return self.face:getTileInfo(
      horizontal and (originalSize - 1) or x,
      horizontal and y or (originalSize - 1),
      z
    )
  end

  -- MIDDLE
  return self.face:getTileInfo(
    horizontal and 1 or x,
    horizontal and y or 1,
    z
  )
end

function FaceInfoProxy:getTileInfoForSprite(tile)
  return self.face:getTileInfoForSprite(tile)
end

return BGDProxies
