--[[ //////////////////////////////////////////////////////////////////////////////////
                                     SWALLOW
                                     *******
    Transport aircraft arrives into Syria, with a mission to drop supplies at a 
    designated drop zone (DZ). The mission is deemed critical and its safety must be 
    assured for it to be successful. Should the situation be deemed to risky the GM
    can cancel the mission. If GM feels security can be assured by delaying the mission
    the transporters can be ordered to hold. GM can also cancel the mission if necessary.

<<<<<<< Updated upstream
    ## HOLDING
    After the transporters passes a 'COMMIT' waypoint the GM will have the option to
    hold the aircraft. Doing so will update the same menu option to a command to 
    'Continue'. As the mission enters Syrian airspace wp ('IN') the "HOLD" option
    is no longer available as it is deemed to risky to be holding inside enemy 
    airspace.

    ## CANCELLING
    After the transporters passes a 'COMMIT' waypoint the GM will have the option to
    cancel the mission and have the aircraft RTB. Doing so will require a confirmation
    to avoid fat-finger mistakes. The flight will RTB by diverting to '_divert_' WP
    or 'RTB' waypoint, depending on its current location. This will ensure a safe
    route back.

    ## THREATS
    The flight's final leg before the DZ will have it descend to 7000 feet, and 
    go into an appropriate formation for the drop. But as the flight passes 'COMMIT' 
    WP an SA-15 Gauntlet vehicle will be spawned in a location where it will pose a 
    very serious threat. This vehicle must be destroyed or the mission will 
    automatically be cancelled when the flight reaches WP 'IP'.

    ## TTS
    The mission supports a frequency for a text-to-speech output source, such as
    DCAF's "TOP DOG" (a combination of JSTAR, and theatre commander, useful for
    keeping the players informed of events as they happen). The MM can pass a 
    #DCAF.TTSChannel into the `Swallow:InitTTS()` function for this to be enabled.
    With a TTS channel injected, there will be call-outs on that frequency as
    the Swallow mission unfolds.
    
]]
=======
-- TODO
-- More messages (top dog) -- Needs final approval
-- Complete isEscortNearby function
>>>>>>> Stashed changes

local _codeword = "Swallow"
local _recipient = "FOCUS"
Swallow = {
    Name = _codeword,
    Groups = {
        BLU = {
            Hercs_1 = getGroup("Swallow Hercs-1"),
        },
        RED = {
            Gauntlet = getGroup("Swallow Gauntlet-1")
        }
    },
    -- after Hercs passes GoNogo point the SA-15 is activated, but in GREEN state until mission BLU aircraft types gets within the specified range...
    WakeGauntletTypes = {
        ENUMS.UnitType.C_130,
        ENUMS.UnitType.F16CM,
        ENUMS.UnitType.F15ESE,
        ENUMS.UnitType.AVN8B,
    },
    WakeGauntletRange = NauticalMiles(40),
    Flags = {
        EndHold = _codeword .. " :: end hold"
    },
    MSG = {
        Start =
        _recipient .. ", [CALLSIGN]. Priority mission. Operation " .. _codeword .. " is now underway. E T A Control Point Davy is time plus thirty seven minutes. [CALLSIGN] out.",
        -- _recipient .. ", [CALLSIGN]. Priority mission. Operation " .. _codeword .. " is now underway. Request tasking of appropriate flight package to escort " .. _codeword .. " one " ..
        -- "to their destination in the no fly zone. [CALLSIGN] out.",
        RequestEscort =
            _recipient .. ", [CALLSIGN]. Relaying urgent request from [CALLSIGN] actual! " ..
            _codeword .. " one is expected to enter the no fly zone at time plus seventeen " ..
            "and is requesting immediate flight package to escort. [CALLSIGN] actual would like to remind you that the ".. _codeword .. " one mission is critical to our objective. [CALLSIGN] out.",
        MissionComplete =
            _recipient .. ", [CALLSIGN]. " .. _codeword .. " has completed their mission and is RTB. [CALLSIGN] actual asked me to pass on his congratulations on a job well done!" ..
            "[CALLSIGN] out.",
        GauntletActive =
            _recipient .. ", [CALLSIGN]. urgent tasking. We are picking up emission from an active Gauntlet at grid p[EV 09], keypad one. " ..
            "The S A fifteen is an imminent threat toward " .. _codeword .. " one and must be eliminated or suppressed before the hercs "..
            "reaches the area in about nine minutes. Repeat. Request immediate destruction of Gauntlet vehicle in grid p[EV 09] keypad one, "..
            "to ensure safety for " .. _codeword .. " one supply drop mission. [CALLSIGN] out.",
        MissionAbortedNoEscort =
            _recipient .. ", [CALLSIGN] with an update. Failure to provide security for the " ..
            _codeword .. " supply drop mission has forced it to abort and return to base. This is very unfortunate. [CALLSIGN] out.",
        MissionAbortedGauntletAwake =
            _recipient .. ", [CALLSIGN] with an update. The Gauntlet in grid p[EV 09] is still awake and represents an unacceptable threat to " ..
            _codeword .. " one. The supply drop is therefore cancelled and " .. _codeword .. " one is now RTB. This is very unfortunate. [CALLSIGN] out.",
        MissionAbortedManually = 
        _recipient .. ", [CALLSIGN] with an update. As security for the " .. _codeword .. " one mission has been deemed unsatisfactory, the mission "..
            "has been cancelled and is now R T B. This is very unfortunate. [CALLSIGN] out.",
        TDA_ScoldingNoEscort =
            "All stations! [CALLSIGN] here. Listen up! I'm disappointed to report that due to failure to meet mission " ..
            "criteria on time, " .. _codeword .. " mission has been scrapped. We operate on precise timelines for a reason. "..
            "Failure to adhere to these timelines jeopardizes not only the success of the mission, but the safety of every member of this force. " ..
            "This lack of discipline is unacceptable. We cannot afford to make excuses or overlook the importance of our protocols. " ..
            "I expect better from each and every one of you. We will review our procedures and ensure that this does not happen again. " ..
            "Get your act together pilots. Our reputation, and the lives of our comrades are at stake. Flight leads. Expect a full debrief "..
            "and review tomorrow at oh eight hundred. [CALLSIGN] out.",
        TDA_ScoldingThreatTooHigh =
            "All stations! [CALLSIGN] here. Listen up! I'm disappointed to report that due to failure to uphold security " .. _codeword .. " mission has been scrapped. " ..
            "We need to do better! The inability to react to unexpected threats jeopardizes not only the success of the mission, but the safety of every member " ..
            "of this unit. This is unacceptable. I expect better from each and every one of you. We will review our ability to prioritize and make proper decisions " ..
            "to ensure that this does not repeat.  Our reputation, and the lives of our comrades are at stake. Flight leads, expect a full debrief " ..
            "and review tomorrow at oh eight hundred. [CALLSIGN] out.",
    }
}

function Swallow:Start(tts)
    if self._is_started then return end
    self._is_started = true
    if self._start_menu then self._start_menu:Remove(false) end
    self.TTS = tts
    self.Groups.BLU.Hercs_1:Activate()
    self:Send(self.MSG.Start)
    self._is_escorted = nil
end

function Swallow:InitTTS(tts)
    self.TTS = tts
    return self
end

function Swallow:Send(msg)
    if not self.TTS or not isAssignedString(msg) then return end
    self.TTS:Send(msg)
end

function Swallow:SendActual(msg)
    if not self.TTS or not isAssignedString(msg) then return end
    self.TTS:SendActual(msg)
end

function Swallow:GoNoGoDecision()
    self:ActivateGauntlet(self.WakeGauntletRange)
    self:EnableRTB()
    self:EnableHold()
end

function Swallow:Hold()
    if not self._is_hold_enabled then return end
    local hercs = self.Groups.BLU.Hercs_1
    local altitude = hercs:GetAltitude(false)
    self._is_holding = true
    hercs:PushTask(hercs:TaskOrbitCircle(altitude, Knots(250)))
    self:EnableHold()
    return self
end

function Swallow:EndHold()
    if not self._is_holding then return end
    self._is_holding = false
    self.Groups.BLU.Hercs_1:PopCurrentTask()
    self:EnableHold()
    return self
end

function Swallow:EnterSyria()
    self._is_in_syria = true
    self:DisableHold()
    return self
end

function Swallow:EnableHold()
    if not self._main_menu then return self end
    self._is_hold_enabled = true
    if self._hold_menu then self._hold_menu:Remove() end
    if self._is_holding then
        self._hold_menu = self._main_menu:AddCommand("Continue (leave hold)", function()
            Swallow:EndHold()
        end)
    else
        self._hold_menu = self._main_menu:AddCommand("Hold at location", function()
            Swallow:Hold()
        end)
    end
    return self
end

function Swallow:DisableHold()
Debug("nisse - Swallow:DisableHold :: self: " .. DumpPretty(self))    
    if self._is_holding then self:EndHold() end
    self._is_hold_enabled = false
    if self._hold_menu then self._hold_menu:Remove() end
    return self
end

function Swallow:EnableRTB()
    if not self._main_menu then return self end
    self._rtb_menu = self._main_menu:AddMenu("CANCEL mission")
    self._rtb_menu:AddCommand("CONFIRM CANCEL mission", function()
        Swallow:MissionAbortedManually()
    end)
    return self
end

function Swallow:ActivateGauntlet(wakeUpAtRangeMeters)
    self.Groups.RED.Gauntlet:Activate()
Debug("nisse - Swallow:ActivateGauntlet :: wakeUpAtRange: " .. Dump(wakeUpAtRangeMeters))
    if isNumber(wakeUpAtRangeMeters) then
Debug("nisse - Swallow:ActivateGauntlet :: gauntlet is in GREEN state until hostiles gets to " .. UTILS.MetersToNM(wakeUpAtRangeMeters) .. " nm")
        self.Groups.RED.Gauntlet:OptionAlarmStateGreen()
        local locGauntlet = DCAF.Location.Resolve(self.Groups.RED.Gauntlet)
        locGauntlet:OnUnitTypesInRange(self.WakeGauntletTypes, wakeUpAtRangeMeters, Coalition.Blue, function()
Debug("nisse - Swallow:ActivateGauntlet :: wakes up gauntlet! :: hostiles at ".. UTILS.MetersToNM(wakeUpAtRangeMeters) .. " nm...")
            Swallow:ActivateGauntlet()
        end)
        return self
    end
Debug("nisse - Swallow:ActivateGauntlet :: wakes up gauntlet!")
    self.Groups.RED.Gauntlet:OptionAlarmStateRed()
    DCAF.delay(function()
        if not self.Groups.RED.Gauntlet:IsAlive() then return end
        self:Send(self.MSG.GauntletActive)
    end, 30)
    self:_debug_addCASmenu()
end

function Swallow:_topDogActualScolding(msg, delay)
    DCAF.delay(function()
        -- temporarily tunes Guard to give everyone a dress-down for failing the mission...
        self.TTS:Tune(Frequencies.Guard)
        self:SendActual(msg)
        self.TTS:Detune()
    end, delay or Minutes(2))
end

function Swallow:MissionAbortedManually()
    if self._is_aborted then return end
    self._is_aborted = true
    self:DisableHold()
    if self._rtb_menu then self._rtb_menu:Remove(true) end
    self:Send(self.MSG.MissionAbortedManually)
    self:_topDogActualScolding(self.MSG.TDA_ScoldingThreatTooHigh, Minutes(2))
    if self._is_in_syria then
        Divert(self.Groups.BLU.Hercs_1)
    else
        Divert(self.Groups.BLU.Hercs_1, "RTB")
    end
end

function Swallow:AbortOnGauntletActive()
    if not self.Groups.RED.Gauntlet:IsAlive() then return end
    self:DisableHold()
    if self._rtb_menu then self._rtb_menu:Remove(true) end
    Divert(self.Groups.BLU.Hercs_1)
    self:Send(self.MSG.MissionAbortedGauntletAwake)
    self:_topDogActualScolding(self.MSG.TDA_ScoldingThreatTooHigh, Minutes(2))
end

function Swallow:MissionComplete()
    if self._rtb_menu then self._rtb_menu:Remove(true) end
    self:Send(self.MSG.MissionComplete)
end

-- function Swallow:CAS_Request()
--     if not self.Groups.RED.Gauntlet:IsAlive() then return end
--     self.Groups.RED.Gauntlet:GetUnit(1):Explode(1500, 10)
--     self._CAS_menu:Remove(true)
-- end

function Swallow:Debug()
    self._debug = true
    return self
end

function Swallow:_debug_addCASmenu()
    if not self._main_menu or not self._debug then return end
    Swallow._CAS_menu = Swallow._main_menu:AddCommand("- debug - Destroy Gauntlet", function()
        Swallow:CAS_Request()
    end)
end

Swallow._main_menu = GM_Menu:AddMenu(_codeword)
Swallow._start_menu = Swallow._main_menu:AddCommand("Start", function()
    Swallow:Start(TTS_Top_Dog)
end)

-- Debug("sausage →→ " .. DumpPrettyDeep(Swallow))