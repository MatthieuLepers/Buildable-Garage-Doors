local BGDHelpers = require "BGD_Helpers"
local BGDProxies = require "BGD_Proxies"

Events.OnInitGlobalModData.Add(function()
  if BGD_ISBUILD_PATCHED then return end
  BGD_ISBUILD_PATCHED = true

  -- setInfo override
  local BGD_oldSetInfo = ISBuildIsoEntity.setInfo

  local function BGD_setInfoOverride(self, square, north, sprite, openSprite)
    local spriteObj = getSprite(sprite)
    if not spriteObj then
      return BGD_oldSetInfo(self, square, north, sprite, openSprite)
    end

    local props = spriteObj:getProperties()
    if not props or not props:has(IsoPropertyType.GARAGE_DOOR) then
      return BGD_oldSetInfo(self, square, north, sprite, openSprite)
    end

    local door = IsoDoor.new(getCell(), square, sprite, north, self)

    door:setName(self.name)
    door:setModData(copyTable(self.modData))

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

      if (result.replaceObject and result.object ~= nil) and isServer() then
        result.object:transmitCompleteItemToClients()
      end

      return
    end

    if isServer() then
      door:transmitCompleteItemToClients()
    end
  end

  function ISBuildIsoEntity:setInfo(square, north, sprite, openSprite)
    local spriteObj = getSprite(sprite)

    if not spriteObj then
      return BGD_oldSetInfo(self, square, north, sprite, openSprite)
    end

    local props = spriteObj:getProperties()
    if not props or not props:has(IsoPropertyType.GARAGE_DOOR) then
      return BGD_oldSetInfo(self, square, north, sprite, openSprite)
    end

    return BGD_setInfoOverride(self, square, north, sprite, openSprite)
  end

  -- getGarageSize new method
  function ISBuildIsoEntity:getGarageSize()
    local modData = self.modData or {}
    return modData.BGDGarageDoorSize or 1
  end

  -- setGarageSize new method
  function ISBuildIsoEntity:setGarageSize(size)
    -- Middle tile size validation
    local min = 0
    local max = (SandboxVars.BuildableGarageDoor.MaxSize or 5) - 2
    local sanitizedSize = math.min(max, math.max(min, size))

    local modData = self.modData or {}
    modData.BGDGarageDoorSize = sanitizedSize + 2 -- adding 2 to add left and right tiles
    self.modData = modData
  end

  -- getFace override as proxy
  local BGD_oldGetFace = ISBuildIsoEntity.getFace
  function ISBuildIsoEntity:getFace()
    if not BGDHelpers.IsGarageDoorCursor(self) then
      return BGD_oldGetFace(self)
    end

    local originalFace = BGD_oldGetFace(self)
    if not originalFace then return nil end

    return BGDProxies.SpriteConfigManager_FaceInfoProxy(originalFace, self)
  end
end)
