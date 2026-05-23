local BGDHelpers = {}

function BGDHelpers.IsGarageDoorCursor(cursor)
  if not cursor then return false end
  if not cursor.objectInfo then return false end

  local name = cursor.objectInfo:getName()

  return name and name:find("GarageDoor")
end

return BGDHelpers
