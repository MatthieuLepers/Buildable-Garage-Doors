local BGDHelpers = require "BGD_Helpers"
local BGDProxies = require "BGD_Proxies"

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

  function BuildableGarageDoor.Debug(text)
    local player = getPlayer()

    if not player then return end

    player:Say(text)
  end

  local function OverrideCursor(cursor)
    if not cursor then return end
    if cursor.garageDoorOverridden then return end
    cursor.garageDoorOverridden = true

    function cursor:getGarageSize()
      return BuildableGarageDoor.size + 2
    end

    local oldGetFace = cursor.getFace
    function cursor:getFace()
      local originalFace = oldGetFace(self)

      if not originalFace then return nil end

      return BGDProxies.SpriteConfigManager_FaceInfoProxy(originalFace, self)
    end

    local oldSetInfo = cursor.setInfo
    function cursor:setInfo(square, north, sprite, openSprite)
      local spriteObj = getSprite(sprite)

      if not spriteObj then
        return oldSetInfo(self, square, north, sprite, openSprite)
      end

      local props = spriteObj:getProperties()

      if not props or not props:has(IsoPropertyType.GARAGE_DOOR) then
        return oldSetInfo(self, square, north, sprite, openSprite)
      end

      local door = IsoDoor.new(getCell(), square, sprite, north, self)

      door:setName(self.name)
      door:setModData(copyTable(self.modDate))

      local playerObj

      if isServer() then
        playerObj = self.character
      else
        playerObj = getSpecificPlayer(self.player)
      end

      local craftRecipe = self.objectInfo:getRecipe():getCraftRecipe()
      local perk = craftRecipe:getHighestRelevantSkill(playerObj)
      local perkLevel = playerObj:getPerkLevel(perk)

      -- Use at least the minimum required perk level in cheat mode, to avoid zero-health door.
      if playerObj:isBuildCheat() then
        for i = 1, craftRecipe:getRequiredSkillCount() do
          local requiredSkill = craftRecipe:getRequiredSkill(i - 1)
          if (requiredSkill:getPerk() ~= nil) and (requiredSkill:getLevel() > perkLevel) then
            perkLevel = requiredSkill:getLevel()
          end
        end
      end

      local bonusHealth = self.objectInfo:getScript():getBonusHealth();
      local skillBonus = craftRecipe:getHighestRelevantSkillLevel(playerObj) * self.objectInfo:getScript():getSkillBaseHealth();
      local baseHealth = math.max(self.objectInfo:getScript():getHealth(), self.objectInfo:getScript():getSkillBaseHealth());
      -- MULTIPLY BONUS HEALTH
      local bonusHealthMultiplier = getSandboxOptions():getOptionByName("ConstructionBonusPoints"):getValue()
      if bonusHealthMultiplier == 1 then bonusHealth = bonusHealth * 0.5; end
      if bonusHealthMultiplier == 2 then bonusHealth = bonusHealth * 0.7; end
      if bonusHealthMultiplier == 4 then bonusHealth = bonusHealth * 1.3; end
      if bonusHealthMultiplier == 5 then bonusHealth = bonusHealth * 1.5; end
      local totalHealth = baseHealth + bonusHealth + skillBonus;
      door:setHealth(totalHealth)

      if self.objectInfo:getScript() and self.objectInfo:getScript():getParent() then
        local gameEntityScript = self.objectInfo:getScript():getParent();
        local isFirstTimeCreated = true;
        GameEntityFactory.CreateIsoObjectEntity(door, gameEntityScript, isFirstTimeCreated);
      else
        print("[BuildableGarageDoor] ISBuildIsoEntity -> Cannot instance components, script missing.")
      end

      local replacedObjectIndex = -1;
      if self.previousStageObject and self.previousStageObject:getSquare() == square then
        replacedObjectIndex = self.previousStageObject:getSquare():transmitRemoveItemFromSquare(self.previousStageObject);
        self.previousStageObject = nil;
      end

      square:AddSpecialObject(door, replacedObjectIndex);
      buildUtil.checkCorner(square:getX(), square:getY(), square:getZ(), north, door, self);

      door:setExplored(true)

      local result = nil;
      if self.objectInfo:getScript():getOnCreate() then
        local facing = self:getFace():getFaceName()
        local func = self.objectInfo:getScript():getOnCreate()

        result = BaseCraftingLogic.callLuaObject(
          func,
          {
            door = door,
            craftRecipeData = self.buildPanelLogic:getRecipeData(),
            character = playerObj,
            facing = facing,
          }
        )
      end

      square:RecalcAllWithNeighbours(true);
      if result ~= nil then
        if result.objectAlreadyTransmitted then return end

        if (result.replaceObject and result.object ~= nil) then
          result.object:transmitCompleteItemToClients()
        end

        return
      end

      door:transmitCompleteItemToClients()
    end
  end

  Events.OnDoTileBuilding2.Add(function(cursor, bRender, x, y, z, square)
    if not bRender or not BGDHelpers.IsGarageDoorCursor(cursor) then return end

    OverrideCursor(cursor)
  end)

  Events.OnKeyPressed.Add(function(key)
    local player = getPlayer()
    if not player then return end

    local drag = getCell():getDrag(player:getPlayerNum())

    if not BGDHelpers.IsGarageDoorCursor(drag) then return end

    if key == BuildableGarageDoor.increaseSizeKey:getValue() then
      local val = BuildableGarageDoor.size + 1

      BuildableGarageDoor.size = math.min(BuildableGarageDoor.max, val)
    elseif key == BuildableGarageDoor.decreaseSizeKey:getValue() then
      local val = BuildableGarageDoor.size - 1

      BuildableGarageDoor.size = math.max(BuildableGarageDoor.min, val)
    end
  end)
end)
