local env              = select(2, ...)

local CreateFrame      = CreateFrame
local type             = type
local setmetatable     = setmetatable
local error            = error
local math_pi          = math.pi

local UIAnim_Processor = env.WPM:Import("wpm_modules\\ui-anim\\processor")
local UIAnim_Enum      = env.WPM:Import("wpm_modules\\ui-anim\\enum")
local UIAnim_Engine    = env.WPM:New("wpm_modules\\ui-anim\\engine")


-- Shared
----------------------------------------------------------------------------------------------------

local MIN_TICK                  = 1 / 60
local STATE_WAIT                = 0
local STATE_PLAY                = 1
local STATE_LOOP_DELAY          = 2

local APPLY_METHOD              = 1
local APPLY_POS_X               = 2
local APPLY_POS_Y               = 3
local APPLY_ROTATION            = 4

local LOOP_YOYO                 = UIAnim_Enum.Looping and UIAnim_Enum.Looping.Yoyo

local Processor_Apply           = UIAnim_Processor.Apply
local Processor_Read            = UIAnim_Processor.Read
local Processor_GetEasing       = UIAnim_Processor.GetEasing
local Processor_PrepareApply    = UIAnim_Processor.PrepareApply
local Processor_ResolveTarget   = UIAnim_Processor.ResolveTarget
local LINEAR_EASE               = Processor_GetEasing(UIAnim_Enum.Easing.Linear)

local activeInstances           = {}
local activeInstanceCount       = 0
local instancePool              = {}
local instancePoolCount         = 0
local wrapperRegistry           = setmetatable({}, { __mode = "k" })
local currentWrapper            = nil
local currentWrapperIsAnimation = false
local currentAnimationName      = nil
local currentRunId              = 0
local lastPlayedWrapper         = nil
local updateFrame               = CreateFrame("Frame")
local isRunning                 = false
local nextDefId                 = 0


-- Internal
----------------------------------------------------------------------------------------------------

local function PushActive(instance)
    activeInstanceCount = activeInstanceCount + 1
    activeInstances[activeInstanceCount] = instance
    if not isRunning then
        updateFrame:SetScript("OnUpdate", UIAnim_Engine.OnUpdate)
        isRunning = true
    end
end

local function RemoveActive(index)
    local inst = activeInstances[index]
    if not inst then return end
    local lastIdx = activeInstanceCount
    if index ~= lastIdx then activeInstances[index] = activeInstances[lastIdx] end
    activeInstances[lastIdx] = nil
    activeInstanceCount = lastIdx - 1
    local info = inst.wrapperInfo
    if info and info.pendingCount > 0 then
        info.pendingCount = info.pendingCount - 1
        if info.pendingCount == 0 then NotifyFinish(info) end
    end
    if instancePoolCount < 100 then
        instancePoolCount = instancePoolCount + 1
        instancePool[instancePoolCount] = inst
    end
    if activeInstanceCount == 0 and isRunning then
        updateFrame:SetScript("OnUpdate", nil)
        isRunning = false
    end
end

function NotifyFinish(info)
    if not info then return end
    local pending = (info.pendingCount or 0) - 1
    info.pendingCount = pending > 0 and pending or 0
    if pending <= 0 and info.finishCallback then
        local cb = info.finishCallback
        info.finishCallback = nil
        cb()
    end
end

local function FastApply(inst, value)
    local method, kind = inst.applyMethod, inst.applyKind
    if not method then return end
    if kind == APPLY_METHOD then
        method(inst.target, value)
    elseif kind == APPLY_POS_X then
        method(inst.target, inst.applyPoint, inst.applyRelativeTo, inst.applyRelativePoint, value, inst.applyOffsetY)
    elseif kind == APPLY_POS_Y then
        method(inst.target, inst.applyPoint, inst.applyRelativeTo, inst.applyRelativePoint, inst.applyOffsetX, value)
    elseif kind == APPLY_ROTATION then
        method(inst.target, value * math_pi / 180)
    end
end


local function TriggerStart(inst)
    local info = inst.wrapperInfo
    if not info or info.startNotified then return end
    info.startNotified = true
    if info.startCallback then
        local cb = info.startCallback
        info.startCallback = nil
        cb()
    end
end


local function FinalizeInstance(inst)
    if not inst or inst.loopType then return end
    local endVal = inst.dir == 1 and inst.to or inst.from
    if endVal ~= nil then FastApply(inst, endVal) end
end


-- Definition Prototype
----------------------------------------------------------------------------------------------------

local DefProto = {}
DefProto.__index = DefProto

local function ResetDefinition(def)
    def.__property, def.__duration, def.__from, def.__to, def.__loopType = nil, nil, nil, nil, nil
    def.__easing, def.__hasFrom, def.__loopDelayStart, def.__loopDelayEnd, def.__waitStart = "Linear", false, 0, 0, 0
    return def
end

local function AllocateDefinition()
    nextDefId = nextDefId + 1
    local def = ResetDefinition({})
    def.__id = nextDefId
    return setmetatable(def, DefProto)
end

function DefProto:wait(s)           self.__waitStart = s or 0;              return self end
function DefProto:property(p)       self.__property = p;                    return self end
function DefProto:duration(s)       self.__duration = s;                    return self end
function DefProto:easing(e)         self.__easing = e;                      return self end
function DefProto:from(v)           self.__from, self.__hasFrom = v, true;  return self end
function DefProto:to(v)             self.__to = v;                          return self end
function DefProto:loop(t)           self.__loopType = t;                    return self end
function DefProto:loopDelayStart(s) self.__loopDelayStart = s or 0;         return self end
function DefProto:loopDelayEnd(s)   self.__loopDelayEnd = s or 0;           return self end

local function CreateInstance(def, target, wrapper, wrapperInfo, runId)
    local inst
    if instancePoolCount > 0 then
        inst = instancePool[instancePoolCount]
        instancePool[instancePoolCount] = nil
        instancePoolCount = instancePoolCount - 1
    else
        inst = {}
    end
    local loopType = def.__loopType
    local duration = def.__duration or 0
    local info = wrapperInfo or (wrapper and wrapperRegistry[wrapper])
    local prop = def.__property
    inst.target, inst.property, inst.duration = target, prop, duration
    inst.easing = Processor_GetEasing(def.__easing)
    inst.from = def.__hasFrom and def.__from or nil
    inst.to, inst.loopType = def.__to, loopType
    inst.loopDelayS, inst.loopDelayE = def.__loopDelayStart or 0, def.__loopDelayEnd or 0
    inst.dir, inst.t, inst.timer, inst.accum = 1, 0, 0, 0
    inst.wrapper, inst.wrapperInfo = wrapper, info
    inst.runId = runId or currentRunId
    inst.stateName = info and info.activeStateName or nil
    inst.defId = def.__id
    inst.hasBeenVisible = target.IsVisible and target:IsVisible() or false
    inst.invDuration = duration > 0 and (1 / duration) or 0
    if target then
        inst.applyKind, inst.applyMethod, inst.applyPoint, inst.applyRelativeTo, inst.applyRelativePoint, inst.applyOffsetX, inst.applyOffsetY = Processor_PrepareApply(target, prop)
    end
    local startDelay = (def.__waitStart or 0) + (loopType and (def.__loopDelayStart or 0) or 0)
    if startDelay > 0 then
        inst.state, inst.timer = STATE_WAIT, startDelay
    else
        inst.state = STATE_PLAY
        TriggerStart(inst)
    end
    if not inst.from then inst.from = Processor_Read(target, prop) end
    inst.delta = (inst.to or 0) - (inst.from or 0)
    return inst
end

local function StopExistingDefinitionInstance(wrapper, definitionId, target)
    if not (wrapper and definitionId) then return end
    local i = 1
    while i <= activeInstanceCount do
        local inst = activeInstances[i]
        if inst and inst.wrapper == wrapper and inst.defId == definitionId and ((not target) or inst.target == target) then
            RemoveActive(i)
            return
        end
        i = i + 1
    end
end

function DefProto:Play(target)
    local prop, dur, toVal = self.__property, self.__duration, self.__to
    if not (prop and dur and toVal ~= nil) then return self end
    if target == nil then error("UIAnim.Animate:Play requires a target.", 2) end
    local resolved = Processor_ResolveTarget(target)
    if not resolved then return self end
    local wrapper = currentWrapper
    if wrapper and self.__id then StopExistingDefinitionInstance(wrapper, self.__id, resolved) end
    local isLooping = self.__loopType ~= nil
    local info = wrapper and wrapperRegistry[wrapper]
    local isAnim = currentWrapperIsAnimation
    if not isLooping and info and not isAnim then info.pendingCount = info.pendingCount + 1 end
    if dur <= 0 then
        Processor_Apply(resolved, prop, toVal)
        if not isLooping and info and not isAnim then NotifyFinish(info) end
        return self
    end
    local inst = CreateInstance(self, resolved, wrapper, info, nil)
    if not inst.target then
        if not isLooping and info and not isAnim then NotifyFinish(info) end
        return self
    end
    if isAnim then inst.isAnimationState, inst.animName = true, currentAnimationName end
    PushActive(inst)
    return self
end


-- Wrapper Prototype
----------------------------------------------------------------------------------------------------

local WrapperProto = {}
WrapperProto.__index = WrapperProto

local function CancelAnimationsByName(wrapper, name)
    if not (wrapper and name) then return end
    local i = 1
    while i <= activeInstanceCount do
        local inst = activeInstances[i]
        if inst and inst.wrapper == wrapper and inst.isAnimationState and inst.animName == name then
            FinalizeInstance(inst)
            RemoveActive(i)
        else
            i = i + 1
        end
    end
end

function WrapperProto:State(name, fn)
    if not name or type(fn) ~= "function" then return self end
    local info = wrapperRegistry[self]
    if info then info.states[name] = fn end
    return self
end

function WrapperProto:Animation(name, fn)
    local info = wrapperRegistry[self]
    if info and type(name) == "string" and type(fn) == "function" then
        info.animationStates = info.animationStates or {}
        info.animationStates[name] = fn
    end
    return self
end

function WrapperProto:Play(target, name)
    local info = wrapperRegistry[self]
    if not info then return self end
    local stateTarget, stateName
    if type(name) == "string" then stateName, stateTarget = name, target
    elseif type(target) == "string" then stateName, stateTarget = target, name
    else stateTarget, stateName = target, name end
    if not stateName then return self end
    local animStates = info.animationStates
    local animFn = animStates and animStates[stateName]
    if animFn then
        CancelAnimationsByName(self, stateName)
        local prevWrapper, prevRunId, prevIsAnim, prevAnimName = currentWrapper, currentRunId, currentWrapperIsAnimation, currentAnimationName
        local animRunIds = info.animationRunIds or {}
        info.animationRunIds = animRunIds
        local nextRun = (animRunIds[stateName] or 0) + 1
        animRunIds[stateName] = nextRun
        currentWrapper, currentRunId, currentWrapperIsAnimation, currentAnimationName = self, nextRun, true, stateName
        animFn(stateTarget)
        currentWrapper, currentRunId, currentWrapperIsAnimation, currentAnimationName = prevWrapper, prevRunId, prevIsAnim, prevAnimName
        return self
    end
    self:Stop(false)
    info.runId = info.runId + 1
    info.pendingCount, info.finishCallback, info.startCallback, info.startNotified = 0, nil, nil, false
    local stateFn = info.states[stateName]
    if stateFn then
        currentWrapper, currentRunId = self, info.runId
        info.activeStateName = stateName
        local defCache = info.defCache[stateName]
        if not defCache then
            defCache = { idx = 0 }
            info.defCache[stateName] = defCache
        else
            defCache.idx = 0
        end
        stateFn(stateTarget)
        currentWrapper, currentRunId, info.activeStateName = nil, 0, nil
        lastPlayedWrapper = self
    end
    return self
end

function WrapperProto:IsPlaying(target, name)
    local info = wrapperRegistry[self]
    if not info then return false end
    local queryTarget, queryState
    if name == nil and type(target) == "string" then queryState = target
    else queryTarget, queryState = target, name end
    local resolved = queryTarget and Processor_ResolveTarget(queryTarget)
    for i = 1, activeInstanceCount do
        local inst = activeInstances[i]
        if inst and inst.wrapper == self and inst.runId == (info.runId or 0) then
            if (not queryState or inst.stateName == queryState) and (not resolved or inst.target == resolved) then
                return true
            end
        end
    end
    return false
end

function WrapperProto.onFinish(cb)
    local wrapper = lastPlayedWrapper
    if not wrapper then return WrapperProto end
    local info = wrapperRegistry[wrapper]
    if not info then lastPlayedWrapper = nil; return WrapperProto end
    if cb then
        if (info.pendingCount or 0) == 0 then cb() else info.finishCallback = cb end
    end
    lastPlayedWrapper = nil
    return wrapper
end

function WrapperProto.onStart(cb)
    local wrapper = lastPlayedWrapper
    if not wrapper then return WrapperProto end
    local info = wrapperRegistry[wrapper]
    if not info then lastPlayedWrapper = nil; return WrapperProto end
    if cb then
        if info.startNotified then cb() else info.startCallback = cb end
    end
    return wrapper
end

function WrapperProto:Stop(cancelAnims)
    local cancelFlag = cancelAnims ~= false
    local info = wrapperRegistry[self]
    if not info then return self end
    info.runId = info.runId + 1
    info.pendingCount, info.finishCallback, info.startCallback, info.startNotified = 0, nil, nil, false
    local i = 1
    while i <= activeInstanceCount do
        local inst = activeInstances[i]
        if inst and inst.wrapper == self and (cancelFlag or not inst.isAnimationState) then
            FinalizeInstance(inst)
            RemoveActive(i)
        else
            i = i + 1
        end
    end
    return self
end


-- Engine Update
----------------------------------------------------------------------------------------------------

local function StepInstance(inst, dt)
    local info = inst.wrapperInfo
    if info then
        if inst.isAnimationState then
            local ids = info.animationRunIds
            if inst.runId ~= (ids and ids[inst.animName] or 0) then return true end
        elseif inst.runId ~= info.runId then
            return true
        end
    elseif inst.wrapper then
        info = wrapperRegistry[inst.wrapper]
        if not info or inst.runId ~= info.runId then return true end
        inst.wrapperInfo = info
    end
    local accum = inst.accum + dt
    if accum < MIN_TICK then inst.accum = accum; return false end
    inst.accum = 0
    local remain = accum
    while remain > 0 do
        local state = inst.state
        if state == STATE_WAIT then
            local timer = inst.timer
            if remain < timer then inst.timer = timer - remain; return false end
            remain = remain - timer
            inst.state, inst.t, inst.timer = STATE_PLAY, 0, 0
            TriggerStart(inst)
        elseif state == STATE_PLAY then
            local dur, elapsed = inst.duration, inst.t
            local timeLeft = dur - elapsed
            if remain < timeLeft then
                elapsed = elapsed + remain
                inst.t, remain = elapsed, 0
            else
                elapsed, inst.t = dur, dur
                remain = remain - timeLeft
            end
            local ease = inst.easing
            local norm = elapsed * inst.invDuration
            local prog = ease == LINEAR_EASE and norm or ease(norm)
            local fromVal, toVal, dir = inst.from, inst.to, inst.dir
            local val = dir == 1 and (fromVal + inst.delta * prog) or (toVal - inst.delta * prog)
            FastApply(inst, val)
            local tgt = inst.target
            if tgt.IsVisible and not tgt:IsVisible() then
                if inst.hasBeenVisible then
                    if not inst.loopType and toVal ~= nil then FastApply(inst, toVal) end
                    if info and not inst.isAnimationState then NotifyFinish(info) end
                    return true
                end
            else
                inst.hasBeenVisible = true
            end
            if elapsed >= dur then
                local loop = inst.loopType
                if not loop then
                    FastApply(inst, dir == 1 and toVal or fromVal)
                    if info then NotifyFinish(info) end
                    return true
                end
                if loop == LOOP_YOYO then inst.dir = -dir end
                local delayE = inst.loopDelayE
                if delayE > 0 then
                    inst.state, inst.timer = STATE_LOOP_DELAY, delayE
                else
                    inst.state, inst.t, inst.timer = STATE_PLAY, 0, 0
                    TriggerStart(inst)
                    local delayS = inst.loopDelayS
                    if delayS > 0 then inst.state, inst.timer = STATE_WAIT, delayS end
                end
            else
                return false
            end
        elseif state == STATE_LOOP_DELAY then
            local timer = inst.timer
            if remain < timer then inst.timer = timer - remain; return false end
            remain = remain - timer
            inst.state, inst.t, inst.timer = STATE_PLAY, 0, 0
            TriggerStart(inst)
            local delayS = inst.loopDelayS
            if delayS > 0 then inst.state, inst.timer = STATE_WAIT, delayS end
        else
            return true
        end
    end
    return false
end

function UIAnim_Engine.OnUpdate(_, dt)
    if activeInstanceCount == 0 or not dt or dt <= 0 then return end
    local i = 1
    while i <= activeInstanceCount do
        local inst = activeInstances[i]
        if not inst or StepInstance(inst, dt) then RemoveActive(i) else i = i + 1 end
    end
end


-- API
----------------------------------------------------------------------------------------------------

function UIAnim_Engine.New()
    local wrapper = {}
    wrapperRegistry[wrapper] = { states = {}, runId = 0, pendingCount = 0, defCache = {}, startNotified = false, animationRunIds = {} }
    return setmetatable(wrapper, WrapperProto)
end

function UIAnim_Engine.Animate()
    if currentWrapper then
        local info = wrapperRegistry[currentWrapper]
        if info and info.activeStateName then
            local cache = info.defCache
            local defs = cache[info.activeStateName]
            if not defs then defs = { idx = 0 }; cache[info.activeStateName] = defs end
            local idx = defs.idx + 1
            defs.idx = idx
            local cached = defs[idx]
            if cached then ResetDefinition(cached); return cached end
            local new = AllocateDefinition()
            defs[idx] = new
            return new
        end
    end
    return AllocateDefinition()
end
