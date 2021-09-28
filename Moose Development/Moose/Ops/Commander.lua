--- **Ops** - Commander of Airwings, Brigades and Flotillas.
--
-- **Main Features:**
--
--    * Manages AIRWINGS, BRIGADEs and FLOTILLAs
--    * Handles missions (AUFTRAG) and finds the best man for the job 
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Commander
-- @image OPS_Commander.png


--- COMMANDER class.
-- @type COMMANDER
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table legions Table of legions which are commanded.
-- @field #table missionqueue Mission queue.
-- @field #table transportqueue Transport queue.
-- @field #table rearmingZones Rearming zones. Each element is of type `#BRIGADE.SupplyZone`.
-- @field #table refuellingZones Refuelling zones. Each element is of type `#BRIGADE.SupplyZone`.
-- @field Ops.Chief#CHIEF chief Chief of staff.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- # The COMMANDER Concept
-- 
-- A commander is the head of legions. He/she will find the best LEGIONs to perform an assigned AUFTRAG (mission).
--
--
-- @field #COMMANDER
COMMANDER = {
  ClassName       = "COMMANDER",
  verbose         =     0,
  legions         =    {},
  missionqueue    =    {},
  transportqueue  =    {},
  rearmingZones   =    {},
  refuellingZones =    {},
}

--- COMMANDER class version.
-- @field #string version
COMMANDER.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Improve legion selection. Mostly done!
-- TODO: Find solution for missions, which require a transport. This is not as easy as it sounds since the selected mission assets restrict the possible transport assets.
-- TODO: Add ops transports.
-- DONE: Allow multiple Legions for one mission.
-- NOGO: Maybe it's possible to preselect the assets for the mission.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new COMMANDER object and start the FSM.
-- @param #COMMANDER self
-- @return #COMMANDER self
function COMMANDER:New()

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, FSM:New()) --#COMMANDER
  
  -- Log ID.
  self.lid="COMMANDER | "

  -- Start state.
  self:SetStartState("NotReadyYet")

  -- Add FSM transitions.
  --                 From State     -->      Event        -->     To State
  self:AddTransition("NotReadyYet",        "Start",               "OnDuty")      -- Start COMMANDER.
  self:AddTransition("*",                  "Status",              "*")           -- Status report.
  self:AddTransition("*",                  "Stop",                "Stopped")     -- Stop COMMANDER.
  
  self:AddTransition("*",                  "MissionAssign",       "*")           -- Mission is assigned to a or multiple LEGIONs.
  self:AddTransition("*",                  "MissionCancel",       "*")           -- COMMANDER cancels a mission.

  self:AddTransition("*",                  "TransportAssign",     "*")           -- Transport is assigned to a or multiple LEGIONs.
  self:AddTransition("*",                  "TransportCancel",     "*")           -- COMMANDER cancels a Transport.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the COMMANDER.
  -- @function [parent=#COMMANDER] Start
  -- @param #COMMANDER self

  --- Triggers the FSM event "Start" after a delay. Starts the COMMANDER.
  -- @function [parent=#COMMANDER] __Start
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop". Stops the COMMANDER.
  -- @param #COMMANDER self

  --- Triggers the FSM event "Stop" after a delay. Stops the COMMANDER.
  -- @function [parent=#COMMANDER] __Stop
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Status".
  -- @function [parent=#COMMANDER] Status
  -- @param #COMMANDER self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#COMMANDER] __Status
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "MissionAssign". Mission is added to a LEGION mission queue and already requested. Needs assets to be added to the mission!
  -- @function [parent=#COMMANDER] MissionAssign
  -- @param #COMMANDER self
  -- @param Ops.Legion#LEGION Legion The Legion.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionAssign" after a delay. Mission is added to a LEGION mission queue and already requested. Needs assets to be added to the mission!
  -- @function [parent=#COMMANDER] __MissionAssign
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Legion#LEGION Legion The Legion.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionAssign" event.
  -- @function [parent=#COMMANDER] OnAfterMissionAssign
  -- @param #COMMANDER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Legion#LEGION Legion The Legion.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "MissionCancel".
  -- @function [parent=#COMMANDER] MissionCancel
  -- @param #COMMANDER self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionCancel" after a delay.
  -- @function [parent=#COMMANDER] __MissionCancel
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionCancel" event.
  -- @function [parent=#COMMANDER] OnAfterMissionCancel
  -- @param #COMMANDER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "TransportAssign".
  -- @function [parent=#COMMANDER] TransportAssign
  -- @param #COMMANDER self
  -- @param Ops.Legion#LEGION Legion The Legion.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- Triggers the FSM event "TransportAssign" after a delay.
  -- @function [parent=#COMMANDER] __TransportAssign
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Legion#LEGION Legion The Legion.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- On after "TransportAssign" event.
  -- @function [parent=#COMMANDER] OnAfterTransportAssign
  -- @param #COMMANDER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Legion#LEGION Legion The Legion.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.


  --- Triggers the FSM event "TransportCancel".
  -- @function [parent=#COMMANDER] TransportCancel
  -- @param #COMMANDER self
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- Triggers the FSM event "TransportCancel" after a delay.
  -- @function [parent=#COMMANDER] __TransportCancel
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- On after "TransportCancel" event.
  -- @function [parent=#COMMANDER] OnAfterTransportCancel
  -- @param #COMMANDER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set verbosity level.
-- @param #COMMANDER self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #COMMANDER self
function COMMANDER:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Add an AIRWING to the commander.
-- @param #COMMANDER self
-- @param Ops.AirWing#AIRWING Airwing The airwing to add.
-- @return #COMMANDER self
function COMMANDER:AddAirwing(Airwing)

  -- Add legion.
  self:AddLegion(Airwing)
  
  return self
end

--- Add an BRIGADE to the commander.
-- @param #COMMANDER self
-- @param Ops.Brigade#BRIGADE Brigade The brigade to add.
-- @return #COMMANDER self
function COMMANDER:AddBrigade(Brigade)

  -- Add legion.
  self:AddLegion(Brigade)
  
  return self
end

--- Add a LEGION to the commander.
-- @param #COMMANDER self
-- @param Ops.Legion#LEGION Legion The legion to add.
-- @return #COMMANDER self
function COMMANDER:AddLegion(Legion)

  -- This legion is managed by the commander. 
  Legion.commander=self

  -- Add to legions.
  table.insert(self.legions, Legion)  
  
  return self
end

--- Add mission to mission queue.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be added.
-- @return #COMMANDER self
function COMMANDER:AddMission(Mission)

  Mission.commander=self
  
  Mission.statusCommander=AUFTRAG.Status.PLANNED

  table.insert(self.missionqueue, Mission)

  return self
end

--- Add transport to queue.
-- @param #COMMANDER self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The OPS transport to be added.
-- @return #COMMANDER self
function COMMANDER:AddOpsTransport(Transport)

  Transport.commander=self
  
  Transport.statusCommander=TRANSPORT.Status.PLANNED

  table.insert(self.transportqueue, Transport)

  return self
end

--- Remove mission from queue.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #COMMANDER self
function COMMANDER:RemoveMission(Mission)

  for i,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission.auftragsnummer==Mission.auftragsnummer then
      self:I(self.lid..string.format("Removing mission %s (%s) status=%s from queue", Mission.name, Mission.type, Mission.status))
      mission.commander=nil
      table.remove(self.missionqueue, i)
      break
    end
    
  end

  return self
end

--- Remove transport from queue.
-- @param #COMMANDER self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The OPS transport to be removed.
-- @return #COMMANDER self
function COMMANDER:RemoveTransport(Transport)

  for i,_transport in pairs(self.transportqueue) do
    local transport=_transport --Ops.OpsTransport#OPSTRANSPORT
    
    if transport.uid==Transport.uid then
      self:I(self.lid..string.format("Removing mission %s (%s) status=%s from queue", transport.uid, transport:GetState()))
      transport.commander=nil
      table.remove(self.transportqueue, i)
      break
    end
    
  end

  return self
end

--- Add a rearming zone.
-- @param #COMMANDER self
-- @param Core.Zone#ZONE RearmingZone Rearming zone.
-- @return Ops.Brigade#BRIGADE.SupplyZone The rearming zone data.
function COMMANDER:AddRearmingZone(RearmingZone)

  local rearmingzone={} --Ops.Brigade#BRIGADE.SupplyZone
  
  rearmingzone.zone=RearmingZone
  rearmingzone.mission=nil
  rearmingzone.marker=MARKER:New(rearmingzone.zone:GetCoordinate(), "Rearming Zone"):ToCoalition(self:GetCoalition())

  table.insert(self.rearmingZones, rearmingzone)

  return rearmingzone
end

--- Add a refuelling zone.
-- @param #COMMANDER self
-- @param Core.Zone#ZONE RefuellingZone Refuelling zone.
-- @return Ops.Brigade#BRIGADE.SupplyZone The refuelling zone data.
function COMMANDER:AddRefuellingZone(RefuellingZone)

  local rearmingzone={} --Ops.Brigade#BRIGADE.SupplyZone
  
  rearmingzone.zone=RefuellingZone
  rearmingzone.mission=nil
  rearmingzone.marker=MARKER:New(rearmingzone.zone:GetCoordinate(), "Refuelling Zone"):ToCoalition(self:GetCoalition())

  table.insert(self.refuellingZones, rearmingzone)

  return rearmingzone
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #COMMANDER self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function COMMANDER:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting Commander")
  self:I(self.lid..text)
  
  -- Start attached legions.
  for _,_legion in pairs(self.legions) do
    local legion=_legion --Ops.Legion#LEGION
    if legion:GetState()=="NotReadyYet" then
      legion:Start()
    end
  end

  self:__Status(-1)
end

--- On after "Status" event.
-- @param #COMMANDER self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function COMMANDER:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()

  -- Status.
  if self.verbose>=1 then
    local text=string.format("Status %s: Legions=%d, Missions=%d, Transports", fsmstate, #self.legions, #self.missionqueue, #self.transportqueue)
    self:I(self.lid..text)
  end

  -- Check mission queue and assign one PLANNED mission.
  self:CheckMissionQueue()
  
  -- Check transport queue and assign one PLANNED transport.
  self:CheckTransportQueue()
  
  -- Check rearming zones.
  for _,_rearmingzone in pairs(self.rearmingZones) do
    local rearmingzone=_rearmingzone --#BRIGADE.SupplyZone
    -- Check if mission is nil or over.      
    if (not rearmingzone.mission) or rearmingzone.mission:IsOver() then
      rearmingzone.mission=AUFTRAG:NewAMMOSUPPLY(rearmingzone.zone)
      self:AddMission(rearmingzone.mission)
    end
  end
  
  -- Check refuelling zones.
  for _,_supplyzone in pairs(self.refuellingZones) do
    local supplyzone=_supplyzone --#BRIGADE.SupplyZone
    -- Check if mission is nil or over.      
    if (not supplyzone.mission) or supplyzone.mission:IsOver() then
      supplyzone.mission=AUFTRAG:NewFUELSUPPLY(supplyzone.zone)
      self:AddMission(supplyzone.mission)
    end
  end    
    
  ---
  -- LEGIONS
  ---
 
  if self.verbose>=2 and #self.legions>0 then
  
    local text="Legions:"
    for _,_legion in pairs(self.legions) do
      local legion=_legion --Ops.Legion#LEGION
      local Nassets=legion:CountAssets()
      local Nastock=legion:CountAssets(true)
      text=text..string.format("\n* %s [%s]: Assets=%s stock=%s", legion.alias, legion:GetState(), Nassets, Nastock)
      for _,aname in pairs(AUFTRAG.Type) do
        local na=legion:CountAssets(true, {aname})
        local np=legion:CountPayloadsInStock({aname})
        local nm=legion:CountAssetsOnMission({aname})
        if na>0 or np>0 then
          text=text..string.format("\n   - %s: assets=%d, payloads=%d, on mission=%d", aname, na, np, nm)
        end
      end            
    end
    self:I(self.lid..text)
    
    
    if self.verbose>=3 then
    
      -- Count numbers
      local Ntotal=0
      local Nspawned=0
      local Nrequested=0
      local Nreserved=0
      local Nstock=0
      
      local text="\n===========================================\n"
      text=text.."Assets:"
      for _,_legion in pairs(self.legions) do
        local legion=_legion --Ops.Legion#LEGION
  
        for _,_cohort in pairs(legion.cohorts) do
          local cohort=_cohort --Ops.Cohort#COHORT
          
          for _,_asset in pairs(cohort.assets) do
            local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem

            local state="In Stock"
            if asset.flightgroup then
              state=asset.flightgroup:GetState()
              local mission=legion:GetAssetCurrentMission(asset)
              if mission then
                state=state..string.format("Mission %s [%s]", mission:GetName(), mission:GetType())
              end
            else
              if asset.spawned then
                env.info("FF ERROR: asset has opsgroup but is NOT spawned!")
              end
              if asset.requested and asset.isReserved then
                env.info("FF ERROR: asset is requested and reserved. Should not be both!")
                state="Reserved+Requested!"
              elseif asset.isReserved then
                state="Reserved"
              elseif asset.requested then
                state="Requested"
              end
            end
                        
            -- Text.
            text=text..string.format("\n[UID=%03d] %s Legion=%s [%s]: State=%s [RID=%s]", 
            asset.uid, asset.spawngroupname, legion.alias, cohort.name, state, tostring(asset.rid))
            
            
            if asset.spawned then
              Nspawned=Nspawned+1
            end            
            if asset.requested then
              Nrequested=Nrequested+1
            end  
            if asset.isReserved then
              Nreserved=Nreserved+1
            end                      
            if not (asset.spawned or asset.requested or asset.isReserved) then
              Nstock=Nstock+1
            end
            
            Ntotal=Ntotal+1
            
          end
          
        end
  
      end
      text=text.."\n-------------------------------------------"
      text=text..string.format("\nNstock     = %d", Nstock)
      text=text..string.format("\nNreserved  = %d", Nreserved)
      text=text..string.format("\nNrequested = %d", Nrequested)
      text=text..string.format("\nNspawned   = %d", Nspawned)
      text=text..string.format("\nNtotal     = %d (=%d)", Ntotal, Nstock+Nspawned+Nrequested+Nreserved)
      text=text.."\n==========================================="
      self:I(self.lid..text)
    end
    
  end
  
  ---
  -- MISSIONS
  ---
    
  -- Mission queue.
  if self.verbose>=2 and #self.missionqueue>0 then
    local text="Mission queue:"
    for i,_mission in pairs(self.missionqueue) do
      local mission=_mission --Ops.Auftrag#AUFTRAG      
      local target=mission:GetTargetName() or "unknown"      
      text=text..string.format("\n[%d] %s (%s): status=%s, target=%s", i, mission.name, mission.type, mission.status, target)
    end
    self:I(self.lid..text)    
  end
  
  ---
  -- TRANSPORTS
  ---
    
  -- Transport queue.
  if self.verbose>=2 and #self.transportqueue>0 then
    local text="Transport queue:"
    for i,_transport in pairs(self.transportqueue) do
      local transport=_transport --Ops.OpsTransport#OPSTRANSPORT            
      text=text..string.format("\n[%d] UID=%d: status=%s", i, transport.uid, transport:GetState())
    end
    self:I(self.lid..text)    
  end  

  self:__Status(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "MissionAssign" event. Mission is added to a LEGION mission queue and already requested. Needs assets to be added to the mission already.
-- @param #COMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Legion#LEGION Legion The LEGION.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function COMMANDER:onafterMissionAssign(From, Event, To, Legion, Mission)

  -- Debug info.
  self:I(self.lid..string.format("Assigning mission %s (%s) to legion %s", Mission.name, Mission.type, Legion.alias))
  
  -- Set mission commander status to QUEUED as it is now queued at a legion.
  Mission.statusCommander=AUFTRAG.Status.QUEUED
  
  -- Add mission to legion.
  Legion:AddMission(Mission)
  
  -- Directly request the mission as the assets have already been selected.
  Legion:MissionRequest(Mission)

end

--- On after "MissionCancel" event.
-- @param #COMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function COMMANDER:onafterMissionCancel(From, Event, To, Mission)

  -- Debug info.
  self:I(self.lid..string.format("Cancelling mission %s (%s) in status %s", Mission.name, Mission.type, Mission.status))
  
  -- Set commander status.
  Mission.statusCommander=AUFTRAG.Status.CANCELLED
  
  if Mission:IsPlanned() then
  
    -- Mission is still in planning stage. Should not have a legion assigned ==> Just remove it form the queue.
    self:RemoveMission(Mission)
    
  else
  
    -- Legion will cancel mission.
    if #Mission.legions>0 then
      for _,_legion in pairs(Mission.legions) do
        local legion=_legion --Ops.Legion#LEGION
        
        -- TODO: Should check that this legions actually belongs to this commander.
        
        -- Legion will cancel the mission.
        legion:MissionCancel(Mission)
      end
    end
    
  end

end

--- On after "TransportAssign" event. Transport is added to a LEGION mission queue.
-- @param #COMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Legion#LEGION Legion The LEGION.
-- @param Ops.OpsTransport#OPSTRANSPORT
function COMMANDER:onafterTransportAssign(From, Event, To, Legion, Transport)

  -- Debug info.
  self:I(self.lid..string.format("Assigning transport %d to legion %s", Transport.uid, Legion.alias))
  
  -- Set mission commander status to QUEUED as it is now queued at a legion.
  Transport.statusCommander=OPSTRANSPORT.Status.QUEUED
  
  -- Add mission to legion.
  Legion:AddOpsTransport(Transport)
  
  -- Directly request the mission as the assets have already been selected.
  Legion:TransportRequest(Transport)

end

--- On after "TransportCancel" event.
-- @param #COMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
function COMMANDER:onafterTransportCancel(From, Event, To, Transport)

  -- Debug info.
  self:I(self.lid..string.format("Cancelling Transport UID=%d in status %s", Transport.uid, Transport:GetState()))
  
  -- Set commander status.
  Transport.statusCommander=OPSTRANSPORT.Status.CANCELLED
  
  if Transport:IsPlanned() then
  
    -- Transport is still in planning stage. Should not have a legion assigned ==> Just remove it form the queue.
    self:RemoveTransport(Transport)
    
  else
  
    -- Legion will cancel mission.
    if #Transport.legions>0 then
      for _,_legion in pairs(Transport.legions) do
        local legion=_legion --Ops.Legion#LEGION
        
        -- TODO: Should check that this legions actually belongs to this commander.
        
        -- Legion will cancel the mission.
        legion:TransportCancel(Transport)
      end
    end
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check mission queue and assign ONE planned mission.
-- @param #COMMANDER self 
function COMMANDER:CheckMissionQueue()

  -- Number of missions.
  local Nmissions=#self.missionqueue

  -- Treat special cases.
  if Nmissions==0 then
    return nil
  end

  -- Sort results table wrt prio and start time.
  local function _sort(a, b)
    local taskA=a --Ops.Auftrag#AUFTRAG
    local taskB=b --Ops.Auftrag#AUFTRAG
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.Tstart<taskB.Tstart)
  end
  table.sort(self.missionqueue, _sort)

  -- Get the lowest importance value (lower means more important).
  -- If a mission with importance 1 exists, mission with importance 2 will not be assigned. Missions with no importance (nil) can still be selected. 
  local vip=math.huge
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    if mission.importance and mission.importance<vip then
      vip=mission.importance
    end
  end

  -- Loop over missions in queue.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- We look for PLANNED missions.
    if mission:IsPlanned() and mission:IsReadyToGo() and (mission.importance==nil or mission.importance<=vip) then
    
      ---
      -- PLANNNED Mission
      -- 
      -- 1. Select best assets from legions
      -- 2. Assign mission to legions that have the best assets.
      ---    
    
      -- Recruite assets from legions.      
      local recruited, assets, legions=self:RecruitAssetsForMission(mission)
      
      if recruited then
      
        -- Add asset to mission.
        for _,_asset in pairs(assets) do
          local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
          mission:AddAsset(asset)
        end
        
        -- Recruit asset for escorting recruited mission assets.
        local EscortAvail=self:RecruitAssetsForEscort(mission, assets)
        
        -- Transport available (or not required).
        local TransportAvail=true
        
        -- Escort requested and available.
        if EscortAvail then

          -- Check if mission assets need a transport.
          if mission.NcarriersMin then
          
            -- Recruit carrier assets for transport.
            local Transport=nil
            local Legions=mission.transportLegions or self.legions
            
            TransportAvail, Transport=LEGION.AssignAssetsForTransport(self, Legions, assets, mission.NcarriersMin, mission.NcarriersMax, mission.transportDeployZone, mission.transportDisembarkZone)
            
            -- Add opstransport to mission.
            if TransportAvail and Transport then
              mission.opstransport=Transport
            end
          
          end
          
        end
        
        -- Escort and transport must be available (or not required).
        if EscortAvail and TransportAvail then
        
          -- Assign mission to legion(s).
          for _,_legion in pairs(legions) do
            local legion=_legion --Ops.Legion#LEGION
            
            -- Debug message.
            self:I(self.lid..string.format("Assigning mission %s [%s] to legion %s", mission:GetName(), mission:GetType(), legion.alias))
        
            -- Add mission to legion.
            self:MissionAssign(legion, mission)
            
          end
        
        else
          -- Recruited assets but no requested escort available. Unrecruit assets!
          LEGION.UnRecruitAssets(assets, mission)
        end        
    
        -- Only ONE mission is assigned.
        return        
      end
      
    else

      ---
      -- Missions NOT in PLANNED state
      ---    
    
    end
  
  end
  
end

--- Recruit assets for a given mission.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #boolean If `true` enough assets could be recruited.
-- @return #table Recruited assets.
-- @return #table Legions that have recruited assets.
function COMMANDER:RecruitAssetsForMission(Mission)

  -- Debug info.
  env.info(string.format("FF recruiting assets for mission %s [%s]", Mission:GetName(), Mission:GetType()))
  
  -- Cohorts.
  local Cohorts={}
  for _,_legion in pairs(Mission.specialLegions or {}) do
    local legion=_legion --Ops.Legion#LEGION
    for _,_cohort in pairs(legion.cohorts) do
      local cohort=_cohort --Ops.Cohort#COHORT
      table.insert(Cohorts, cohort)
    end
  end
  for _,_cohort in pairs(Mission.specialCohorts or {}) do
    local cohort=_cohort --Ops.Cohort#COHORT
    table.insert(Cohorts, cohort)
  end
  
  -- No special mission legions/cohorts found ==> take own legions.
  if #Cohorts==0 then
    for _,_legion in pairs(self.legions) do
      local legion=_legion --Ops.Legion#LEGION
      for _,_cohort in pairs(legion.cohorts) do
        local cohort=_cohort --Ops.Cohort#COHORT
        table.insert(Cohorts, cohort)
      end
    end      
  end  

  -- Number of required assets.
  local NreqMin, NreqMax=Mission:GetRequiredAssets()
  
  -- Target position.
  local TargetVec2=Mission:GetTargetVec2()
  
  -- Special payloads.
  local Payloads=Mission.payloads
  
  -- Recruite assets.
  local recruited, assets, legions=LEGION.RecruitCohortAssets(Cohorts, Mission.type, Mission.alert5MissionType, NreqMin, NreqMax, TargetVec2, Payloads, Mission.engageRange, Mission.refuelSystem, nil)

  return recruited, assets, legions
end

--- Recruit assets performing an escort mission for a given asset.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @param #table Assets Table of assets to be escorted.
-- @return #boolean If `true`, enough assets could be recruited or no escort was required in the first place.
function COMMANDER:RecruitAssetsForEscort(Mission, Assets)

  -- Is an escort requested in the first place?
  if Mission.NescortMin and Mission.NescortMax and (Mission.NescortMin>0 or Mission.NescortMax>0) then

    -- Cohorts.
    local Cohorts={}
    for _,_legion in pairs(Mission.escortLegions or {}) do
      local legion=_legion --Ops.Legion#LEGION
      for _,_cohort in pairs(legion.cohorts) do
        local cohort=_cohort --Ops.Cohort#COHORT
        table.insert(Cohorts, cohort)
      end
    end
    for _,_cohort in pairs(Mission.escortCohorts or {}) do
      local cohort=_cohort --Ops.Cohort#COHORT
      table.insert(Cohorts, cohort)
    end
    
    -- No special escort legions/cohorts found ==> take own legions.
    if #Cohorts==0 then
      for _,_legion in pairs(self.legions) do
        local legion=_legion --Ops.Legion#LEGION
        for _,_cohort in pairs(legion.cohorts) do
          local cohort=_cohort --Ops.Cohort#COHORT
          table.insert(Cohorts, cohort)
        end
      end      
    end
        
    
    -- Call LEGION function but provide COMMANDER as self.
    local assigned=LEGION.AssignAssetsForEscort(self, Cohorts, Assets, Mission.NescortMin, Mission.NescortMin)
    
    return assigned    
  end

  return true
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Transport Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check transport queue and assign ONE planned transport.
-- @param #COMMANDER self 
function COMMANDER:CheckTransportQueue()

  -- Number of missions.
  local Ntransports=#self.transportqueue

  -- Treat special cases.
  if Ntransports==0 then
    return nil
  end

  -- Sort results table wrt prio and start time.
  local function _sort(a, b)
    local taskA=a --Ops.Auftrag#AUFTRAG
    local taskB=b --Ops.Auftrag#AUFTRAG
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.Tstart<taskB.Tstart)
  end
  table.sort(self.transportqueue, _sort)

  -- Get the lowest importance value (lower means more important).
  -- If a mission with importance 1 exists, mission with importance 2 will not be assigned. Missions with no importance (nil) can still be selected. 
  local vip=math.huge
  for _,_transport in pairs(self.transportqueue) do
    local transport=_transport --Ops.OpsTransport#OPSTRANSPORT
    if transport.importance and transport.importance<vip then
      vip=transport.importance
    end
  end

  for _,_transport in pairs(self.transportqueue) do
    local transport=_transport --Ops.OpsTransport#OPSTRANSPORT
    
    -- We look for PLANNED missions.
    if transport:IsPlanned() and transport:IsReadyToGo() and (transport.importance==nil or transport.importance<=vip) then
    
      ---
      -- PLANNNED Mission
      -- 
      -- 1. Select best assets from legions
      -- 2. Assign mission to legions that have the best assets.
      ---    

      -- Get all undelivered cargo ops groups.
      local cargoOpsGroups=transport:GetCargoOpsGroups(false)
      
      -- Weight of the heaviest cargo group. Necessary condition that this fits into on carrier unit!
      local weightGroup=0
      
      -- Calculate the max weight so we know which cohorts can provide carriers.
      if #cargoOpsGroups>0 then  
        for _,_opsgroup in pairs(cargoOpsGroups) do
          local opsgroup=_opsgroup --Ops.OpsGroup#OPSGROUP
          local weight=opsgroup:GetWeightTotal()
          if weight>weightGroup then
            weightGroup=weight
          end
        end    
      end
      
      if weightGroup>0 then
    
        -- Recruite assets from legions.      
        local recruited, assets, legions=self:RecruitAssetsForTransport(transport, weightGroup)
        
        if recruited then
        
          -- Add asset to transport.
          for _,_asset in pairs(assets) do
            local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
            transport:AddAsset(asset)
          end        
  
          -- Assign transport to legion(s).
          for _,_legion in pairs(legions) do
            local legion=_legion --Ops.Legion#LEGION
            
            -- Debug message.
            self:I(self.lid..string.format("Assigning transport UID=%d to legion %s", transport.uid, legion.alias))
        
            -- Add mission to legion.
            self:TransportAssign(legion, transport)
            
          end
      
          -- Only ONE transport is assigned.
          return
        else
          -- Not recruited.
          LEGION.UnRecruitAssets(assets)
        end
        
      end
      
    else

      ---
      -- Missions NOT in PLANNED state
      ---    
    
    end
  
  end
  
end

--- Recruit assets for a given OPS transport.
-- @param #COMMANDER self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The OPS transport.
-- @return #boolean If `true`, enough assets could be recruited.
-- @return #table Recruited assets.
-- @return #table Legions that have recruited assets.
function COMMANDER:RecruitAssetsForTransport(Transport, CargoWeight)
  
  if CargoWeight==0 then
    -- No cargo groups!
    return false, {}, {}
  end
  
  -- Cohorts.
  local Cohorts={}
  for _,_legion in pairs(self.legions) do
    local legion=_legion --Ops.Legion#LEGION
    
    -- Check that runway is operational.    
    local Runway=legion:IsAirwing() and legion:IsRunwayOperational() or true
    
    if legion:IsRunning() and Runway then
    
      -- Loops over cohorts.
      for _,_cohort in pairs(legion.cohorts) do
        local cohort=_cohort --Ops.Cohort#COHORT
        table.insert(Cohorts, cohort)
      end
      
    end
  end    


  -- Target is the deploy zone.
  local TargetVec2=Transport:GetDeployZone():GetVec2()

  -- Number of required carriers.
  local NreqMin,NreqMax=Transport:GetRequiredCarriers()
  
  -- Recruit assets and legions.
  local recruited, assets, legions=LEGION.RecruitCohortAssets(Cohorts, AUFTRAG.Type.OPSTRANSPORT, nil, NreqMin, NreqMax, TargetVec2, nil, nil, nil, CargoWeight)

  return recruited, assets, legions  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Resources
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Count assets of all assigned legions.
-- @param #COMMANDER self
-- @param #boolean InStock If true, only assets that are in the warehouse stock/inventory are counted.
-- @param #table MissionTypes (Optional) Count only assest that can perform certain mission type(s). Default is all types.
-- @param #table Attributes (Optional) Count only assest that have a certain attribute(s), e.g. `WAREHOUSE.Attribute.AIR_BOMBER`.
-- @return #number Amount of asset groups.
function COMMANDER:CountAssets(InStock, MissionTypes, Attributes)

  local N=0
  for _,_legion in pairs(self.legions) do
    local legion=_legion --Ops.Legion#LEGION
    N=N+legion:CountAssets(InStock, MissionTypes, Attributes)
  end

  return N
end

--- Count assets of all assigned legions.
-- @param #COMMANDER self
-- @param #boolean InStock If true, only assets that are in the warehouse stock/inventory are counted.
-- @param #table Legions (Optional) Table of legions. Default is all legions.
-- @param #table MissionTypes (Optional) Count only assest that can perform certain mission type(s). Default is all types.
-- @param #table Attributes (Optional) Count only assest that have a certain attribute(s), e.g. `WAREHOUSE.Attribute.AIR_BOMBER`.
-- @return #number Amount of asset groups.
function COMMANDER:GetAssets(InStock, Legions, MissionTypes, Attributes)

  -- Selected assets.
  local assets={}

  for _,_legion in pairs(Legions or self.legions) do
    local legion=_legion --Ops.Legion#LEGION
    
    --TODO Check if legion is running and maybe if runway is operational if air assets are requested.

    for _,_cohort in pairs(legion.cohorts) do
      local cohort=_cohort --Ops.Cohort#COHORT
      
      for _,_asset in pairs(cohort.assets) do
        local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
        
        -- TODO: Check if repaired.
        -- TODO: currently we take only unspawned assets.
        if not (asset.spawned or asset.isReserved or asset.requested) then
          table.insert(assets, asset)
        end
        
      end
    end
  end
  
  return assets
end

--- Check all legions if they are able to do a specific mission type at a certain location with a given number of assets.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #table Table of LEGIONs that can do the mission and have at least one asset available right now.
function COMMANDER:GetLegionsForMission(Mission)

  -- Table of legions that can do the mission.
  local legions={}
  
  -- Loop over all legions.
  for _,_legion in pairs(self.legions) do
    local legion=_legion --Ops.Legion#LEGION
    
    -- Count number of assets in stock.
    local Nassets=0    
    if legion:IsAirwing() then
      Nassets=legion:CountAssetsWithPayloadsInStock(Mission.payloads, {Mission.type}, Attributes)
    else    
      Nassets=legion:CountAssets(true, {Mission.type}, Attributes) --Could also specify the attribute if Air or Ground mission.
    end    
    
    -- Has it assets that can?
    if Nassets>0  and false then        
      
      -- Get coordinate of the target.
      local coord=Mission:GetTargetCoordinate()
      
      if coord then
      
        -- Distance from legion to target.
        local distance=UTILS.MetersToNM(coord:Get2DDistance(legion:GetCoordinate()))
        
        -- Round: 55 NM ==> 5.5 ==> 6, 63 NM ==> 6.3 ==> 6
        local dist=UTILS.Round(distance/10, 0)
        
        -- Debug info.
        self:I(self.lid..string.format("Got legion %s with Nassets=%d and dist=%.1f NM, rounded=%.1f", legion.alias, Nassets, distance, dist))
      
        -- Add legion to table of legions that can.
        table.insert(legions, {airwing=legion, distance=distance, dist=dist, targetcoord=coord, nassets=Nassets})
        
      end
      
    end
    
    -- Add legion if it can provide at least 1 asset.    
    if Nassets>0 then
      table.insert(legions, legion)
    end
            
  end
  
  return legions
end

--- Get assets on given mission or missions.
-- @param #COMMANDER self
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @return #table Assets on pending requests.
function COMMANDER:GetAssetsOnMission(MissionTypes)

  local assets={}

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    -- Check if this mission type is requested.
    if AUFTRAG.CheckMissionType(mission.type, MissionTypes) then

      for _,_asset in pairs(mission.assets or {}) do
        local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
          table.insert(assets, asset)
       end
    end
  end

  return assets
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------