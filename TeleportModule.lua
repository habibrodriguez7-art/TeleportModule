-- TeleportModule.lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local TeleportModule = {}

TeleportModule.Locations = {
    ["Ancient Jungle"] = Vector3.new(1467.8480224609375, 7.447117328643799, -327.5971984863281),
    ["Ancient Ruin"] = Vector3.new(6045.40234375, -588.600830078125, 4608.9375),
    ["Coral Reefs"] = Vector3.new(-2921.858154296875, 3.249999761581421, 2083.2978515625),
    ["Crater Island"] = Vector3.new(1078.454345703125, 5.0720038414001465, 5099.396484375),
    ["Esoteric Depths"] = Vector3.new(3224.075927734375, -1302.85498046875, 1404.9346923828125),
    ["Fisherman Island"] = Vector3.new(92.80695343017578, 9.531265258789062, 2762.082275390625),
    ["Kohana"] = Vector3.new(-643.3051147460938, 16.03544807434082, 622.3605346679688),
    ["Kohana Volcano"] = Vector3.new(-572.0244750976562, 39.4923210144043, 112.49259185791016),
    ["Lost Isle"] = Vector3.new(-3701.1513671875, 5.425841808319092, -1058.9107666015625),
    ["Sysiphus Statue"] = Vector3.new(-3656.56201171875, -134.5314178466797, -964.3167724609375),
    ["Sacred Temple"] = Vector3.new(1476.30810546875, -21.8499755859375, -630.8220825195312),
    ["Treasure Room"] = Vector3.new(-3601.568359375, -266.57373046875, -1578.998779296875),
    ["Tropical Grove"] = Vector3.new(-2104.467041015625, 6.268016815185547, 3718.2548828125),
    ["Underground Cellar"] = Vector3.new(2162.577392578125, -91.1981430053711, -725.591552734375),
    ["Pirate Cove"] = Vector3.new(3334.47, 10.2, 3502.92),
    ["Leviathan Den"] = Vector3.new(3471.41, -287.84, 3468.87),
    ["Pirate Treasure Room"] = Vector3.new(3337.64, -302.75, 3089.56),
    ["Crystal Depths"] = Vector3.new(5729.04, -904.82, 15407.97),
    ["(New)Vulcanic Cavern"] = Vector3.new(1118.181762695312500, 85.990936279296875, -10250.158203125000000),
    ["(New)Lava Basin"] = Vector3.new(871.716613769531250, 96.938903808593750, -10176.625976562500000),
    ["(New)Heartfelt Island"] = Vector3.new(1114.147705078125000, 4.845647811889648, 2715.550048828125000),
    ["Weather Machine"] = Vector3.new(-1513.9249267578125, 6.499999523162842, 1892.10693359375)
}

function TeleportModule.TeleportTo(name)
    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    local target = TeleportModule.Locations[name]
    if not target then
        return false
    end

    root.CFrame = CFrame.new(target)
    return true
end

return TeleportModule
