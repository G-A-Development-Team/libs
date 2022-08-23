local function using(pkgn) file.Write( "\\using/json.lua", http.Get( "https://raw.githubusercontent.com/G-A-Development-Team/libs/main/json.lua" ) ) LoadScript("\\using/json.lua") local pkg = json.decode(http.Get("https://raw.githubusercontent.com/G-A-Development-Team/Using/main/using.json"))["pkgs"][ pkgn ] if pkg ~= nil then file.Write( "\\using/" .. pkgn .. ".lua", http.Get( pkg ) ) LoadScript("\\using/" .. pkgn .. ".lua") else print("[using] package doesn't exist. {" .. pkgn .. "}") end end

local function GetScreenWidth() local w, h = draw.GetScreenSize()  return w end

local function GetScreenHeight() local w, h = draw.GetScreenSize() return h end

local Globals = {
    thruclick = false,
    dummywindow = nil,
    openkey = 35,
    jsonkeycodes = nil,
    disableoverlay = true,

    GetDisableOverlay = function(self) return self.disableoverlay end,
    GetOpenKey = function(self) return self.openkey end,
    SetThruClick = function(self, bool) self.thruclick = bool end,
    GetThruClick = function(self) return self.thruclick end,
    GetDummyWindow = function(self) return self.dummywindow end,
    GetMousePosX = function(self) local MouseX, MouseY = input.GetMousePos() return MouseX end,
    GetMousePosY = function(self) local MouseX, MouseY = input.GetMousePos() return MouseY end,
    GetJsonKeyCodes = function(self) return self.jsonkeycodes end,

    InRect = function(self, X1, Y1, X2, Y2)  return self:GetMousePosX() >= X1 and self:GetMousePosX() < X2 and self:GetMousePosY() >= Y1 and self:GetMousePosY() < Y2  end,

    Init = function(self)
        --Create blank dummywindow
        self.dummywindow = gui.Window("dummywindow", "Dummy Window", 1, 1, 1, 1)
        self.dummywindow:SetOpenKey(self:GetOpenKey())
        self.dummywindow:SetActive(false)

        self.jsonkeycodes = json.decode(http.Get("https://raw.githubusercontent.com/G-A-Development-Team/libs/main/keycodes.json"))
    end,

    Print = function(self, string)
        print("[AimwareOverlay] " .. string)
    end,

    Center = function(self, itemW, itemH, W, H)
        return (W/2)-(itemW/2), (H/2)-(itemH/2)
    end,

    TranslateKeyCode = function(self, int)
        local json = self:GetJsonKeyCodes()
        for i = 1, #json, 1 do
            if json[i]["Key Code"] == tostring(int) then
                return json[i]["Key"]
            end
        end
    end,
}

local Overlay = {
    x = 0, y = 0,
    w = GetScreenWidth(),
    h = GetScreenHeight(),
    componentsscaling = 1.15,
    componentsscalinglast = 0,

    components = {},
    fonts = {},

    flags = { visible = true, enabled = true, active = false, },

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

    GetComponentsScale = function(self) return self.componentsscaling end,
    SetComponentsScale = function(self, int) self.componentsscaling = int end,
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
    AddComponent = function(self, key, tbl) self.components[key] = tbl return self.components[key] end,
    GetComponets = function(self) return self.components end,
    GetComponet = function(self, key) return self.components[key] end,
    AddFont = function(self, key, font) self.fonts[key] = font end,
    GetFont = function(self, font) return self.fonts[font] end,
    ClearFonts = function(self) self.fonts = {} end,

    CombineComponentTable = function(self, component, X, Y)
        local tbl = {
            x = 0, y = 0,
            flags = { visible = true, enabled = true, active = true, },

            currentx = X,
            currenty = Y,
            hovering = false,
            clicked = false,
            init = false,

            SetFlag = function(self, key, object) self.flags[key] = object end,
            SetEnabled = function(self, bool) self.flags.enabled = bool end,
            SetActive = function(self, bool) self.flags.active = bool end,
            SetVisible = function(self, bool) self.flags.visible = bool end,
            SetInit = function(self, bool) self.init = bool end,
            SetClicked = function(self, bool) self.clicked = bool end,
            SetPosX = function(self, int) self.currentx = int end,
            SetPosY = function(self, int) self.currenty = int end,
            SetHovering = function(self, bool) self.hovering = bool end,
            SetSizeWidth = function(self, int) self.w = int end,
            SetSizeHeight = function(self, int) self.h = int end,
            SetColor = function(self, tbl) self.color = tbl end,
            SetCurrentPosX = function(self, int) self.x = int end,
            SetCurrentPosY = function(self, int) self.y = int end,
            GetClicked = function(self) return self.clicked end,
            GetPosX = function(self) return self.currentx end,
            GetPosY = function(self) return self.currenty end,
            GetHovering = function(self) return self.hovering end,
            GetCurrentPosX = function(self) return self.x end,
            GetCurrentPosY = function(self) return self.y end,
            GetSizeWidth = function(self) return self.w end,
            GetSizeHeight = function(self) return self.h end,
            GetTotalCurrentWidth = function(self) return self:GetCurrentPosX() + self:GetSizeWidth() end,
            GetTotalCurrentHeight = function(self) return self:GetCurrentPosY() + self:GetSizeHeight() end,
            GetColor = function(self) return self.color end,
            GetName = function(self) return self.name end,
            GetInit = function(self) return self.init end,
            GetEnabled = function(self) return self.flags.enabled end,
            GetActive = function(self) return self.flags.active end,
            GetVisible = function(self) return self.flags.visible end,
            GetFlag = function(self, key) return self.flags[key] end,
        }
        local meta = {__index = tbl}
        setmetatable(component, meta)
        return component
    end,

    Draw = function(self)
        if not Globals:GetDisableOverlay() then
            if not self:GetEnabled() then return end
            if not self:GetActive() then return end 
        end

        self:ScalingListener()

        if self:GetVisible() and not Globals:GetDisableOverlay() then
            --Base
            draw.Color(unpack(self:GetColor("Base")))
            draw.FilledRect(self:GetPosX(), self:GetPosY(), self:GetPosX() + self:GetSizeWidth(), self:GetPosY() + self:GetSizeHeight())

            --Base Shadow
            draw.Color(unpack(self:GetColor("BaseShadow")));
            draw.ShadowRect(self:GetPosX(), self:GetPosY(), self:GetPosX() + self:GetSizeWidth(), self:GetPosY() + self:GetSizeHeight(), 100);

            self:ComponentsHandler()
        else
            self:ComponentsHandler()
        end
    end,

    ComponentsHandler = function(self)
        for key, value in pairs(self:GetComponets()) do
            if not value:GetEnabled() then return end

            --Call init function if added
            if value.Init ~= nil then
                if not value:GetInit() then
                    value:Init()
                    value:SetInit(true)
                end
            end

            if not value:GetActive() then return end
    
            if value:GetVisible() then
                --Scissoring components of window components
                if value:GetName() == "window" then
                    draw.SetScissorRect(self:GetPosX(), self:GetPosY(), self:GetSizeWidth() * self:GetComponentsScale(), self:GetSizeHeight());
                    
                    value:UpdateArgs({X = self:GetPosX(), Y = self:GetPosY(), Width = self:GetSizeWidth(), Height = self:GetSizeHeight(), Scale = self:GetComponentsScale()})
                    value:Draw({X = self:GetPosX(), Y = self:GetPosY(), Width = self:GetSizeWidth() * self:GetComponentsScale(), Height = self:GetSizeHeight(), Scale = self:GetComponentsScale()})
                    
                    draw.SetScissorRect(0, 0, draw.GetScreenSize())
                else
                    value:UpdateArgs({X = self:GetPosX(), Y = self:GetPosY(), Width = self:GetSizeWidth(), Height = self:GetSizeHeight(), Scale = self:GetComponentsScale()})
                    value:Draw({X = self:GetPosX(), Y = self:GetPosY(), Width = self:GetSizeWidth() * self:GetComponentsScale(), Height = self:GetSizeHeight(), Scale = self:GetComponentsScale()})
                end

                --Check if mouse is hovering on component
                if Globals:InRect(value:GetCurrentPosX(), value:GetCurrentPosY(), value:GetCurrentPosX() + value:GetSizeWidth(), value:GetCurrentPosY() + value:GetSizeHeight()) then
                    value:SetHovering(true)

                    if input.IsButtonReleased(1) then value:SetClicked(true) else value:SetClicked(false) end
                else
                    value:SetHovering(false)
                end
            end
        end
    end,

    ScalingListener = function(self)
        if self.componentsscalinglast ~= self:GetComponentsScale() then
            Globals:Print("Scaling Changed from " .. self.componentsscalinglast .. " to " .. self:GetComponentsScale())

            --Update scaling on fonts
            self:ClearFonts()
            self:CreateFonts()

            self.componentsscalinglast = self:GetComponentsScale()
        end
    end,

    CreateFonts = function(self)
        self:AddFont("label", draw.CreateFont("Bahnschrift", 20 * self:GetComponentsScale(), 100))
        self:AddFont("button", draw.CreateFont("Bahnschrift", 20 * self:GetComponentsScale(), 100))
        self:AddFont("window", draw.CreateFont("Bahnschrift", 20 * self:GetComponentsScale(), 100))
        self:AddFont("inputbox", draw.CreateFont("Bahnschrift", 20 * self:GetComponentsScale(), 100))
        self:AddFont("checkbox", draw.CreateFont("Bahnschrift", 20 * self:GetComponentsScale(), 100))
    end,

    Init = function(self)
        self.componentsscalinglast = self:GetComponentsScale()
        self:CreateFonts()
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

local Label = function(X, Y, Options)
    local component = {
        name = "label",
        text = Options["Text"],
        color = Options["Color"],
        font = Options["Font"],
        underline = Options["Underline"],
        w = 0, h = 0,
    
        SetText = function(self, string) self.text = string end,
        GetUnderLine = function(self) return self.underline end, 
        GetFont = function(self) return self.font end,
        GetText = function(self) return self.text end,

        UpdateArgs = function(self, args)
            self:SetCurrentPosX(args["X"] + (self:GetPosX() * Overlay:GetComponentsScale()))
            self:SetCurrentPosY(args["Y"] + (self:GetPosY() * Overlay:GetComponentsScale()))

            --Check if custom font was set. If not use default
            if self:GetFont() == nil then
                if Overlay:GetFont(self:GetName()) ~= nil then
                    draw.SetFont(Overlay:GetFont(self:GetName())) 
                end
            else
                draw.SetFont(self:GetFont()) 
            end

            local TextWidth, TextHeight = draw.GetTextSize(self:GetText())
            self:SetSizeWidth(TextWidth)
            self:SetSizeHeight(TextHeight)
        end,
    
        Draw = function(self, args)
            local base = {
                X = self:GetCurrentPosX(),
                Y = self:GetCurrentPosY(),
                W = self:GetCurrentPosX() + (self:GetSizeWidth() * Overlay:GetComponentsScale()),
                H = self:GetCurrentPosY() + (self:GetSizeHeight() * Overlay:GetComponentsScale()),
            }
            --Check if custom font was set. If not use default
            if self:GetFont() == nil then
                draw.SetFont(Overlay:GetFont(self:GetName())) else draw.SetFont(self:GetFont()) end

            draw.Color(unpack(self:GetColor()))
            draw.TextShadow(base.X, base.Y, self:GetText())

            --If mouse is hovering over the component
            if self:GetHovering() then
                if self:GetUnderLine() then
                    draw.Color(unpack(self:GetColor()))
                    draw.FilledRect(base.X, self:GetTotalCurrentHeight() + (5 * Overlay:GetComponentsScale()), self:GetTotalCurrentWidth(), self:GetTotalCurrentHeight() + (8 * Overlay:GetComponentsScale()))
                end
            end

            --Execute Click function
            if self:GetClicked() and Options["Click"] ~= nil then Options["Click"]() end
        end,
    }
    return Overlay:CombineComponentTable(component, X, Y)
end

local Picture = function(X, Y, W, H, Options)
    local component = {
        name = "picture",
        alpha = Options["Alpha"] or 255,
        imageurl = Options["URL"],
        loadedtexture = nil,
        w = W, h = H,

        SetAlpha = function(self, int) self.alpha = int end,
        GetAlpha = function(self) return self.alpha end,
        GetImageURL = function(self) return self.imageurl end,
        SetLoadedTexture = function(self, texture) self.loadedtexture = texture end,
        GetLoadedTexture = function(self) return self.loadedtexture end,

        Init = function(self)
            local ImageData = http.Get(self:GetImageURL())
            if ImageData == nil then return end

            local ImageRGBA, ImageWidth, ImageHeight = common.DecodePNG(ImageData)
            self:SetLoadedTexture(draw.CreateTexture(ImageRGBA, ImageWidth, ImageHeight))
        end,

        UpdateArgs = function(self, args)
            self:SetCurrentPosX(args["X"] + (self:GetPosX() * Overlay:GetComponentsScale()))
            self:SetCurrentPosY(args["Y"] + (self:GetPosY() * Overlay:GetComponentsScale()))
        end,
    
        Draw = function(self, args)
            draw.Color(255, 255, 255, self:GetAlpha())
            draw.SetTexture(self:GetLoadedTexture())
            draw.FilledRect(self:GetCurrentPosX(), self:GetCurrentPosY(), self:GetTotalCurrentWidth() * Overlay:GetComponentsScale(), self:GetTotalCurrentHeight() * Overlay:GetComponentsScale())
            draw.SetTexture(nil)

            --Execute Click function
            if self:GetClicked() and Options["Click"] ~= nil then Options["Click"]() end
        end,
    }
    return Overlay:CombineComponentTable(component, X, Y)
end

local Button = function(X, Y, W, H, Options)
    local component = {
        name = "button",
        text = Options["Text"],
        w = W, h = H,

        colors = {
          base = {40, 40, 40, 255},
          baseshadow = {10, 10, 10, 255},
          border = {10, 10, 10, 255},
          text = {255, 255, 255, 255},
          basehover = {97, 96, 96, 255},
        },

        GetText = function(self) return self.text end,
        SetText = function(self, string) self.text = string end,
        GetDefaultColor = function(self, key) return self.colors[string.lower(key)] end,

        Init = function(self)
            self:SetSizeWidth(self:GetSizeWidth() * Overlay:GetComponentsScale())
            self:SetSizeHeight(self:GetSizeHeight() * Overlay:GetComponentsScale())
        end,

        UpdateArgs = function(self, args)
            self:SetCurrentPosX(args["X"] + (self:GetPosX() * Overlay:GetComponentsScale()))
            self:SetCurrentPosY(args["Y"] + (self:GetPosY() * Overlay:GetComponentsScale()))
        end,

        Draw = function(self, args)
            local base = {
                X = self:GetCurrentPosX(),
                Y = self:GetCurrentPosY(),
                W = self:GetTotalCurrentWidth(),
                H = self:GetTotalCurrentHeight(),
            }
            --Base Shadow
            draw.Color(unpack(self:GetDefaultColor("BaseShadow")))
            draw.ShadowRect(base.X, base.Y, base.W, base.H, 10)
            
            --Base
            draw.Color(unpack(self:GetDefaultColor("Base")))
            draw.FilledRect(base.X, base.Y, base.W, base.H)

            --If mouse is hovering over the component
            if self:GetHovering() and not self:GetClicked() then
                draw.Color(unpack(self:GetDefaultColor("BaseHover")))
                draw.FilledRect(base.X, base.Y, base.W, base.H)
            end

            --Base Border
            draw.Color(unpack(self:GetDefaultColor("Border")))
            draw.OutlinedRect(base.X, base.Y, base.W, base.H)

            --Text
            draw.SetFont(Overlay:GetFont(self:GetName()))
            draw.Color(unpack(self:GetDefaultColor("Text")))

            local TextWidth, TextHeight = draw.GetTextSize(self:GetText())
            local centerX, centerY = center(TextWidth, TextHeight, self:GetSizeWidth(), self:GetSizeHeight())
            draw.TextShadow(base.X + centerX, base.Y + centerY, self:GetText())

            --Execute Click function
            if self:GetClicked() and Options["Click"] ~= nil then 
                --Base Click Effect
                draw.Color(unpack(self:GetDefaultColor("Base")))
                draw.FilledRect(base.X, base.Y, base.W, base.H)
                Options["Click"]()
            end
        end,
    }
    return Overlay:CombineComponentTable(component, X, Y)
end

local InputBox = function(X, Y, W, H, Options)
    local component = {
        name = "inputbox",
        text = Options["Text"],
        w = W, h = H,

        colors = {
          base = {40, 40, 40, 255},
          baseshadow = {10, 10, 10, 255},
          border = {10, 10, 10, 255},
          text = {255, 255, 255, 255},
          basehover = {97, 96, 96, 255},
        },

        GetText = function(self) if self.text == nil then self.text = "" end return self.text end,
        SetText = function(self, string) self.text = string end,
        GetDefaultColor = function(self, key) return self.colors[string.lower(key)] end,

        Init = function(self)
            self:SetSizeWidth(self:GetSizeWidth() * Overlay:GetComponentsScale())
            self:SetSizeHeight(self:GetSizeHeight() * Overlay:GetComponentsScale())
            self:SetFlag("selected", false)
            self:SetFlag("shift", false)
            self:SetFlag("overflow", 0)
        end,

        UpdateArgs = function(self, args)
            self:SetCurrentPosX(args["X"] + (self:GetPosX() * Overlay:GetComponentsScale()))
            self:SetCurrentPosY(args["Y"] + (self:GetPosY() * Overlay:GetComponentsScale()))
        end,

        TextOverfillCheck = function(self, operation)
            local TextWidth, TextHeight = draw.GetTextSize(self:GetText())
            --Move text to fit
            if TextWidth > (150 * Overlay:GetComponentsScale()) and operation == "+" then
                local lastchar = string.sub(self:GetText(), -1)
                local charsize = draw.GetTextSize(lastchar)
                self:SetFlag("overflow", self:GetFlag("overflow") + charsize)
            end
            if TextWidth > (150 * Overlay:GetComponentsScale()) and operation == "-" then
                local lastchar = string.sub(self:GetText(), -1)
                local charsize = draw.GetTextSize(lastchar)
                self:SetFlag("overflow", self:GetFlag("overflow") - charsize)
            end
        end,

        Draw = function(self, args)
            local base = {
                X = self:GetCurrentPosX(),
                Y = self:GetCurrentPosY(),
                W = self:GetTotalCurrentWidth(),
                H = self:GetTotalCurrentHeight(),
            }
            
            --Base Shadow
            draw.Color(unpack(self:GetDefaultColor("BaseShadow")))
            draw.ShadowRect(base.X, base.Y, base.W, base.H, 10)
            
            --Base
            draw.Color(unpack(self:GetDefaultColor("Base")))
            draw.FilledRect(base.X, base.Y, base.W, base.H)

            --If mouse is hovering over the component
            if self:GetHovering() and not self:GetClicked() then
                draw.Color(unpack(self:GetDefaultColor("BaseHover")))
                draw.FilledRect(base.X, base.Y, base.W, base.H)
            end

            --Base Border
            draw.Color(unpack(self:GetDefaultColor("Border")))
            draw.OutlinedRect(base.X, base.Y, base.W, base.H)

            --Execute Click function
            if self:GetClicked() then 
                self:SetFlag("selected", not self:GetFlag("selected"))
                --Base Click Effect
                draw.Color(unpack(self:GetDefaultColor("Base")))
                draw.FilledRect(base.X, base.Y, base.W, base.H)
            end

            --Handle key input
            if self:GetFlag("selected") then
                --Mouse Left Click Key
                if input.IsButtonPressed(1) then
                    self:SetFlag("selected", false)
                end
                --Highlight
                draw.Color(unpack(self:GetDefaultColor("BaseHover")))
                draw.FilledRect(base.X, base.Y, base.W, base.H)

                --Handle key setting and reading
                for i = 3, 255, 1 do
                    local key = Globals:TranslateKeyCode(i)
                    if input.IsButtonDown(i) then
                        if key == "Shift" then self:SetFlag("shift", true) end
                    end

                    if input.IsButtonReleased(i) then
                        if key == "Shift" then self:SetFlag("shift", false) end
                    end

                    if input.IsButtonPressed(32) then
                        self:SetText(self:GetText() .. " ")
                        self:TextOverfillCheck("+")
                        break
                    end

                    if input.IsButtonPressed(i) then
                        if key == "Shift" then break end
                        
                        if key == "Space" then break end

                        if key == "Backspace" then
                            --Remove last character
                            self:TextOverfillCheck("-")
                            self:SetText(self:GetText():sub(1, -2))
                            break
                        end

                        if key == "Enter" then self:SetFlag("selected", false) break end

                        if self:GetFlag("shift") then
                            self:SetText(self:GetText() .. string.upper(Globals:TranslateKeyCode(i)))
                            self:TextOverfillCheck("+")
                            break
                        end

                        self:SetText(self:GetText() .. Globals:TranslateKeyCode(i))
                        self:TextOverfillCheck("+")
                    end
                end
            end

            --Text
            draw.SetFont(Overlay:GetFont(self:GetName()))
            draw.Color(unpack(self:GetDefaultColor("Text")))

            local TextWidth, TextHeight = draw.GetTextSize(self:GetText())
            local centerX, centerY = center(TextWidth, TextHeight, self:GetSizeWidth(), self:GetSizeHeight())

            --Scissor Text overfill
            draw.SetScissorRect(base.X, base.Y, self:GetSizeWidth() - (10 * Overlay:GetComponentsScale()), self:GetSizeHeight())
            
            draw.TextShadow(base.X + (10 * Overlay:GetComponentsScale()) - self:GetFlag("overflow"), base.Y + centerY, self:GetText())

            --Reset scissoring
            draw.SetScissorRect(0, 0, draw.GetScreenSize())
        end,
    }
    return Overlay:CombineComponentTable(component, X, Y)
end

local Checkbox = function(X, Y, W, H, Options)
    local component = {
        name = "checkbox",
        checked = Options["Checked"],
        w = W, h = H,

        colors = {
          base = {40, 40, 40, 255},
          baseshadow = {10, 10, 10, 255},
          border = {10, 10, 10, 255},
          text = {255, 255, 255, 255},
          basehover = {97, 96, 96, 255},
        },

        GetChecked = function(self) return self.checked end,
        SetChecked = function(self, bool) self.checked = bool end,
        GetDefaultColor = function(self, key) return self.colors[string.lower(key)] end,

        Init = function(self)
            self:SetSizeWidth(self:GetSizeWidth() * Overlay:GetComponentsScale())
            self:SetSizeHeight(self:GetSizeHeight() * Overlay:GetComponentsScale())
        end,

        UpdateArgs = function(self, args)
            self:SetCurrentPosX(args["X"] + (self:GetPosX() * Overlay:GetComponentsScale()))
            self:SetCurrentPosY(args["Y"] + (self:GetPosY() * Overlay:GetComponentsScale()))
        end,

        Draw = function(self, args)
            local base = {
                X = self:GetCurrentPosX(),
                Y = self:GetCurrentPosY(),
                W = self:GetTotalCurrentWidth(),
                H = self:GetTotalCurrentHeight(),
            }
            --Base Shadow
            draw.Color(unpack(self:GetDefaultColor("BaseShadow")))
            draw.ShadowRect(base.X, base.Y, base.W, base.H, 10)
            
            --Base
            draw.Color(unpack(self:GetDefaultColor("Base")))
            draw.FilledRect(base.X, base.Y, base.W, base.H)

            --If mouse is hovering over the component
            if self:GetHovering() and not self:GetClicked() then
                draw.Color(unpack(self:GetDefaultColor("BaseHover")))
                draw.FilledRect(base.X, base.Y, base.W, base.H)
            end

            --Base Border
            draw.Color(unpack(self:GetDefaultColor("Border")))
            draw.OutlinedRect(base.X, base.Y, base.W, base.H)

            if self:GetChecked() then
                --Selected Base
                draw.Color(unpack(self:GetDefaultColor("BaseHover")))
                draw.FilledRect(base.X + (5 * Overlay:GetComponentsScale()), base.Y + (5 * Overlay:GetComponentsScale()), base.W - (5 * Overlay:GetComponentsScale()), base.H - (5 * Overlay:GetComponentsScale()))
            
                --Selected Border
                draw.Color(unpack(self:GetDefaultColor("Border")))
                draw.OutlinedRect(base.X + (5 * Overlay:GetComponentsScale()), base.Y + (5 * Overlay:GetComponentsScale()), base.W - (5 * Overlay:GetComponentsScale()), base.H - (5 * Overlay:GetComponentsScale()))
            end

            --Execute Click function
            if self:GetClicked() then 
                if Options["Click"] ~= nil then
                    Options["Click"]()
                end
                self:SetChecked(not self:GetChecked())
                --Base Click Effect
                draw.Color(unpack(self:GetDefaultColor("Base")))
                draw.FilledRect(base.X, base.Y, base.W, base.H)
            end
            
        end,
    }
    return Overlay:CombineComponentTable(component, X, Y)
end

local Window = function(X, Y, W, H, Options)
    local component = {
        name = "window",
        title = Options["Title"],
        move = Options["Move"],
        w = W, h = H,

        components = {},

        colors = {
          base = {50, 50, 50, 255},
          baseshadow = {10, 10, 10, 255},
          border = {10, 10, 10, 255},
          title = {255, 255, 255, 255},
          header = {28, 28, 28, 255},
          headershadow = {10, 10, 10, 255},
        },

        GetMove = function(self) return self.move end,
        GetTitle = function(self) return self.title end,
        GetDefaultColor = function(self, key) return self.colors[string.lower(key)] end,
        AddComponent = function(self, key, tbl) self.components[key] = tbl return self.components[key] end,
        GetComponets = function(self) return self.components end,
        GetComponet = function(self, key) return self.components[key] end,
        SetTitle = function(self, string) self.title = string end,

        ComponentsHandler = function(self)
            for key, value in pairs(self:GetComponets()) do
                if not value:GetEnabled() then return end
    
                --Call init function if added
                if value.Init ~= nil then
                    if not value:GetInit() then
                        value:Init()
                        value:SetInit(true)
                    end
                end
    
                if not value:GetActive() then return end
        
                if value:GetVisible() then
                    draw.SetScissorRect(self:GetPosX(), self:GetPosY() + (30 * Overlay:GetComponentsScale()), self:GetSizeWidth(), self:GetSizeHeight() - (30 * Overlay:GetComponentsScale()));
                    value:UpdateArgs({X = self:GetPosX(), Y = self:GetPosY() + (30 * Overlay:GetComponentsScale()), Width = self:GetSizeWidth(), Height = self:GetSizeHeight(), Scale = Overlay:GetComponentsScale()})
                    value:Draw({X = self:GetPosX(), Y = self:GetPosY() + (30 * Overlay:GetComponentsScale()), Width = self:GetSizeWidth() * Overlay:GetComponentsScale(), Height = self:GetSizeHeight(), Scale = Overlay:GetComponentsScale()})
                    --Reset scissoring
                    draw.SetScissorRect(0, 0, draw.GetScreenSize())

                    --Check if mouse is hovering on component
                    if Globals:InRect(value:GetCurrentPosX(), value:GetCurrentPosY(), value:GetCurrentPosX() + value:GetSizeWidth(), value:GetCurrentPosY() + value:GetSizeHeight()) then
                        value:SetHovering(true)
    
                        if input.IsButtonReleased(1) then value:SetClicked(true) else value:SetClicked(false) end
                    else
                        value:SetHovering(false)
                    end
                end
            end
        end,

        Init = function(self)
            self:SetSizeWidth(self:GetSizeWidth() * Overlay:GetComponentsScale())
            self:SetSizeHeight(self:GetSizeHeight() * Overlay:GetComponentsScale())
            self:SetFlag("shouldDrag", false)
            self:SetFlag("dx", 0)
            self:SetFlag("dy", 0)
        end,

        UpdateArgs = function(self, args)
            --Handle window moving and positioning
            if self:GetFlag("shouldDrag") then
                self:SetCurrentPosX(Globals:GetMousePosX() - self:GetFlag("dx"))
                self:SetCurrentPosY(Globals:GetMousePosY() - self:GetFlag("dy"))
                self:SetPosX(self:GetCurrentPosX())
                self:SetPosY(self:GetCurrentPosY())
            else
                self:SetCurrentPosX(args["X"] + (self:GetPosX()))
                self:SetCurrentPosY(args["Y"] + (self:GetPosY()))
            end
        end,

        Draw = function(self, args)
            local base = {
                X = self:GetCurrentPosX(),
                Y = self:GetCurrentPosY(),
                W = self:GetTotalCurrentWidth(),
                H = self:GetTotalCurrentHeight(),
            }
            --Base Shadow
            draw.Color(unpack(self:GetDefaultColor("BaseShadow")))
            draw.ShadowRect(base.X, base.Y, base.W, base.H, 10)
            
            --Base
            draw.Color(unpack(self:GetDefaultColor("Base")))
            draw.FilledRect(base.X, base.Y, base.W, base.H)

            --Header Shadow
            draw.Color(unpack(self:GetDefaultColor("HeaderShadow")))
            draw.ShadowRect(base.X, base.Y, base.W, base.Y + (30 * Overlay:GetComponentsScale()), 2)

            --Header
            draw.Color(unpack(self:GetDefaultColor("Header")))
            draw.FilledRect(base.X, base.Y, base.W, base.Y + (30 * Overlay:GetComponentsScale()))

            --Header Border
            draw.Color(unpack(self:GetDefaultColor("Border")))
            draw.OutlinedRect(base.X, base.Y, base.W, base.Y + (30 * Overlay:GetComponentsScale()))

            --Header Title
            draw.SetFont(Overlay:GetFont(self:GetName()))
            draw.Color(unpack(self:GetDefaultColor("Title")))
            draw.TextShadow(base.X + (10 * Overlay:GetComponentsScale()), base.Y + (10 * Overlay:GetComponentsScale()), self:GetTitle())

            --Base Border
            draw.Color(unpack(self:GetDefaultColor("Border")))
            draw.OutlinedRect(base.X, base.Y, base.W, base.H)

            --If mouse is hovering over the component
            if self:GetHovering() then
            end

            --Handle window moving
            if self:GetMove() then
                if input.IsButtonDown(1) then
                    --Header
                    if Globals:InRect(base.X, base.Y, base.W, base.Y + (30 * Overlay:GetComponentsScale())) then
                        self:SetFlag("shouldDrag", true)
                        self:SetFlag("dx", Globals:GetMousePosX() - base.X)
                        self:SetFlag("dy", Globals:GetMousePosY() - base.Y)
                    end
                else
                    self:SetFlag("shouldDrag", false)
                end
            end

            --Execute Click function
            if self:GetClicked() and Options["Click"] ~= nil then 
                Options["Click"]()
            end

            self:ComponentsHandler()
        end,
    }
    return Overlay:CombineComponentTable(component, X, Y)
end
