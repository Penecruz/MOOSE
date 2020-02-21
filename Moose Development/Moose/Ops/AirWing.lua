--- **Ops** - Airwing Warehouse.
--
-- **Main Features:**
--
--    * Manage squadrons.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Airwing
-- @image OPS_AirWing.png


--- AIRWING class.
-- @type AIRWING
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string warehousename The name of the warehouse unit/static.
-- @field #table menu Table of menu items.
-- @field #table squadrons Table of squadrons.
-- @field #table missionqueue Mission queue table.
-- @field #table missioncounter Running index counting the added missions.
-- @field #table payloads Playloads for specific aircraft and mission types. 
-- @extends Functional.Warehouse#WAREHOUSE

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\AIRWING_Main.jpg)
--
-- # The AIRWING Concept
--
--
--
-- @field #AIRWING
AIRWING = {
  ClassName      = "AIRWING",
  lid            =   nil,
  warehousename  =   nil,
  menu           =   nil,
  squadrons      =   nil,
  missionqueue   =    {},
  missioncounter =   nil,
  payloads       =    {},
}

--- Squadron data.
-- @type AIRWING.Squadron
-- @field #string name Name of the squadron.
-- @field #table assets Assets of the squadron.
-- @field #table missiontypes Mission types that the squadron can do.
-- @field #string livery Livery of the squadron.
-- @field #table menu The squadron menu entries.
-- @field #string skill Skill of squadron team members.

--- Squadron asset.
-- @type AIRWING.SquadronAsset
-- @field #AIRWING.Missiondata mission The assigned mission.
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flightgroup object.
-- @extends Functional.Warehouse#WAREHOUSE.Assetitem

--- Mission data.
-- @type AIRWING.Missiondata
-- @extends Ops.FlightGroup#FLIGHTGROUP.Mission
-- @field #number MID Mission ID.
-- @field #string squadname Name of the assigned squadron.
-- @field #table assets Assets assigned for this mission.
-- @field #number nassets Number of required assets.

--- Payload data.
-- @type AIRWING.Payload
-- @field #string aircrafttype Type of aircraft, which can use this payload.
-- @field #table missiontypes Mission types for which this payload can be used.
-- @field #table pylons Pylon data extracted for the unit template.
-- @field #number navail Number of available payloads of this type.


--- AIRWING class version.
-- @field #string version
AIRWING.version="0.1.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Add squadrons to warehouse.
-- TODO: Make special request to transfer squadrons to anther airwing (or warehouse).
-- TODO: Build mission queue.
-- TODO: Find way to start missions.
-- TODO: Check if missions are accomplished. 
-- TODO: Paylods as assets.
-- TODO: Cargo as assets.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new AIRWING class object for a specific aircraft carrier unit.
-- @param #AIRWING self
-- @param #string warehousename Name of the warehouse static or unit object representing the warehouse.
-- @param #string airwingname Name of the air wing, e.g. "AIRWING-8".
-- @return #AIRWING self
function AIRWING:New(warehousename, airwingname)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, WAREHOUSE:New(warehousename, airwingname)) -- #AIRWING

  if not self then
    BASE:E(string.format("ERROR: Could not find warehouse %s!", warehousename))
    return nil
  end

  self.warehousename=warehousename

  self.squadrons={}
  
  self.missioncounter=0


  -- Set some string id for output to DCS.log file.
  self.lid=string.format("AIRWING %s | ", airwingname)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "MissionNew",       "*")           -- Add a new mission.  
  self:AddTransition("*",             "MissionRequest",   "*")           -- Add a (mission) request to the warehouse.
  self:AddTransition("*",             "MissionDone",      "*")           -- Mission is over.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the AIRWING. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRWING] Start
  -- @param #AIRWING self

  --- Triggers the FSM event "Start" after a delay. Starts the AIRWING. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRWING] __Start
  -- @param #AIRWING self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the AIRWING and all its event handlers.
  -- @param #AIRWING self

  --- Triggers the FSM event "Stop" after a delay. Stops the AIRWING and all its event handlers.
  -- @function [parent=#AIRWING] __Stop
  -- @param #AIRWING self
  -- @param #number delay Delay in seconds.


  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a squadron to the air wing.
-- @param #AIRWING self
-- @param #string SquadronName Name of the squadron, e.g. "VFA-37".
-- @param #table MissionTypes Table of mission types this squadron is able to perform.
-- @param #string Livery The livery for all added flight group. Default is the livery of the template group.
-- @param #string Skill The skill of all squadron members.
-- @return #AIRWING.Squadron The squadron object.
function AIRWING:AddSquadron(SquadronName, MissionTypes, Livery, Skill)

  local squadron={} --#AIRWING.Squadron

  squadron.name=SquadronName
  squadron.assets={}
  squadron.missiontypes=MissionTypes or {}
  squadron.livery=Livery
  squadron.skill=Skill

  self.squadrons[SquadronName]=squadron
  
  return squadron
end

--- Add a payload to air wing resources.
-- @param #AIRWING self
-- @param #string UnitName Name of the (template) unit from which the payload is extracted.
-- @param #number Npayloads Number of payloads to add to the airwing resources. Default 99 (which should be enough for most scenarios).
-- @param #table MissionTypes Mission types this payload can be used for.
function AIRWING:AddPayload(UnitName, Npayloads, MissionTypes)

    local payload=self:GetPayloadByName(UnitName)
    
    if payload then
    
      -- Payload already exists. Increase the number.
      payload.navail=payload.navail+Npayloads
      
      --TODO: maybe check if mission types given now are different from before.
      
    else
    
      local unit=UNIT:FindByName(UnitName)
      
      if unit then
    
        payload={} --#AIRWING.Payload
        
        payload.navail=Npayloads
        payload.missiontypes=MissionTypes
        payload.aircrafttype=unit:GetTypeName()
        payload.pylons=unit:GetTemplatePylons()
        
        --TODO: maybe add fuel, chaff and gun?
        
        --table.insert(self.payloads, payload)
        self.payloads[UnitName]=payload
        
      end
    
    end

end

--- Add a payload to air wing resources.
-- @param #AIRWING self
-- @param #string UnitName Name of the unit from which the payload was extracted.
-- @return #AIRWING.Payload
function AIRWING:GetPayloadByName(UnitName)
  return self.payloads[UnitName]
end


--- Add flight group(s) to squadron.
-- @param #AIRWING self
-- @param #AIRWING.Squadron SquadronName Name of the squadron.
-- @param Wrapper.Group#GROUP Group The group object.
-- @param #number Ngroups Number of groups to add.
-- @return #AIRWING self
function AIRWING:AddAssetToSquadron(SquadronName, Group, Ngroups)

  local squadron=self:GetSquadron(SquadronName)

  if squadron then
  
    if type(Group)=="string" then
      Group=GROUP:FindByName(Group)
    end
    
    if Group then

      local text=string.format("FF Adding asset %s to squadron %s", Group:GetName(), squadron.name)
      env.info(text)
    
      self:AddAsset(Group, Ngroups, nil, nil, nil, nil, squadron.skill, squadron.livery, squadron.name)
      
    else
      self:E("ERROR: Group does not exist!")
    end
    
  else
    self:E("ERROR: Squadron does not exit!")
  end

  return self
end

--- Get squadron by name.
-- @param #AIRWING self
-- @param #string SquadronName Name of the squadron, e.g. "VFA-37".
-- @return #AIRWING.Squadron Squadron table.
function AIRWING:GetSquadron(SquadronName)
  return self.squadrons[SquadronName]
end



--- Create a CAP mission.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE OrbitCoordinate Where to orbit. Altitude is also taken from the coordinate. 
-- @param #number OrbitSpeed Orbit speed in knots. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @param Core.Zone#ZONE_RADIUS ZoneCAP Circular CAP zone. Detected targets in this zone will be engaged.
-- @param #table TargetTypes Table of target types. Default {"Air"}.
-- @return Ops.FlightGroup#FLIGHTGROUP.MissionCAP The CAP mission table.
function AIRWING:CreateMissionCAP(OrbitCoordinate, OrbitSpeed, Heading, Leg, ZoneCap, TargetTypes)

  local mission=FLIGHTGROUP.CreateMissionCAP(self, OrbitCoordinate, OrbitSpeed, Heading, Leg, ZoneCap, TargetTypes)

  return mission
end

--- Add mission to queue.
-- @param #AIRWING self
-- @param #AIRWING.Missiondata Mission for this group.
-- @param #number Nassets Number of required assets for this mission. Default 1.
-- @param Core.Point#COORDINATE WaypointCoordinate Coordinate of the mission waypoint.
-- @param #string ClockStart Time the mission is started, e.g. "05:00" for 5 am. If specified as a #number, it will be relative (in seconds) to the current mission time. Default is 5 seconds after mission was added.
-- @param #string ClockStop Time the mission is stopped, e.g. "13:00" for 1 pm. If mission could not be started at that time, it will be removed from the queue. If specified as a #number it will be relative (in seconds) to the current mission time.
-- @param #number Prio Priority of the mission, i.e. a number between 1 and 100. Default 50.
-- @param #string Name Mission name. Default "Aerial Refueling #00X", where "#00X" is a running mission counter index starting at "#001".
-- @return #AIRWING.Missiondata The mission table.
function AIRWING:AddMission(Mission, Nassets, WaypointCoordinate, ClockStart, ClockStop, Prio, Name)

  -- TODO: need to check that this call increases the correct mission counter and adds it to the mission queue.
  local mission=FLIGHTGROUP.AddMission(self, Mission, WaypointCoordinate, nil, ClockStart, ClockStop, Prio, Name)
  
  mission.nassets=Nassets or 1

  -- Mission needs the correct MID.
  mission.mid=nil
  mission.MID=self.missioncounter
  
  return mission
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start AIRWING FSM.
-- @param #AIRWING self
function AIRWING:onafterStart(From, Event, To)

  -- Start parent Warehouse.
  self:GetParent(self).onafterStart(self, From, Event, To)

  -- Info.
  self:I(self.lid..string.format("Starting AIRWING v%s %s (%s)", AIRWING.version, self.alias, self.warehousename))

  -- Add F10 radio menu.
  self:_SetMenuCoalition()

  for _,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#AIRWING.Squadron
    self:_AddSquadonMenu(squadron)
  end

  -- Init status updates.
  --self:__AirwingStatus(-1)
end

--- Update status.
-- @param #AIRWING self
function AIRWING:onafterStatus(From, Event, To)

  -- Status of parent Warehouse.
  self:GetParent(self).onafterStatus(self, From, Event, To)

  local fsmstate=self:GetState()
  
  ------------------
  -- Mission Info --
  ------------------
  local text=string.format("Missions Total=%d:", #self.missionqueue)
  for i,_mission in pairs(self.missionqueue) do
    local mission=_mission --#AIRWING.Missiondata
    text=text..string.format("\n[%d] %s: Status=%s, Nassets=%d, Prio=%d, ID=%d (%s)", i, mission.type, mission.status, mission.nassets, mission.prio, mission.MID, mission.name)
  end
  self:I(self.lid..text)

  -------------------
  -- Squadron Info --
  -------------------
  local text="Squadrons:"
  for i,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#AIRWING.Squadron
    
    -- Squadron text
    text=text..string.format("\n* %s", squadron.name)
    
    -- Loop over all assets.
    for j,_asset in pairs(squadron.assets) do
      local asset=_asset --#AIRWING.SquadronAsset
      local assignment=asset.assignment or "none"
      local name=asset.templatename
      local task=asset.mission and asset.mission.name or "none"
      local spawned=tostring(asset.spawned)
      local groupname=asset.spawngroupname
      local group=nil --Wrapper.Group#GROUP
      local typename=asset.unittype
      local fuel=100
      if groupname then
        group=GROUP:FindByName(groupname)
        if group then
          fuel=group:GetFuelMin()
        end
      end
      
      text=text..string.format("\n  -[%d] %s*%d: spawned=%s, mission=%s, fuel=%d", j, typename, asset.nunits, spawned, task, fuel)
      
    end
  end
  self:I(self.lid..text)
  
  --------------
  -- Mission ---
  --------------
  
  -- Get next mission.
  local mission=self:_GetNextMission()

  -- Request mission execution.  
  if mission then
    self:MissionRequest(mission)
  end

  --self:__AirwingStatus(-30)
end

--- Get next mission.
-- @param #AIRWING self
-- @return #AIRWING.Missiondata Next mission or *nil*.
function AIRWING:_GetNextMission()

  -- Number of missions.
  local Nmissions=#self.missionqueue

  -- Treat special cases.
  if Nmissions==0 then
    return nil
  end

  -- Sort results table wrt times they have already been engaged.
  local function _sort(a, b)
    local taskA=a --#AIRWING.Missiondata
    local taskB=b --#AIRWING.Missiondata
    --TODO: probably sort by prio first and then by time as only missions for T>Tstart are executed. That would ensure that the highest prio mission is carried out first!
    return (taskA.Tstart<taskB.Tstart) or (taskA.Tstart==taskB.Tstart and taskA.prio<taskB.prio)
  end
  table.sort(self.missionqueue, _sort)
  
  -- Current time.
  local time=timer.getAbsTime()

  -- Look for first task that is not accomplished.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --#AIRWING.Missiondata
        
    -- Check if airwing can do the mission and gather required assets.
    local can, assets=self:CanMission(mission.type, mission.nassets)
    
    -- Debug output.
    self:T3({self.lid.."Mission check:", MissionStatusScheduled=mission.status==FLIGHTGROUP.MissionStatus.SCHEDULED, TstartPassed=time>=mission.Tstart, CanMission=can, Nassets=#assets})
    
    -- Check that mission is still scheduled, time has passed and enough assets are available.
    if mission.status==FLIGHTGROUP.MissionStatus.SCHEDULED and time>=mission.Tstart and can then
    
      -- TODO: check that mission.assets table is clean.
      mission.assets=mission.assets or {}
    
      -- Assign assets to mission.
      for i=1,mission.nassets do
        local asset=assets[i] --#AIRWING.SquadronAsset
        table.insert(mission.assets, asset)
        asset.mission=mission
      end
      
      return mission
    end
  end

  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "NewAsset" event. Asset is added to the given squadron (asset assignment).
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The asset that has just been added.
-- @param #string assignment The (optional) assignment for the asset.
function AIRWING:onafterNewAsset(From, Event, To, asset, assignment)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterNewAsset(self, From, Event, To, asset, assignment)
  
  -- Get squadron.
  local squad=self:GetSquadron(assignment)  

  if squad then
  
    -- TODO: Check if asset is already part of the squadron. If an asset returns, it will be added again!

    -- Debug text.
    local text=string.format("Adding asset to squadron %s: assignment=%s, type=%s, attribute=%s", squad.name, assignment, asset.unittype, asset.attribute)
    self:I(self.lid..text)
    
    -- Add asset to squadron.
    table.insert(squad.assets, asset)
        
  end
end

--- On after "MissionNew" event.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #AIRWING.Missiondata Mission
function AIRWING:onafterMissionNew(From, Event, To, Mission)
  
  self:I(self.lid..string.format("New mission %s", Mission.name))

end

--- On after "MissionRequest" event. Performs a self request to the warehouse for the mission assets. Sets mission status to ASSIGNED.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #AIRWING.Missiondata Mission The requested mission.
function AIRWING:onafterMissionRequest(From, Event, To, Mission)

  -- Set mission status to ASSIGNED.
  Mission.status=FLIGHTGROUP.MissionStatus.ASSIGNED

  --TODO: Check that mission prio is same as warehouse prio (small=high or the other way around).
  self:AddRequest(self, WAREHOUSE.Descriptor.ASSETLIST, Mission.assets, Mission.nassets, nil, nil, Mission.prio, tostring(Mission.MID))

end

--- On after "Request" event. Spawns the necessary cargo and transport assets.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Queueitem Request Information table of the request.
function AIRWING:onafterRequest(From, Event, To, Request)

  -- Modify the cargo assets.
  local assets=Request.cargoassets
  
  local Mission=self:GetMissionByID(Request.assignment)
  
  if Mission and assets then
  
    for _,_asset in pairs(assets) do
      local asset=_asset --#AIRWING.SquadronAsset
      
      asset.payload=Mission.payload
      
    end
    
  end

  -- Call parent warehouse function after assets have been adjusted.
  self:GetParent(self).onafterRequest(self, From, Event, To, Request)
  
end

--- On after "AssetSpawned" event triggered when an asset group is spawned into the cruel world. Creates a new flightgroup element and adds the mission to the flightgroup queue.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group The group spawned.
-- @param #AIRWING.SquadronAsset asset The asset that was spawned.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request The request of the dead asset.
function AIRWING:onafterAssetSpawned(From, Event, To, group, asset, request)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterAssetSpawned(self, From, Event, To, group, asset, request)
  
  local mid=tonumber(request.assignment)
  
  -- Set mission.
  asset.mission=self:GetMissionByID(mid)
  
end

--- On after "SelfRequest" event.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Set#SET_GROUP groupset The set of asset groups that was delivered to the warehouse itself.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request Pending self request.
function AIRWING:onafterSelfRequest(From, Event, To, groupset, request)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterSelfRequest(self, From, Event, To, groupset, request)
  
  local mid=tonumber(request.assignment)
  
  local mission=self:GetMissionByID(mid)

  
  for _,_asset in pairs(request.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem    
  end
  
  
  for _,_group in pairs(groupset:GetSet()) do
    local group=_group --Wrapper.Group#GROUP
      
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new flight group after an asset was spawned.
-- @param #AIRWING self
-- @param Wrapper.Group#GROUP group The group.
-- @param #AIRWING.SquadronAsset asset The asset.
function AIRWING:_CreateFlightGroup(group, asset)

  -- Create flightgroup.
  local flightgroup=FLIGHTGROUP:New(group:GetName())
  
  asset.flightgroup=flightgroup
  
  flightgroup:SetAirwing(self)
  
  
  --- Check if out of missiles. For A2A missions ==> RTB.
  function flightgroup:OnAfterOutOfMissiles()  
    local airwing=flightgroup:GetAirWing()
    
  end
  
  --- Check if out of missiles. For A2G missions ==> RTB. But need to check A2G missiles, rockets as well.
  function flightgroup:OnAfterOutOfBombs()  
    local airwing=flightgroup:GetAirWing()
  
  end


  --- Mission started.
  function flightgroup:OnAfterMissionStart(From, Event, To, Mission)
    local airwing=flightgroup:GetAirWing()

    -- TODO: Add event? Set mission status!
    --airwing:MissionStart(Mission)
  
  end
  
  --- Flight is DEAD.
  function flightgroup:OnAfterFlightDead(From, Event, To)  
    local airwing=flightgroup:GetAirWing()
    
    -- TODO
    -- Mission failed ==> launch new mission?
    
  end  
  
  -- Add mission to flightgroup queue.
  if asset.mission then
    local Cstart=UTILS.SecondsToClock(asset.mission.Tstart)
    local Cstop=asset.mission.Tstop and UTILS.SecondsToClock(asset.mission.Tstop) or nil
    asset.flightgroup:AddMission(asset.mission, asset.mission.waypointcoord, asset.mission.waypointindex, Cstart, Cstop, asset.mission.name)
  end

end


--- Check if there is a squadron that can execute a given mission type. Optionally, the number of required assets can be specified.
-- @param #AIRWING self
-- @param #AIRWING.Squadron Squadron The Squadron.
-- @param #string MissionType Type of mission.
-- @param #number Nassets Number of required assets for the mission. Use *nil* or 0 for none. Then only the general capability is checked.
-- @return #boolean If true, Squadron can do that type of mission. Available assets are not checked.
-- @return #table Assets that can do the required mission.
function AIRWING:SquadronCanMission(Squadron, MissionType, Nassets)

  local cando=true
  local assets={}

  local gotit=false
  for _,canmission in pairs(Squadron.missiontypes) do
    if canmission==MissionType then
      gotit=true
      break
    end   
  end
  
  if not gotit then
    -- This squad cannot do this mission.
    cando=false
  else

    for _,_asset in pairs(Squadron.assets) do
      local asset=_asset --#AIRWING.SquadronAsset
      
      -- Check if has already a mission assigned.
      if asset.mission==nil then
        table.insert(assets, asset)
      end
      
    end
  
  end
  
  -- Check if required assets are present.
  if Nassets and Nassets > #assets then
    cando=false
  end

  return cando, assets
end

--- Check if assets for a given mission type are available.
-- @param #AIRWING self
-- @param #string MissionType Type of mission.
-- @param #number Nassets Amount of assets required for the mission. Default 1.
-- @return #boolean If true, enough assets are available.
-- @return #table Assets that can do the required mission.
function AIRWING:CanMission(MissionType, Nassets)

  -- Assume we CANNOT and NO assets are available.
  local Can=false
  local Assets={}

  for squadname,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#AIRWING.Squadron

    -- Check if this squadron can.
    local can, assets=self:SquadronCanMission(squadron, MissionType, Nassets)
    
    -- Debug output.
    local text=string.format("Mission=%s, squadron=%s, can=%s, assets=%d/%d", MissionType, squadron.name, tostring(can), #assets, Nassets)
    self:I(self.lid..text)
    
    -- If anyone can, we Can.
    if can then
      Can=true
    end
    
    -- Total number.
    for _,asset in pairs(assets) do
      table.insert(Assets, asset)
    end

  end
  
  return Can, Assets
end


--- Returns the mission for a given mission ID (MID).
-- @param #AIRWING self
-- @param #number mid Mission ID.
-- @return #AIRWING.Missiondata Mission table.
function AIRWING:GetMissionByID(mid)

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --#AIRWING.Missiondata
    
    if mission.MID==tonumber(mid) then
      return mission
    end
    
  end

  --return self.missionqueue[mid]

  return nil
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Menu Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Patrol carrier.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:_SetMenuCoalition()

  -- Get coalition.
  local Coalition=self:GetCoalition()

  -- Init menu table.
  self.menu=self.menu or {}

  -- Init menu coalition table.
  self.menu[Coalition]=self.menu[Coalition] or {}

  -- Shortcut.
  local menu=self.menu[Coalition]

  if self.menusingle then
    -- F10/Skipper/...
    if not menu.AIRWING then
      menu.AIRWING=MENU_COALITION:New(Coalition, "AIRWING")
    end
  else
    -- F10/Skipper/<Carrier Alias>/...
    if not menu.Root then
      menu.Root=MENU_COALITION:New(Coalition, "AIRWING")
    end
    menu.AIRWING=MENU_COALITION:New(Coalition, self.alias, menu.Root)
  end

  -------------------
  -- Squadron Menu --
  -------------------

  menu.Squadron={}
  menu.Squadron.Main= MENU_COALITION:New(Coalition, "Squadrons", menu.AIRWING)

  menu.Warehouse={}
  menu.Warehouse.Main    = MENU_COALITION:New(Coalition, "Warehouse", menu.AIRWING)
  menu.Warehouse.Reports = MENU_COALITION_COMMAND:New(Coalition, "Reports On/Off", menu.Warehouse.Main, self.WarehouseReportsToggle, self)
  menu.Warehouse.Assets  = MENU_COALITION_COMMAND:New(Coalition, "Report Assets",  menu.Warehouse.Main, self.ReportWarehouseStock, self)
  
  menu.ReportSquadrons = MENU_COALITION_COMMAND:New(Coalition, "Report Squadrons",  menu.AIRWING, self.ReportSquadrons, self)

end

--- Report squadron status.
-- @param #AIRWING self
function AIRWING:ReportSquadrons()

  local text="Squadron Report:"
  
  for i,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#AIRWING.Squadron
    
    local name=squadron.name
    
    local nspawned=0
    local nstock=0
    for _,_asset in pairs(squadron.assets) do
      local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
      --env.info(string.format("Asset name=%s", asset.spawngroupname))
      
      local n=asset.nunits
      
      if asset.spawned then
        nspawned=nspawned+n
      else
        nstock=nstock+n
      end
      
    end
    
    text=string.format("\n%s: AC on duty=%d, in stock=%d", name, nspawned, nstock)
    
  end
  
  self:I(self.lid..text)
  MESSAGE:New(text, 10, "AIRWING", true):ToCoalition(self:GetCoalition())

end


--- Add sub menu for this intruder.
-- @param #AIRWING self
-- @param #AIRWING.Squadron squadron The squadron data.
function AIRWING:_AddSquadonMenu(squadron)

  local Coalition=self:GetCoalition()

  local root=self.menu[Coalition].Squadron.Main

  local menu=MENU_COALITION:New(Coalition, squadron.name, root)

  MENU_COALITION_COMMAND:New(Coalition, "Report",    menu, self._ReportSq, self, squadron)
  MENU_COALITION_COMMAND:New(Coalition, "Launch CAP", menu, self._LaunchCAP, self, squadron)

  -- Set menu.
  squadron.menu=menu

end


--- Report squadron status.
-- @param #AIRWING self
-- @param #AIRWING.Squadron squadron The squadron object.
function AIRWING:_ReportSq(squadron)

  local text=string.format("%s: %s assets:", squadron.name, tostring(squadron.categoryname))
  for i,_asset in pairs(squadron.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    text=text..string.format("%d.) ")
  end
end

--- Warehouse reports on/off.
-- @param #AIRWING self
function AIRWING:WarehouseReportsToggle()
  self.Report=not self.Report
  MESSAGE:New(string.format("Warehouse reports are now %s", tostring(self.Report)), 10, "AIRWING", true):ToCoalition(self:GetCoalition())
end


--- Report warehouse stock.
-- @param #AIRWING self
function AIRWING:ReportWarehouseStock()
  local text=self:_GetStockAssetsText(false)
  MESSAGE:New(text, 10, "AIRWING", true):ToCoalition(self:GetCoalition())
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
