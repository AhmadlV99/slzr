local _ENV = (getgenv or getrenv or getfenv)()

local Utils = {}
local Settings = {}
local Threads = {}
local Fallback = {}

local Owner = "vita6it"
local Repository = "Antigravity"

local function fetch(file)
    local URL = string.format(
        "https://raw.githubusercontent.com/%s/%s/main/%s",
        Owner, Repository, file
    )

    warn("Fetch : ", file)

    return loadstring(game:HttpGet(URL))()
end

local function AddModule(Name, Module)
    do Utils[Name] = Module()
        return Utils[Name]
    end
end

local Library = fetch("Utils/Library.lua")

local TeleportService = game:GetService('TeleportService')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

Utils.Library = Library

AddModule("Connections", function()
    local Connections = {}
    local Cached = _ENV.Connections or {}

    do
        _ENV.Connections = Cached

        for i = 1, #Cached do
            Cached[i]:Disconnect()
        end

        table.clear(Cached)
    end

    function Connections.Connect(Instance, Callback)
        local Connection = Instance:Connect(Callback)

        table.insert(Cached, Connection)

        return Connection
    end 

    return Connections
end)

AddModule("Configurations", function()
    local Configurations = {}
    local Files = "Antigravity"

    local makefolder = makefolder or function( ... ) return ... end
    local writefile = writefile or function( ... ) return ... end
    local isfolder = isfolder or function( ... ) return ... end
    local readfile = readfile or function( ... ) return ... end
    local isfile = isfile or function( ... ) return ... end

    Configurations.FullPaths = `{Configurations.Set}/{PlaceId}.json`
    Configurations.Paths = { Files, Configurations.Set }
    Configurations.Files = Files or "Antigravity"
    Configurations.Set = `{Files}/settings`

    do
        function Configurations:Folder()
            for i = 1, #self.Paths do
                local str = self.Paths[i]

                if not isfolder(str) then
                    makefolder(str)
                end
            end
        end

        function Configurations:Default(index, value)
            if Settings[index] == nil then
                Settings[index] = value
            end
        end

        function Configurations:Save(index, value)
            if index ~= nil then
                Settings[index] = value
            end

            if not isfolder(Files) then
                makefolder(Files)
            end

            if not isfolder(Configurations.Set) then
                makefolder(Configurations.Set)
            end

            writefile(Configurations.FullPaths, HttpService:JSONEncode(Settings))
        end

        function Configurations:Load()
            if not isfile(Configurations.FullPaths) then
                self:Save()
            end

            local Reader = readfile(Configurations.FullPaths) do
                return HttpService:JSONDecode(Reader) 
            end
        end 
    end

    do Configurations:Folder()
        Configurations:Default("Success", true)
    end

    return Configurations
end)

AddModule("Asset", function()
    local Asset = {}

    local getcustomasset = getcustomasset or function(...) return ... end

    local saved = {}

    function Asset:Download(url, filename)
        local data = game:HttpGet(url)

        writefile(filename, data)

        saved[filename] = data

        return data
    end

    function Asset:Get(filename)
        if saved[filename] then
            return getcustomasset(filename)
        end

        if isfile(filename) then
            saved[filename] = readfile(filename)
            return getcustomasset(filename)
        end

        return 0
    end

    do
        if not isfile("Q613L20.png") then
            Asset:Download("https://raw.githubusercontent.com/vita6it/Antigravity/main/assets/xova.png", "Q613L20.png") 
        end
    end

    return Asset
end)

AddModule("Others", function()
    local Others = {}

    Others.Server = (function()
        local Server = {}

        function Server:Reversed(cursor)
            local url = `https://games.roblox.com/v1/games/{PlaceId}/servers/Public?sortOrder=Asc&limit=100`

            if cursor then
                url ..= `&cursor={cursor}`
            end

            return HttpService:JSONDecode(game:HttpGet(url))
        end

        function Server:Rejoin()
            if #Players:GetPlayers() <= 1 then
                LocalPlayer:Kick("\nRejoining");wait()

                return TeleportService:Teleport(PlaceId, LocalPlayer)
            end

            return TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
        end

        function Server:Change()
            local Server, Next

            repeat
                local Servers = Server:Reversed(Next)

                Server = Servers and Servers.data and Servers.data[1]
                Next = Servers and Servers.nextPageCursor
            until Server

            if not Server or not Server.id then return end
            return TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
        end

        function Server:Join(id)
            return TeleportService:TeleportToPlaceInstance(PlaceId, id, LocalPlayer)
        end

        return Server
    end)()

    Others.Optimize = (function()
        local Optimize = {}

        function Optimize:Set3d(value)
            RunService:Set3dRenderingEnabled(if value then false else true)
        end

        function Optimize:Low()
            local Terrain = workspace:FindFirstChildOfClass('Terrain') do
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 0
                game.Lighting.GlobalShadows = false
                game.Lighting.FogEnd = 9e9
                settings().Rendering.QualityLevel = 1
            end
        end

        return Optimize
    end)()

    return Others
end)

AddModule("Parallels", function()
    local Parallels = {}

    local Options = {}
    local clonedEnabled = {}
    local Functions = _ENV.FUNCTIONS or {}
    local FarmFunctions = _ENV.FARM_FUNCTIONS or {}

    local Enabled_Toggle_Debounce = false
    local Enabled_New_Values = {}

    do
        local function ShowErrorMessage(ErrorMessage)
            _ENV.ISLOADED = false
            _ENV.OnFarm = false

            local text = (`error [ { _ENV.RunningOption or "Null" } ] { ErrorMessage }\nWait 10 second for reset option.`)

            if _ENV.error_message then
                _ENV.error_message.Text ..= `\n\n{ text }`

                return nil
            end

            local Message = Instance.new("Message", workspace) do
                _ENV.error_message = Message
                Message.Text = text
            end
        end

        local function RunQueue(Options)
            local Success, ErrorMessage = pcall(function()
                local function GetQueue()
                    for _, Option in Options do

                        _ENV.RunningOption = Option.Name

                        local Method = Option.Function()

                        if Method then
                            if type(Method) == "string" then
                                _ENV.RunningMethod = Method
                            end

                            return Method
                        end
                    end

                    _ENV.RunningOption, _ENV.RunningMethod = nil, nil
                end

                while task.wait(not Settings['Smooth Mode'] and 0 or 1) do
                    _ENV.OnFarm = if GetQueue() then true else false
                end
            end)

            if not Success then
                ShowErrorMessage(ErrorMessage)
                warn(ErrorMessage)

                task.delay(5, function()
                    if _ENV.error_message then
                        _ENV.error_message.Text = "- Antigravity Model -\nStart Refresh Options ..."

                        task.wait(2)

                        if _ENV.RunningOption and Fallback[_ENV.RunningOption] then
                            Fallback[_ENV.RunningOption].Value = false
                            _ENV.error_message.Text = "- Antigravity Model -\nHas been Disabled " .. _ENV.RunningOption
                        end

                        task.wait(2)

                        _ENV.error_message:Destroy()
                        _ENV.error_message = nil

                        task.spawn(RunQueue, FarmFunctions)
                    end
                end)
            end
        end

        local function UpdateEnabledOptions()
            table.clear(FarmFunctions)

            for index, value in pairs(Enabled_New_Values) do
                clonedEnabled[index] = value or nil
                Enabled_New_Values[index] = nil
            end

            for i = 1, #Functions do
                local funcData = Functions[i]
                if clonedEnabled[funcData.Name] then
                    table.insert(FarmFunctions, funcData)
                end
            end
        end

        local Enabled = _ENV.ENABLED_OPTIONS or setmetatable({}, {
            __newindex = function(self, index, value)
                Enabled_New_Values[index] = value or false

                if not Enabled_Toggle_Debounce then
                    Enabled_Toggle_Debounce = false
                    task.spawn(UpdateEnabledOptions)
                end
            end,
            __index = clonedEnabled
        })

        do
            _ENV.FUNCTIONS = Functions
            _ENV.ENABLED_OPTIONS = Enabled
            _ENV.FARM_FUNCTIONS = FarmFunctions

            if not _ENV.ISLOADED then
                _ENV.ISLOADED = true

                task.spawn(RunQueue, FarmFunctions)
            end
        end

        do table.clear(Functions) end

        local index = {}

        local function While(a, b, c, d)
            while a do
                local t = tick()

                if c then c() end
                if d and d() then break end

                repeat
                    RunService.Heartbeat:Wait()
                until tick() - t >= (b or 0.1)
            end
        end

        local function NewOption(Tag, Function, Time)
            if Time then
                Threads[Tag] = function(Value)
                    While(Value, Time or 0.1, Function, function()
                        return not Value
                    end)
                end
            else
                local Data = { 
                    ["Name"] = Tag,
                    ["Function"] = Function
                }

                index[Tag] = Function
                table.insert(Functions, Data)
            end
        end

        Parallels.NewOption = NewOption
        Parallels.Options = function()
            return Enabled, Options
        end
    end

    return Parallels
end)

AddModule("Plugins", function()
    local Plugins = {
        NewTabs = true
    }

    local Configurations = Utils.Configurations
    local Parallels = Utils.Parallels
    local Others = Utils.Others

    local Enabled, Options = Parallels.Options()

    function Plugins:Window(Info)
        Library['Base'] = Library:Window(Info or {})
        return Library['Base']
    end

    function Plugins:NewPage(Info)
        return Library['Base']:NewPage({
            Title = Info[1],
            Desc = Info[2],
            Icon = Info[3]
        })
    end
    
    function Plugins:TextLabel(Forms, Info)
        return Forms:Paragraph({
            Title = Info[1],
            Desc = Info[2],
            Image = Info[3] or nil
        }) 
    end
    
    function Plugins:RightLabel(Forms, Info)
        return Forms:RightLabel({
            Title = Info[1],
            Desc = Info[2],
            Right = Info[3]
        }) 
    end

    function Plugins:Toggle(Forms, Info, Flag, Callback)
        local Thread = nil

        Fallback[Flag] = Forms:Toggle({
            Title = Info[1],
            Desc = Info[2],
            Value = Settings[Flag],
            Callback = function(value)
                Settings[Flag] = value
                Configurations:Save(Flag, value)

                Enabled[Flag] = value

                if value then
                    Thread = task.spawn(function()
                        if Threads[Flag] then Threads[Flag](Settings[Flag]) end
                    end)
                else
                    if Thread then task.cancel(Thread) end
                end

                if Callback then Callback(value) end
            end
        })

        return Fallback[Flag]
    end

    function Plugins:Slider(Forms, Info, Value, Flag, Callback)
        return Forms:Slider({
            Title = Info,
            Min = Value[1],
            Max = Value[2],
            Rounding = Value[3],
            Value = Settings[Flag],
            Callback = function(value)
                Settings[Flag] = value
                Configurations:Save(Flag, value)
                if Callback then Callback(value) end
            end
        })
    end

    function Plugins:Dropdown(Forms, Info, List, Flag, Callback)
        return Forms:Dropdown({
            Title = Info,
            Value = Settings[Flag],
            List = List,
            Callback = function(value)
                Settings[Flag] = value
                Configurations:Save(Flag, value)

                if Callback then Callback(value) end
            end
        })
    end

    function Plugins:Button(Forms, Info, Callback)
        return Forms:Button({
            Title = Info[1],
            Desc = Info[2],
            Callback = Callback,
        }) 
    end

    function Plugins:Input(Forms, Flag, Callback)
        return Forms:Input({
            Value = Settings[Flag],
            Callback = function(value)
                Settings[Flag] = value
                Configurations:Save(Flag, value)

                if Callback then Callback(value) end
            end
        })
    end

    function Plugins:Community()
        local Community = Plugins:NewPage({ "Community", "Join our community", 115960025411300 }) do
            Community:Section("Community") do
                local Discord = Community:Input({ Value = "https://discord.gg/JXgCz6uC2U" }) do
                    Discord.TextEditable = false
                    Discord.Interactable = false
                    Discord.ClearTextOnFocus = false 
                end
                
                local Banner = Utils.Asset:Get("Q613L20.png") do
                    Community:Banner(Banner or 98180244082666) 
                end
            end
        end
        
        return Community
    end
    
    function Plugins:Managers()
        local Managers = Plugins:NewPage({ "Managers", "Managers Options", 134261589888025 }) do
            
            Managers:Section("Server") do
                Configurations:Default("JobId", JobId)
                
                Plugins:Input(Managers, 'JobId')
                
                Plugins:Button(Managers, { "Join", "Connect to the server using the provided JobId." }, function()
                    Others.Server:Join(Settings['JobId'])
                end)
                
                Plugins:Button(Managers, { "Change", "Teleport to a different public server instance." }, function()
                    Others.Server:Change()
                end)
                
                Plugins:Button(Managers, { "Rejoin", "Reconnect to the current server instance." }, function()
                    Others.Server:Rejoin()
                end)
            end
            
            Managers:Section("Optimize") do
                Plugins:Toggle(Managers, { "White Screen", "Disabled 3D Rendering to improve performance" }, "White Screen", function(value)
                    Others.Optimize:Set3d(value)
                end)

                Plugins:Button(Managers, { "Fast Mode", "Set graphics quality to low" }, function()
                    Others.Optimize:Low()
                end)
            end
            
            Managers:Section("Configurations") do
                Library:SizeSlider(Managers, Plugins)
                
                Plugins:Button(Managers, { "Remove Worksapce", "Reset save setting file to default value." }, function()
                    local Files = Configurations.FullPaths

                    if Files and isfile(Files) then
                        pcall(delfile, Configurations.FullPaths)
                        warn('Remove Success')
                    else
                        warn('File not found')
                    end
                end)
            end
        end
    end

    return Plugins
end)

do
    Settings = Utils.Configurations:Load()
    Utils.Settings = Settings
end

return Utils
