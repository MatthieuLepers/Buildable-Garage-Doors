local BGDHelpers = require "BGD_Helpers"

Events.OnInitGlobalModData.Add(function()
  local BuildableGarageDoor = {}

  local options = PZAPI.ModOptions:create("BuildableGarageDoors", "Buildable Garage Doors")

  BuildableGarageDoor.size = 1
  BuildableGarageDoor.min = 0
  BuildableGarageDoor.max = (SandboxVars.BuildableGarageDoor.MaxSize or 5) - 2
  BuildableGarageDoor.increaseSizeKey = options:addKeyBind(
    "BuildableGarageDoors_IncreaseSizeKey",
    getText("UI_BuildableGarageDoors_IncreaseSizeKey"),
    Keyboard.KEY_UP
  )
  BuildableGarageDoor.decreaseSizeKey = options:addKeyBind(
    "BuildableGarageDoors_DecreaseSizeKey",
    getText("UI_BuildableGarageDoors_DecreaseSizeKey"),
    Keyboard.KEY_DOWN
  )

  Events.OnDoTileBuilding2.Add(function(cursor, bRender, x, y, z, square)
    if not bRender or not BGDHelpers.IsGarageDoorCursor(cursor) then return end

    if not cursor then return end
    cursor:setGarageSize(BuildableGarageDoor.size)
  end)

  Events.OnKeyPressed.Add(function(key)
    local player = getPlayer()
    if not player then return end

    local drag = getCell():getDrag(player:getPlayerNum())

    if not BGDHelpers.IsGarageDoorCursor(drag) then return end

    if key == BuildableGarageDoor.increaseSizeKey:getValue() then
      local val = BuildableGarageDoor.size + 1

      BuildableGarageDoor.size = math.min(BuildableGarageDoor.max, val)
      drag:setGarageSize(BuildableGarageDoor.size)
    elseif key == BuildableGarageDoor.decreaseSizeKey:getValue() then
      local val = BuildableGarageDoor.size - 1

      BuildableGarageDoor.size = math.max(BuildableGarageDoor.min, val)
      drag:setGarageSize(BuildableGarageDoor.size)
    end
  end)
end)
