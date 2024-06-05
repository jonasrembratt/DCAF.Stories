--[[ ////////////////////////////////////↓\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
                                     SHOEBILL
                                     ********
    A friendly helicopter carrying something important and a team of SpecOps
    but they get shot down near _nearestCity. A local warlord sends out a group
    to recover the valuable cargo, and BLU is tasked with taking out the group
    to prevent this. CAS support for the SpecOps team is also required as they
    are taken small arms fire from a nearby location.

]]

local _codeword = "SHOEBILL"
local _recipient = "FOCUS"
local _nearestCity = "RAQQA"
local _JTAC_Frequency = "p[030] decimal p[0]" -- << -- changed to phonetic (p[...]) as frequency was otherwise pronounced "sixty nine"
local _JTAC_Callsign = "SPARTAN p[31]"        -- << -- also changed to phonetic
local _heloType = "Chinook"                   -- << -- changed to reporting name. is much clearer as original took time and was hard to discern
local _destination = "Tabqa"

Shoebill = {
    Name = _codeword,
    MANPADSpattern = "Shoebill_MANPADS", -- <<-- specifies a naming pattern for the DCAF.MobileDefense script (see Start function)
    Groups = {
        BLU = {
            Chinook = getGroup("Shoebill_Chinook-1"),
            SpecOps = getGroup("Shoebill_SpecOps-2"),
            JTAC = getGroup("Shoebill_SpecOps-1"),
            CSAR = getGroup("Shoebill_CSAR-1"),
            },
        RED = {
            InsInf = getGroup("Shoebill_InsInf-1"),
            InsCon = getGroup("Shoebill_InsCon-1"),
            InsReinforce = getGroup("Shoebill_InsReinforce-1")
        }
    },
    Flags = {
    },
    MSG = {
        -- << -- removed use of _recipient from message declarations, as this made it impossible to changed recipient from :InitTTS (see function. Also see :Send function)
        Start =
            "[CALLSIGN]. Priority mission. A " .. _heloType .. " has been shot down near the city of " .. _nearestCity .. " by unknown hostiles. " ..
            "The helicopter was carrying a Special Ops group bound for " .. _destination .. ". The crew escaped and are requesting immediate CAS support and exfil. "..
            "Coordinate with local jaytac, callsign " .. _JTAC_Callsign .. ", on frequency, " .. _JTAC_Frequency .. ", before dispatching a see-sar mission." ..
            "Be advised we may have troops in contact",
        CSAR =
            "[CALLSIGN]. see-sar dispatched. E T A is twenty minutes. Ensure the area is secure.",
        MissionComplete =
            "[CALLSIGN]. Shoebill succesfully extracted, mission accomplished.",
        MissionFailed =
            "[CALLSIGN]. The entire Spec Ops team was killed, and the see-sar is R T B. Full debrief and A A R tomorrow at oh eight hundred.",
        MissionFailedShotDown =
            "[CALLSIGN]. The see-sar helicopter was shot down as we failed to secure the L Z. Debriefing of wing leaders at oh eight hundred tomorrow morning.",
        }
}

-- \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\↑///////////////////////////////////////////////

function Shoebill:Start(tts)
    if self._is_started then return end
    self._is_started = true
    if self._start_menu then self._start_menu:Remove(false) end
    self.TTS = tts
    self.Groups.BLU.Chinook:Activate()
    self.Groups.BLU.Chinook:Explode(150, 2)
    self.Groups.BLU.Chinook:GetCoordinate():BigSmokeAndFire( 5, 1)
    self.Groups.BLU.SpecOps:Activate()
    self.Groups.BLU.JTAC:Activate()
    DCAF.delay(function()
        self.Groups.BLU.JTAC:SetAIOff()
    end, .5)
    DCAF.MobileDefence:New(self.Groups.RED.InsCon:Activate(), 2, self.MANPADSpattern) -- <<-- makes the convoy stop and deploy MANPADS
    self.Groups.RED.InsCon:Activate()
    self.Groups.RED.InsInf:Activate()
    self:Send(self.MSG.Start)
end

function Shoebill:DisableImmortal()
    self.Groups.BLU.SpecOps:SetCommandImmortal(false)
    self.Groups.BLU.JTAC:SetCommandImmortal(false)
end

function Shoebill:ReinforcementsArrive()
    self.Groups.RED.InsReinforce:Activate()
end

function Shoebill:InitTTS(tts, recipient) -- << -- added ability to specify recipient. Allows for MM to init these things from the ME, making the story easier to adapt without access to story file
    self.TTS = tts
    if isAssignedString(recipient) then
        _recipient = recipient
        Debug(_codeword..":InitTTS :: recipient was set to '" .. _recipient .. "'")
    end
    return self
end

function Shoebill:Send(msg)
    if not self.TTS or not isAssignedString(msg) then return end
    msg = _recipient .. ". " .. msg .. ". [CALLSIGN] out" -- << -- automatically injects recipient and then a "[CALLSIGN] out" to all transmissions
    self.TTS:Send(msg)
end

function Shoebill:SendActual(msg)
    if not self.TTS or not isAssignedString(msg) then return end
    self.TTS:SendActual(msg)
end

function Shoebill:Recover()
    Debug("sausage -- Shoebill:Recover was activated")
    self.Groups.BLU.JTAC:SetAIOn()
    DCAF.delay(function()
        self.Groups.BLU.JTAC:Destroy()
        self.Groups.BLU.SpecOps:Destroy()
    end, 150)
end

function Shoebill:MissionComplete()
    self:Send(self.MSG.MissionComplete)
end

function Shoebill:CheckLifeSpecOps()
    self._checkLifeSchedulerSpec = DCAF.startScheduler(function()
        local specs = self.Groups.BLU.SpecOps
        if specs and not specs:IsActive() then return end
        if not self.Groups.BLU.SpecOps:IsAlive() then
            self:Send(self.MSG.MissionFailed)
        end
    end, 30)
end

function Shoebill:CheckLifeCSAR()
    self._checkLifeSchedulerCsar = DCAF.startScheduler(function()
        local csar = self.Groups.BLU.CSAR
        if csar and not csar:IsActive() then return end
        if not self.Groups.BLU.CSAR:IsAlive() then
            self:Send(self.MSG.MissionFailedShotDown)
        end
    end, 30)
end

function Shoebill:CSAR()
    DCAF.delay(function()
        self:Send(self.MSG.CSAR)
        self.Groups.BLU.CSAR:Activate()
        self._csar_menu:Remove(true)
    end, 10)
end

-- function Shoebill:DropBomb()
--         local units = self.Groups.RED.InsInf:GetUnits()
--         local killUnits = math.floor(#units * 1)
--         for i = 1, killUnits, 1 do
--             local unit = self.Groups.RED.InsInf:GetUnit(i)
--             unit:Destroy()
--         end
--         self._boom_menu:Remove(true)
-- end

Shoebill._main_menu = GM_Menu:AddMenu(_codeword)
Shoebill._start_menu = Shoebill._main_menu:AddCommand("Start", function()
    Shoebill:Start(TTS_Top_Dog)
    -- Shoebill._boom_menu = Shoebill._main_menu:AddCommand("Boom", function()
    --     Shoebill:DropBomb()
    -- end)
    Shoebill._csar_menu = Shoebill._main_menu:AddCommand("Send CSAR Helo", function()
        Shoebill:CSAR()
    end)
end)

Trace("\\\\\\\\\\ Story :: SHOEBILL.lua was loaded //////////")