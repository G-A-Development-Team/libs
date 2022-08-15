local Globals = {
    thruclick = false,
    dummywindow = nil,
    openkey = 35,

    GetOpenKey = function(self) return self.openkey end,

    SetThruClick = function(self, bool) self.thruclick = bool end,

    GetThruClick = function(self) return self.thruclick end,

    GetDummyWindow = function(self) return self.dummywindow end,

    Init = function(self)
        --Create blank dummywindow
        self.dummywindow = gui.Window("dummywindow", "Dummy Window", 1, 1, 1, 1)
        self.dummywindow:SetOpenKey(self:GetOpenKey())
        self.dummywindow:SetActive(false)
    end,
}

local function GetScreenWidth()
    local w, h = draw.GetScreenSize()
    return w
end

local function GetScreenHeight()
    local w, h = draw.GetScreenSize()
    return h
end

local Overlay = {
    x = 0,
    y = 0,
    w = GetScreenWidth(),
    h = GetScreenHeight(),

    flags = {
        visible = true,
        enabled = true,
        active = false,
    },

    colors = {
        base = {15, 15, 15, 130},
        baseshadow = {20, 20, 20, 255},
    },

    keybinds = {
        [35] = function(self) -- [End]
            self:SetActive(not self:GetActive())
            Globals:SetThruClick(self:GetActive())
        end,
    },

    GetKeybinds = function(self) return self.keybinds end,

    GetEnabled = function(self) return self.flags.enabled end,

    GetActive = function(self) return self.flags.active end,

    SetActive = function(self, bool) self.flags.active = bool end,

    GetVisible = function(self) return self.flags.visible end,

    GetPosX = function(self) return self.x end,

    GetPosY = function(self) return self.y end,

    GetSizeWidth = function(self) return self.w end,

    GetSizeHeight = function(self) return self.h end,

    GetColor = function(self, color) return self.colors[string.lower(color)] end,

    Draw = function(self)
        if not self:GetEnabled() then return end
        if not self:GetActive() then return end

        if self:GetVisible() then
            --Base
            draw.Color(unpack(self:GetColor("Base")))
            draw.FilledRect(self:GetPosX(), self:GetPosY(), self:GetPosX() + self:GetSizeWidth(), self:GetPosY() + self:GetSizeHeight())

            --Base Shadow
            draw.Color(unpack(self:GetColor("BaseShadow")));
            draw.ShadowRect(self:GetPosX(), self:GetPosY(), self:GetPosX() + self:GetSizeWidth(), self:GetPosY() + self:GetSizeHeight(), 100);

        end
    end,

    Init = function(self)

    end,
}

local function KeybindManager()
    for key, value in pairs(Overlay:GetKeybinds()) do
        if input.IsButtonReleased(key) then
            value(Overlay)
        end
    end
end

local function GlobalsManager()
    Globals:GetDummyWindow():SetActive(Globals:GetThruClick())
    Globals:GetDummyWindow():SetInvisible(Globals:GetThruClick())
end

Globals:Init()
Overlay:Init()

callbacks.Register("Draw", "Render", function()
    GlobalsManager()
    KeybindManager()
    Overlay:Draw()
end)
