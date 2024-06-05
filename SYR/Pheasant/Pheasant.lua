-- //////////////////////////////////////////////////////////////////////////////////
--                                    PHEASANT
--                                    ********
-- Syrian Army dispatches a freight train with infantry and supplies to reinforce position
-- near Al Tabqah. Harriers are tasked with intercepting and disabling the train.

-- TODO
-- More messages (top dog)'
-- Complete isEscortNearby function

local _codeword = "Pheasant"
local _ido = "FOCUS"
local _msr1 = "the Al Bab Manbiidge highway"
local _destination = "Kharabishq"
Pheasant = {
    Name = _codeword,
    Groups = {
        BLU = {
        },
        RED = {
            Convoy = getGroup("Pheasant Convoy-1")
        },
    },
    MSG = {
        Start =
            _ido .. ", [CALLSIGN]. New mission, codename: " .. _codeword .. ". We've received intel that a motor convoy was spotted at grid, p[CA 83], driving along " ..
            _msr1 .. " towards " .. _destination .. ", carrying supplies and troops . Request retasking of appropriate flight package to intercept and destroy A S A P . E T A of convoy at " ..
            _destination .. " is time, plus, one hour and fifteen. R O E; weapons free outside " .. _destination .. " and densely populated areas. Repeat, R O E; weapons free outside " ..
            _destination .. " and densely populated areas. Civilian casualties are absolutely unacceptable. [CALLSIGN] out.",
        MissionFailed =
            _ido .. ", [CALLSIGN], " .. _codeword .. " is a wash. The motor convoy has reached " .. _destination .. " and have succesfully "
            .. "resupplied and reinforced the regiment there. Our efforts to secure the N F Z has been negatively impacted as a result. [CALLSIGN] out.",
        ConvoyDestroyed =
            _ido .. ", [CALLSIGN], mission " .. _codeword .. ": motor convoy succesfully destroyed, and enemy forces at "
            .. _destination .. " are severely weakened in their ability to maintain control of the base. Excellent work. [CALLSIGN] out.",
        Pheasant_Urgent =
            _ido .. ", [CALLSIGN], update on " .. _codeword .. ". The motor convoy has just crossed the bridge north west of " .. _destination .. " into the no fly zone. Unless action is taken immediately, "
            .. "their E T A at " .. _destination .. " is time, plus thirty. [CALLSIGN] out."
    }
}

function Pheasant:Start(tts)
    if self._is_started then return end
    self._is_started = true
    self._start_menu:Remove(true)
    self.TTS = tts
    self.Groups.RED.Convoy:Activate()
    DCAF.MobileDefence:New(self.Groups.RED.Convoy, 2, "Pheasant MobDefense SA")
    self:Send(self.MSG.Start)
    self:ConvoyAlive()
end

function Pheasant:Send(msg)
    if not self.TTS or not isAssignedString(msg) then return end
    self.TTS:Send(msg)
end

function Pheasant:SendActual(msg)
    if not self.TTS or not isAssignedString(msg) then return end
    self.TTS:SendActual(msg)
end

function Pheasant:MissionFailed()
    self:Send(self.MSG.MissionFailed)
end

function Pheasant:Urgent()
    self:Send(self.MSG.Pheasant_Urgent)
    -- self.Groups.BLU.A10:Activate()
end

function Pheasant:ConvoyDestroyed()
    self:Send(self.MSG.ConvoyDestroyed)
end

function Pheasant:ConvoyAlive()
    self._checkLifeSchedulerID = DCAF.startScheduler(function()
        local convoy = self.Groups.RED.Convoy
        local degradeRatio = 0.6
        if convoy and not convoy:IsActive() then return end
        local ratio = convoy:GetSize() / convoy:GetInitialSize()
        if ratio <= degradeRatio then
            self:ConvoyDestroyed()
            DCAF.stopScheduler(self._checkLifeSchedulerID)
            convoy:SetAIOff()
        end
    end, 30)
end

-- function Pheasant:CAS_Request()
--     local units = self.Groups.RED.Convoy:GetUnits()
--     local killUnits = math.floor(#units * 0.7)
--     for i = 1, killUnits, 1 do
--         local unit = self.Groups.RED.Convoy:GetUnit(i)
--         unit:Explode(500, 2)
--     end
--     -- for i, target in ipairs(units) do
--     --     target:Explode(500, 2)
--     -- end
--     self._CAS_menu:Remove(true)
-- end

Pheasant._main_menu = GM_Menu:AddMenu(_codeword)
Pheasant._start_menu = Pheasant._main_menu:AddCommand("Start", function()
    Pheasant:Start(TTS_Top_Dog)
end)
-- Pheasant._CAS_menu = Pheasant._main_menu:AddCommand("Request CAS", function()
--     Pheasant:CAS_Request()
-- end)

Trace("\\\\\\\\\\ Story :: Pheasant.lua was loaded //////////")
