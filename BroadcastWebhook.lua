local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/habibrodriguez7-art/Library/refs/heads/main/lob.lua"))()
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local CoreGui         = game:GetService("PlayerGui")
local LocalPlayer     = Players.LocalPlayer

local function getHTTPRequest()
    local funcs = {
        request,
        http_request,
        (syn and syn.request),
        (fluxus and fluxus.request),
        (http and http.request),
        (solara and solara.request),
    }
    for _, f in ipairs(funcs) do
        if f and type(f) == "function" then return f end
    end
    return nil
end

local httpRequest = getHTTPRequest()

local TIER_DATA = {
    { name = "Epic",      tier = 4, discordColor = 10181046, r = 179, g = 115, b = 248 },
    { name = "Legendary", tier = 5, discordColor = 15844367, r = 255, g = 185, b = 43  },
    { name = "Mythic",    tier = 6, discordColor = 16711680, r = 255, g = 25,  b = 25  },
    { name = "SECRET",    tier = 7, discordColor = 65535,    r = 24,  g = 255, b = 152 },
    { name = "FORGOTTEN", tier = 8, discordColor = 8421504,  r = 128, g = 128, b = 128 },
}

local Config = {
    WebhookURL = "",
    MinTier    = 4,
    Enabled    = false,
    CustomName = "",
}

local function colorDist(r1,g1,b1, r2,g2,b2)
    return math.sqrt((r1-r2)^2 + (g1-g2)^2 + (b1-b2)^2)
end

local function getTierFromRGB(text)
    local allColors = {}
    for cr, cg, cb in text:gmatch("rgb%((%d+),%s*(%d+),%s*(%d+)%)") do
        table.insert(allColors, { tonumber(cr), tonumber(cg), tonumber(cb) })
    end

    local fishColor = allColors[2] or allColors[1]
    if not fishColor then return nil end

    local r, g, b = fishColor[1], fishColor[2], fishColor[3]

    local closest, closestDist = nil, math.huge
    for _, t in ipairs(TIER_DATA) do
        local d = colorDist(r, g, b, t.r, t.g, t.b)
        if d < closestDist then
            closest = t
            closestDist = d
        end
    end

    if closestDist > 40 then return nil end

    return closest
end

local function parseBodyText(text)
    local clean = text:gsub("<[^>]+>", "")

    if not clean:find("%[Server%]") and not clean:find("%[Global%]") then
        return nil
    end
    if not clean:find("obtained") then return nil end

    local prefix  = clean:find("%[Global%]") and "[Global]" or "[Server]"
    local player  = clean:match("%[%a+%]:%s*(.-)%s+obtained")
    local fish    = clean:match("obtained a?n?%s+(.-)%s+with a")
    local chance  = clean:match("with a (1 in [%d%.,KkMmBb]+) chance")

    if not player or not fish then return nil end

    return {
        player = player:match("^%s*(.-)%s*$"),
        fish   = fish:match("^%s*(.-)%s*$"),
        chance = chance or "?",
        prefix = prefix,
    }
end

local function sendWebhook(info, tierData)
    if not Config.WebhookURL or Config.WebhookURL == "" then return end
    if not httpRequest then return end

    local isGlobal = info.prefix == "[Global]"

    local displayName = (Config.CustomName ~= "") and Config.CustomName or info.player

    local payload = {
        embeds = {{
            author      = { name = "Lynxx Webhook | Fish Caught" },
            description = string.format(
                "**%s** obtained a new **%s** fish!%s",
                displayName, tierData.name,
                isGlobal and " 🌐 *(Global Broadcast)*" or ""
            ),
            color  = tierData.discordColor,
            fields = {
                { name = "Fish Name :", value = "> " .. info.fish,     inline = false },
                { name = "Fish Tier :", value = "> " .. tierData.name, inline = false },
                { name = "Chance :",    value = "> " .. info.chance,   inline = false },
            },
            footer    = { text = "Lynxx Webhook • " .. os.date("%m/%d/%Y %H:%M"), icon_url = "https://i.imgur.com/UMWNYK7.png" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    pcall(function()
        httpRequest({
            Url     = Config.WebhookURL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode(payload)
        })
    end)
end

local function processText(text)
    if not Config.Enabled then return end
    if not text or text == "" then return end
    if not text:find("%[Server%]") and not text:find("%[Global%]") then return end
    if not text:find("obtained") then return end

    local info     = parseBodyText(text)
    if not info then return end

    local tierData = getTierFromRGB(text)
    if not tierData then return end

    if tierData.tier < Config.MinTier then return end

    Library:MakeNotify({
        Title       = tierData.name .. " Fish!",
        Description = info.player,
        Content     = info.fish .. " • " .. info.chance,
        Color       = Color3.fromRGB(tierData.r, tierData.g, tierData.b),
        Delay       = 5,
    })

    task.spawn(function()
        sendWebhook(info, tierData)
    end)
end

local hookedObjects = {}
local descConn      = nil

local function hookTextLabel(obj)
    if hookedObjects[obj] then return end
    hookedObjects[obj] = true

    if obj.Text and obj.Text ~= "" then
        processText(obj.Text)
    end
    obj:GetPropertyChangedSignal("Text"):Connect(function()
        processText(obj.Text)
    end)
end

local function isBodyText(obj)
    if not obj:IsA("TextLabel") then return false end
    if obj.Name:lower():find("body") then return true end
    if obj.Text:find("rgb%(") and obj.Text:find("obtained") then return true end
    return false
end

local function startMonitoring()
    hookedObjects = {}

    task.spawn(function()
        local expChat = CoreGui:WaitForChild("ExperienceChat", 15)
        if not expChat then
            Library:MakeNotify({
                Title       = "Warning",
                Description = "ExperienceChat tidak ditemukan!",
                Color       = Color3.fromRGB(255, 200, 0),
                Delay       = 4,
            })
            return
        end

        for _, desc in ipairs(expChat:GetDescendants()) do
            if isBodyText(desc) then
                hookTextLabel(desc)
            end
        end

        descConn = expChat.DescendantAdded:Connect(function(desc)
            if not desc:IsA("TextLabel") then return end
            task.delay(0.1, function()
                if isBodyText(desc) then
                    hookTextLabel(desc)
                end
            end)
        end)
    end)
end

local function stopMonitoring()
    if descConn then
        pcall(function() descConn:Disconnect() end)
        descConn = nil
    end
    hookedObjects = {}
end

Library.ConfigSystem.Load()

local Window = Library:Window({
    Title  = "LynX",
    Footer = "Broadcast Webhook",
})

local MainTab = Window:AddTab({ Name = "Webhook", Icon = "fish" })

local webhookSection = MainTab:AddSection("Configuration")

webhookSection:AddInput({
    Title       = "Webhook URL",
    Placeholder = "https://discord.com/...",
    Default     = "",
    NoSave      = true,
    Callback    = function(val)
        Config.WebhookURL = val
    end,
})

webhookSection:AddInput({
    Title       = "Custom Name",
    Placeholder = "Kosong = nama player asli",
    Default     = "",
    Callback    = function(val)
        Config.CustomName = val
    end,
})

webhookSection:AddDropdown({
    Title    = "Minimal Tier",
    Options  = { "Epic", "Legendary", "Mythic", "SECRET", "FORGOTTEN" },
    Multi    = true,
    Default  = "Epic",
    NoSave   = true,
    Callback = function(val)
        local tierMap = { Epic=4, Legendary=5, Mythic=6, SECRET=7, FORGOTTEN=8 }
        Config.MinTier = tierMap[val] or 4
    end,
})

webhookSection:AddToggle({
    Title    = "Enable Webhook",
    Default  = false,
    NoSave   = true,
    Callback = function(val)
        Config.Enabled = val
        if val then
            startMonitoring()
            Library:MakeNotify({
                Title       = "Webhook Aktif",
                Description = "Scanning ExperienceChat...",
                Content     = "Tunggu sebentar lalu ada yang tangkap ikan",
                Color       = Color3.fromRGB(34, 197, 94),
                Delay       = 4,
            })
        else
            stopMonitoring()
            Library:MakeNotify({
                Title       = "Webhook Berhenti",
                Description = "Monitoring dihentikan",
                Color       = Color3.fromRGB(200, 80, 80),
                Delay       = 3,
            })
        end
    end,
})

webhookSection:AddButton({
    Title    = "Test Webhook",
    Callback = function()
        if Config.WebhookURL == "" then
            Library:MakeNotify({
                Title       = "Error",
                Description = "Webhook URL kosong!",
                Color       = Color3.fromRGB(255, 80, 80),
                Delay       = 3,
            })
            return
        end

        local displayName = (Config.CustomName ~= "") and Config.CustomName or "Test User"

        local ok = pcall(function()
            httpRequest({
                Url     = Config.WebhookURL,
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = HttpService:JSONEncode({
                    embeds = {{
                        author      = { name = "Lynxx Webhook | Fish Caught" },
                        description = "**" .. displayName .. "** obtained a new **SECRET** fish! 🌐 *(Global Broadcast)*",
                        color       = 65535,
                        fields = {
                            { name = "Fish Name :", value = "> TALON", inline = false },
                            { name = "Fish Tier :", value = "> SECRET",            inline = false },
                            { name = "Chance :",    value = "> 1 in 999.999M chance", inline = false },
                        },
                        image = {
                            url = "https://i.imgur.com/4HksNTD.gif"
                        },
                        footer    = { text = "Lynxx Webhook • " .. os.date("%m/%d/%Y %H:%M"), icon_url = "https://i.imgur.com/UMWNYK7.png" },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                })
            })
        end)

        Library:MakeNotify({
            Title       = ok and "Test Terkirim!" or "Gagal",
            Description = ok and "Cek channel Discord kamu!" or "Cek URL webhook",
            Color       = ok and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(255, 80, 80),
            Delay       = 3,
        })
    end,
})
