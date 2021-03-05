--[[
Шо надо сделать:
Кастомный чат /w | /sms
Кастомный чат /r | /d
Кастомный инфобар
Кастомный счетчик онлайна
Кастомный TAB
Кастомный /members
/wanted в зоне стрима
]]
script_name("Gov Secretary | Engine")
script_authors("SiriuS & Wanie Lowely")
script_version("0.4")
local notif_version = "1.0"

require 'lib.moonloader'
local sampev = require 'samp.events'
local copas = require 'copas'
local http = require 'copas.http'
local vkeys = require 'vkeys'
local imgui = require 'mimgui'
local mimgui_addons = require 'mimgui_addons'
local inicfg = require 'inicfg'
local encoding = require 'encoding'
local memory = require 'memory'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local playerRang = 0
local playerRangName = "Неизвестно"
local playerWarns = -1

function httpRequest(request, body, handler)
    if not copas.running then
        copas.running = true
        lua_thread.create(function()
            wait(0)
            while not copas.finished() do
                local ok, err = copas.step(0)
                if ok == nil then error(err) end
                wait(0)
            end
            copas.running = false
        end)
    end
    if handler then
        return copas.addthread(function(r, b, h)
            copas.setErrorHandler(function(err) h(nil, err) end)
            h(http.request(r, b))
        end, request, body, handler)
    else
        local results
        local thread = copas.addthread(function(r, b)
            copas.setErrorHandler(function(err) results = {nil, err} end)
            results = table.pack(http.request(r, b))
        end, request, body)
        while coroutine.status(thread) ~= 'dead' do wait(0) end
        return table.unpack(results)
    end
end

local fa = require('fAwesome5')

local ffi = require 'ffi'
local wm = require 'windows.message'
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof

local pircelEnabled = false
local nightEnabled = false
local infraredEnabled = false

local LogoFont = nil
local VersionFont = nil

local ScriptMainMenu, freezePlayer, removeCursor = new.bool(), new.bool(), new.bool()
local sizeX, sizeY = getScreenResolution()

local MenuListID = 0

local Config = inicfg.load({
	CORE = {
		customChats = true,
		armourBind = 0x42
	},
	FILTERS = {
		Contracts = false,
		Invites = false,
		Orders = false,
		admSMS = false,
		Proposes = false
	}
}, '..\\GOV\\Settings.ini')

cfg_Contracts = new.bool(Config.FILTERS.Contracts)
cfg_Invites = new.bool(Config.FILTERS.Invites)
cfg_Orders = new.bool(Config.FILTERS.Orders)
cfg_admSMS = new.bool(Config.FILTERS.admSMS)
cfg_Proposes = new.bool(Config.FILTERS.Proposes)

local cfg_customChats = new.bool(Config.CORE.customChats)
local cfg_armourBind = Config.CORE.armourBind

local lib_notification = [[script_version("1.0")
local imgui = require 'imgui'
imgui.ShowCursor = false
local style = imgui.GetStyle()
local colors = style.Colors
local clr = imgui.Col
local ImVec4 = imgui.ImVec4
local encoding = require 'encoding'
u8 = encoding.UTF8
encoding.default = 'CP1251'
imgui.GetStyle().WindowMinSize = imgui.ImVec2(1.0, 1.0)
local ToScreen = convertGameScreenCoordsToWindowScreenCoords
local sX, sY = ToScreen(630, 438)
local message = {}
local typeStyle = {
	{ -- 1) Информация
		text = imgui.ImColor(255, 255, 255, 255):GetVec4(),
		rightBox = imgui.ImVec4(0.09, 0.09, 0.43, 0.4),
		mainBox = {
			imgui.ImVec4(0.09, 0.09, 0.43, 0.4),
			imgui.ImVec4(0.09, 0.09, 0.43, 0.4),
			imgui.ImVec4(0.09, 0.09, 0.43, 0.4),
			imgui.ImVec4(0.09, 0.09, 0.43, 0.4),
		}
	},
	{ -- 2) Ошибка
		text = imgui.ImColor(255, 255, 255, 255):GetVec4(),
		rightBox = imgui.ImVec4(0.09, 0.09, 0.43, 0.4),
		mainBox = {
			imgui.ImColor(170, 20, 20, 255):GetU32(),
			imgui.ImColor(170, 20, 20, 255):GetU32(),
			imgui.ImColor(170, 20, 20, 255):GetU32(),
			imgui.ImColor(170, 20, 20, 255):GetU32(),
		}
	}
}
local msxMsg = 3
local notfList = {
	pos = {
		x = sX - 200,
		y = sY
	},
	npos = {
		x = sX - 200,
		y = sY
	},
	size = {
		x = 200,
		y = 0
	}
}

local LastActiveTime = {}
local LastActive = {}
local LastStatus = {}

function setstyle()
	style.WindowRounding = 2.0
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ChildWindowRounding = 2.0
	style.FrameRounding = 2.0
	style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
	style.ScrollbarSize = 13.0
	style.ScrollbarRounding = 0
	style.GrabMinSize = 8.0
	style.GrabRounding = 1.0
	-- style.Alpha =
	style.WindowPadding = imgui.ImVec2(4.0, 4.0)
	style.WindowMinSize = imgui.ImVec2(1.0, 1.0)
	style.FramePadding = imgui.ImVec2(3.5, 3.5)
	-- style.ItemInnerSpacing =
	-- style.TouchExtraPadding =
	-- style.IndentSpacing =
	-- style.ColumnsMinSpacing = ?
	style.ButtonTextAlign = imgui.ImVec2(0.0, 0.5)
	-- style.DisplayWindowPadding =
	-- style.DisplaySafeAreaPadding =
	-- style.AntiAliasedLines =
	-- style.AntiAliasedShapes =
	-- style.CurveTessellationTol =

	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.00)
	colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.ComboBg]                = colors[clr.PopupBg]
	colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.FrameBg]                = ImVec4(0.12, 0.12, 0.12, 0.94)
	colors[clr.FrameBgHovered]         = ImVec4(0.45, 0.45, 0.45, 0.85)
	colors[clr.FrameBgActive]          = ImVec4(0.63, 0.63, 0.63, 0.63)
	colors[clr.TitleBg]                = ImVec4(0.13, 0.13, 0.13, 0.99)
	colors[clr.TitleBgActive]          = ImVec4(0.13, 0.13, 0.13, 0.99)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.05, 0.05, 0.05, 0.79)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.CheckMark]              = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.28, 0.28, 0.28, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.35, 0.35, 0.35, 1.00)
	colors[clr.Button]                 = ImVec4(0.12, 0.12, 0.12, 0.94)
	colors[clr.ButtonHovered]          = ImVec4(0.34, 0.34, 0.35, 0.89)
	colors[clr.ButtonActive]           = ImVec4(0.21, 0.21, 0.21, 0.81)
	colors[clr.Header]                 = ImVec4(0.12, 0.12, 0.12, 0.94)
	colors[clr.HeaderHovered]          = ImVec4(0.34, 0.34, 0.35, 0.89)
	colors[clr.HeaderActive]           = ImVec4(0.12, 0.12, 0.12, 0.94)
	colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
	colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
	colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
	colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
	colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

function main()
	while true do
		wait(0)
		imgui.ShowCursor = false
		imgui.Process = #message > 0
	end
end

function ImSaturate(f)
	return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
end

local glyph_ranges = nil
function imgui.BeforeDrawFrame()
	local x, y = getScreenResolution()
	if not fontChanged then
		setstyle()
		fontChanged = true
	end
end

function imgui.OnDrawFrame()
	imgui.SetMouseCursor(imgui.MouseCursor.None)
	onRenderNotification()
end

function onRenderNotification()
	local ANIM_SPEED = 0.3
	local count = 0
	for k, v in ipairs(message) do
		local push = false
		if v.active and v.time < os.clock() then
			v.active = false
		end
		if count < 5 then
			if not v.active then
				if v.showtime > 0 then
					v.active = true
					v.time = os.clock() + v.showtime
					v.showtime = 0
					LastActiveTime[k] = os.clock()
					LastActive[k] = true
					LastStatus[k] = true
				end
			end
			if v.active then
				count = count + 1
				local t = LastStatus[k] and 0.0 or 1.0
				if LastActive[k] then
					local time = os.clock() - LastActiveTime[k]
					if time <= ANIM_SPEED then
						local t_anim = ImSaturate(time / ANIM_SPEED)
						t = LastStatus[k] and 1.0 - t_anim or t_anim
					else
						LastActive[k] = false
					end
				end
				if v.time - os.clock() <= ANIM_SPEED and not LastActive[k] and LastStatus[k] then
					LastStatus[k] = false
					LastActiveTime[k] = os.clock()
					LastActive[k] = true
				end
				local nText = u8(tostring(v.text))
				notfList.size = imgui.GetFont():CalcTextSizeA(imgui.GetFont().FontSize, 200.0, 196.0, nText)
				notfList.pos = imgui.ImVec2(notfList.pos.x + t * 215, notfList.pos.y - (notfList.size.y + (count == 1 and 8 or 13)))
				imgui.SetNextWindowPos(notfList.pos, _, imgui.ImVec2(0.0, 0.0))
				imgui.SetNextWindowSize(imgui.ImVec2(215 - t * 215, notfList.size.y + imgui.GetStyle().ItemSpacing.y + imgui.GetStyle().WindowPadding.y))
				imgui.Begin(u8'##msg' .. k, _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar)
				local style
				if type(v.style) == "table" then
					style = v.style
				else
					style = typeStyle[v.style] or typeStyle[1]
				end
				local draw_list = imgui.GetWindowDrawList()
				local p = imgui.GetCursorScreenPos()
				draw_list:AddRectFilledMultiColor(imgui.ImVec2(p.x - imgui.GetStyle().WindowPadding.x - 20, p.y - imgui.GetStyle().WindowPadding.y), imgui.ImVec2(p.x + 200, p.y + notfList.size.y + imgui.GetStyle().ItemSpacing.y + imgui.GetStyle().WindowPadding.y), style.mainBox[1], style.mainBox[2], style.mainBox[3], style.mainBox[4]);
				draw_list:AddRectFilled(imgui.ImVec2(p.x - imgui.GetStyle().WindowPadding.x + 205, p.y - imgui.GetStyle().WindowPadding.y), imgui.ImVec2(p.x + 216, p.y + notfList.size.y + imgui.GetStyle().ItemSpacing.y + imgui.GetStyle().WindowPadding.y), style.rightBox);
				imgui.PushTextWrapPos(196.0)
				imgui.TextColored(style.text, nText)
				imgui.PopTextWrapPos()
				imgui.End()
			end
		end
	end
	sX, sY = ToScreen(630, 438)
	notfList = {
		pos = {
			x = sX - 200,
			y = sY
		},
		npos = {
			x = sX - 200,
			y = sY
		},
		size = {
			x = 200,
			y = 0
		}
	}
end

function EXPORTS.addNotification(text, time, style)
	local style = style or 1
	message[#message+1] = {active = false, time = 0, showtime = time, text = text, style = style}
end]]

function load_notf_lib()
	bNotf, notf = pcall(import, "GOV\\GOV-Notifications.lua")
	print("Модуль Notifications успешно подключено.")
	return bNotf
end

function whileNotLoad()
	local is_load = load_notf_lib()
	if not is_load then
		load_notf_lib()
		return
	end
end

if not doesFileExist('moonloader/GOV/GOV-Notifications.lua') then
	local f = io.open('moonloader/GOV/GOV-Notifications.lua', "w")
	print("Загрузка модуля Notifications...")
	if f then
		f:write(lib_notification)
		f:close()
		whileNotLoad()
	else
		whileNotLoad()
	end
	else load_notf_lib()
end

if doesFileExist('moonloader/GOV/GOV-Notifications.lua') then
	local scr = script.find('GOV-Notifications.lua')
	if notif_version ~= scr.version then
		print("Обновление модуля Notifications...")
		os.remove(getWorkingDirectory().."\\GOV\\GOV-Notifications.lua")
		local f = io.open('moonloader/GOV/GOV-Notifications.lua', "w")
		if f then
			f:write(lib_notification)
			f:close()
		end
		lua_thread.create(function() wait(3500) print("Обновление модуля Notifications прошло успешно.") thisScript():reload() end)
	end
end

function checkVers()
	local dlstatus = require('moonloader').download_status
	local json_url = "https://raw.githubusercontent.com/Maksim-Avdeenko/SWAT_Tools/main/SWAT_Updater.json"
	local json = getWorkingDirectory() .. '\\SWAT Tools.json'
	if doesFileExist(json) then os.remove(json) end
	downloadUrlToFile(json_url, json,
	  function(id, status, p1, p2)
		if status == dlstatus.STATUSEX_ENDDOWNLOAD then
			if doesFileExist(json) then
				local f = io.open(json, 'r')
				if f then
					local info = decodeJson(f:read('*a'))
					updateversion = info.latest
					updateurl = info.updateurl
					updatepriority = info.priority
					f:close()
					os.remove(json)
					if tonumber(updatepriority) == 0 and updateversion ~= thisScript().version then
						oldVersion = true
						sampAddChatMessage("** Секретарша: {585858}Доступна версия {cc0000}"..updateversion.."{585858}, мы настоятельно рекомендуем обновиться до последней версии. {8f408f}**", 0x8f408f)
					end
					if tonumber(updatepriority) == 1 and updateversion ~= thisScript().version then
						sampAddChatMessage("** Секретарша: {585858}Доступна версия {cc0000}"..updateversion.."{585858}, начинаю процесс принудительного обновления... {8f408f}**", 0x8f408f)
						lua_thread.create(updateSCR)
					end
				end
			 end
		end
	end)
end

font = renderCreateFont('Bahnschrift Bold', 10)

function updateSCR()
	local url = "vk.com/rgayranyan"
	local dlstatus = require('moonloader').download_status
	if doesFileExist(json) then os.remove(json) end
	getUpdLink = updateurl
	getUpdVers = updateversion
	if getUpdVers ~= nil and getUpdVers ~= thisScript().version then
		lua_thread.create(function()
			local dlstatus = require('moonloader').download_status
			sampAddChatMessage("** Секретарша: {585858}Пытаюсь обновиться c {cc0000}"..thisScript().version.." {585858}на версию {cc0000}"..getUpdVers.." {585858}**", 0x8f408f)
			wait(250)
			downloadUrlToFile(getUpdLink, thisScript().path,
				function(id3, status1, p13, p23)
					if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
						print(string.format('Загружено %d из %d.', p13, p23))
					elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
						print('Загрузка обновления завершена.')
						sampAddChatMessage("** Секретарша: {585858}Обновление програмного обеспечения завершено. {cc0000}**", 0x8f408f)
						goupdatestatus = true
						lua_thread.create(function() wait(500) thisScript():reload() end)
					end
					if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
						if goupdatestatus == nil then
							sampAddChatMessage("** Секретарша: {585858}Обновление ПО провалено. Запускаю устаревшую версию ПО. {cc0000}**", 0x8f408f)
							update = false
						end
					end
				end
			)
		end)
	else
		update = false
		print('v'..thisScript().version..': Обновление не требуется.')
	end
	while update ~= false do wait(100) end
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], text[i])
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(w) end
        end
    end

    render_text(u8(text))
end

function imgui.CenterTextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            imgui.SetCursorPosX( width / 2 - text_width .x / 2 )
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.TextQuestion(text)
    imgui.TextDisabled("(?)")
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        local p = imgui.GetCursorScreenPos()
        imgui.SetCursorScreenPos(imgui.ImVec2(p.x + 14,p.y + 14))
        imgui.PushTextWrapPos(450)
        imgui.TextUnformatted(text)
        local p = imgui.GetCursorScreenPos()
        local obrez = imgui.GetFont():CalcTextSizeA(imgui.GetFont().FontSize,450,450,text).x
        imgui.SetCursorScreenPos(imgui.ImVec2(p.x + obrez + 28,p.y + 14))
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end
function imgui.Hint(text)
    if imgui.IsItemHovered() then
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
			imgui.BeginTooltip()
			local p = imgui.GetCursorScreenPos()
			imgui.SetCursorScreenPos(imgui.ImVec2(p.x + 14,p.y + 14))
			imgui.PushTextWrapPos(450)
			imgui.TextUnformatted(text)
			local p = imgui.GetCursorScreenPos()
			local obrez = imgui.GetFont():CalcTextSizeA(imgui.GetFont().FontSize,450,450,text).x
			imgui.SetCursorScreenPos(imgui.ImVec2(p.x + obrez + 28,p.y + 14))
			imgui.PopTextWrapPos()
			imgui.EndTooltip()
		imgui.PopStyleVar()
    end
end
function imgui.CenterColumnTitleText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.TextColored(imgui.ImVec4(0.09, 0.09, 0.43, 1.0), text)
end
function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end
function imgui.CenterColumnTextColored(color, text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.TextColored(color, text)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
	local config = imgui.ImFontConfig()
    config.MergeMode = true
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    local iconRanges = imgui.new.ImWchar[3](fa.min_range, fa.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromFileTTF('Arial.ttf', 16.0, nil, glyph_ranges)
    icon = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/lib/fa-solid-900.ttf', 14.0, config, iconRanges)
	LogoFont = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/GOV/fonts/BebasNeueBold.ttf', 31.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
	VersionFont = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/GOV/fonts/BebasNeueBold.ttf', 20.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
end)

local newFrame = imgui.OnFrame(
    function() return ScriptMainMenu[0] end,
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(950, 450), imgui.Cond.FirstUseEver)
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.00, 0.00, 0.00, 1.0))
		imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.01, 0.01, 0.41, 1.0))
		imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0.0, 0.0))
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 6.0)
			imgui.Begin("Main Window", ScriptMainMenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
				local p = imgui.GetCursorScreenPos()
				local DrawList = imgui.GetWindowDrawList()
				DrawList:AddRectFilled(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + 180, p.y + 450), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.13, 0.13, 0.13, 1.0)))
				imgui.BeginChild("menuCild", imgui.ImVec2(180, 450), false)
					if MenuListID ~= 0 then
						imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.0, 0.0, 0.01))
						imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.0, 0.0, 0.0, 0.15))
						imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.0, 0.0, 0.0, 0.15))
						if imgui.Button(fa.ICON_HOME..u8" Главная", imgui.ImVec2(-1, 50), true) then MenuListID = 0 end
						imgui.PopStyleColor(3)
					end
					imgui.SetCursorPosY((imgui.GetWindowHeight() - 250)/2)
					imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.09, 0.09, 0.43, 0.15))
					imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.09, 0.09, 0.43, 0.4))
					imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.09, 0.09, 0.43, 0.4))
						if imgui.Button(fa.ICON_RSS_SQUARE..u8" Новости", imgui.ImVec2(-1, 50)) then MenuListID = 1 end
						imgui.Hint(u8"Новости и анонсы скрпта.")
						if imgui.Button(fa.ICON_SYNC..u8" Центр обновлений", imgui.ImVec2(-1, 50)) then MenuListID = 2 end
						imgui.Hint(u8"Информациях об обновлениях.")
						if imgui.Button(fa.ICON_TERMINAL..u8" Бинды", imgui.ImVec2(-1, 50)) then MenuListID = 3 end
						imgui.Hint(u8"Список действующих команд и горячих клавиш.")
						if imgui.Button(fa.ICON_USER_COG..u8" Настройки", imgui.ImVec2(-1, 50)) then MenuListID = 4 end
						imgui.Hint(u8"Настройки панелей, управление макросами.")
						if imgui.Button(fa.ICON_BOOK_READER..u8" Документы", imgui.ImVec2(-1, 50)) then MenuListID = 5 end
						imgui.Hint(u8"Кодексы, правила, уставы.")
					imgui.PopStyleColor()
				imgui.EndChild()
				---
				imgui.SameLine(nil, 0)
				---
				imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15.0, 15.0))
				imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.0, 0.0, 0.0, 0.0))
				imgui.PushStyleVarFloat(imgui.StyleVar.ScrollbarSize, 7)
					imgui.BeginChild("bodyCild", imgui.ImVec2(770, 450), true)
						if MenuListID == 0 then
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Special Weapons And Tactics")
							imgui.PopFont()
							imgui.NewLine()
							imgui.CenterTextColoredRGB("{8f408f}Правительство {ffffff} - подразделения в американских правоохранительных органах, которые используют лёгкое\nвооружение армейского типа и специальные тактики в операциях с высокимриском, в которых\nтребуются способности и навыки, выходящие за рамки возможностей обычных полицейских.")
							imgui.NewLine()
							imgui.CenterTextColoredRGB("{8f408f}GOV Secretary {ffffff}- Многофункциональное и совершенно бесплатное приложение, работающее на базе\n{ffffff}библиотеки {8f408f}MoonLoader{ffffff}, написан на языке {8f408f}Lua{ffffff}. Цель скрипта - облегчение работы сотрудников {8f408f}Правительство\n{ffffff}на игровом проекте SA:MP {0088ff}Pears Project{ffffff}.")
							imgui.NewLine()
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Личное дело")
							imgui.PopFont()
							local _, pID = sampGetPlayerIdByCharHandle(playerPed)
							imgui.CenterTextColoredRGB("{8f408f}Имя, фамилия: {ffffff}"..sampGetPlayerNickname(pID))
							imgui.CenterTextColoredRGB("{8f408f}Должность: {ffffff}"..playerRangName.."["..playerRang.."]")
							imgui.CenterTextColoredRGB("{8f408f}Предупреждения: {ffffff}"..playerWarns.."/5")
							imgui.SetCursorPosY(420)
							imgui.TextColoredRGB("{ffffff}Авторы скрипта: {cc0000}SiriuS{ffffff}, {cc0000}Wanie Lowely{ffffff}.")
						end
						if MenuListID == 1 then
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Список изменений и анонсов")
							imgui.PopFont()
							imgui.NewLine()
							for line in getChangeListFile:gmatch('[^\r\n]+') do
								if line:find('imgui.CreatePaddingX') then
									getNum = line:match('imgui.CreatePaddingX%((%d+)%)')
									imgui.CreatePaddingX(tonumber(getNum));
								end
								if line:find("imgui.NewLine") then
									imgui.NewLine()
								end
								if line:find("imgui.Separator") then
									imgui.Separator()
								end
								if line:find('imgui.TextColoredRGB%(".+"%)') then
									getText = line:match('imgui.TextColoredRGB%("(.+)"%)')
									imgui.TextColoredRGB(getText)
								end
								if line:find('imgui.CenterTextColoredRGB%(".+"%)') then
									getText = line:match('imgui.CenterTextColoredRGB%("(.+)"%)')
									imgui.CenterTextColoredRGB(getText)
								end
							end
						end
						if MenuListID == 2 then
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Центр обновлений GOV Secretary")
							imgui.PopFont()
							imgui.NewLine()
							imgui.CenterTextColoredRGB("Разработка скрипта продолжается, и со временем выходят новые фиксы, системы.")
							imgui.CenterTextColoredRGB("Новые обновления получаются путём автообновлений. В скрипте присутствуют вида вида обновлений:")
							imgui.CenterTextColoredRGB("{ffffff}• {8f408f}Приоритетные обновления {ffffff}- Скрипт обновляется сразу после запуска.")
							imgui.CenterTextColoredRGB("{ffffff}• {8f408f}Обычные обновления {ffffff}- При запуске скрипта Вы будете уведомлены о присутствие новой версии.")
							imgui.NewLine()
							imgui.NewLine()
							imgui.PushFont(VersionFont)
								if updateversion == thisScript().version then
									imgui.CreatePaddingY(30)
									imgui.CenterTextColoredRGB("{8f408f}Текущая версия: {ffffff}"..thisScript().version)
									imgui.CenterTextColoredRGB("{41a85f} Обновлений нет!")
								else
									imgui.CenterTextColoredRGB("{8f408f}Текущая версия: {ffffff}"..thisScript().version)
									imgui.CenterTextColoredRGB("{8f408f}Доступна версия: {41a85f}"..updateversion) end
							imgui.PopFont()
							imgui.NewLine()
							if updateversion ~= thisScript().version then
								imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.09, 0.09, 0.43, 0.15))
								imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.09, 0.09, 0.43, 0.4))
								imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.09, 0.09, 0.43, 0.4))
									if imgui.Button(fa.ICON_SYNC.."  "..u8" Обновить скрипт!", imgui.ImVec2(-1, 50)) then lua_thread.create(updateSCR) end
								imgui.PopStyleColor(3)
							end
							imgui.SetCursorPosY(320)
							imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.5, 0.5, 0.05))
							imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.5, 0.5, 0.5, 0.15))
							imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.5, 0.5, 0.5, 0.15))
							if imgui.Button(fa.ICON_HEADSET.."  "..u8"Связь с разработчиком (SiriuS)", imgui.ImVec2(-1, 50)) then 
								os.execute("start https://vk.me/rgayranyan")
							end
							if imgui.Button(fa.ICON_HEADSET.."  "..u8"Связь с разработчиком (Wanie)", imgui.ImVec2(-1, 50)) then 
								os.execute("start https://vk.me/avdeenkoo10")
							end
							imgui.PopStyleColor(3)
						end
						if MenuListID == 3 then
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Список команд")
							imgui.PopFont()
							imgui.NewLine()
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0.0, 0.0))
							imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.09, 0.09, 0.43, 1.0))
							imgui.PushStyleColor(imgui.Col.Separator, imgui.GetStyle().Colors[imgui.Col.Border])
							imgui.BeginChild("child", imgui.ImVec2(735, 250), true)
								imgui.CreatePaddingY(5)
								imgui.Columns(2)
								imgui.SetColumnWidth(-1, 235); imgui.CenterColumnTitleText(u8'Команда [Аргумент]'); imgui.NextColumn()
								imgui.SetColumnWidth(-1, 500); imgui.CenterColumnTitleText(u8'Описание'); imgui.NextColumn()
								imgui.Separator()
								imgui.CenterColumnText(u8"/sgov")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Меню скрипта")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/ncchat")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Очистить свой игровой чат | Не работает в случае MImGui Chat.")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/sfd [ID игрока]")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Поиск игрока (маркер обновляется раз в 3 сек.).")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/wtd")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Список преступников")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/srecon [1-15]")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Реконнект.")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/rb, /db, /cb [Текст]")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"OOC канал рации.")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/shp [ID игрока]")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Бросить шипы под колеса")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/prs [ID игрока]")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Начать преследование")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/govswat")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Объявить о наборе [ /gov ]")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/transferdep")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Объявить о транфсерах [ /d ]")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/pmir")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Правило миранды [ /pmir ]")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/agc")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Сокращенный /agetcar")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"/su1.1-18.2")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Выдача розыска")
							imgui.NewLine()
							imgui.EndChild()
							imgui.CreatePaddingY(20)
							imgui.PushFont(LogoFont)
							imgui.CenterTextColoredRGB("{8f408f}Список горячих клавиш")
							imgui.PopFont()
							imgui.NewLine()
							imgui.BeginChild("child2", imgui.ImVec2(735, 120), true)
								imgui.CreatePaddingY(5)
								imgui.Columns(2)
								imgui.SetColumnWidth(-1, 235); imgui.CenterColumnTitleText(u8'Комбинация'); imgui.NextColumn()
								imgui.SetColumnWidth(-1, 500); imgui.CenterColumnTitleText(u8'Действие'); imgui.NextColumn()
								imgui.Separator()
								imgui.CenterColumnText(u8"ALT + ПКМ")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Вечный прицел (скрипт держит прицел за Вас)")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Sniper Rifle + ПКМ + 1")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Включить прибор ночного видения на снайперском винтовке")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Sniper Rifle + ПКМ + 2")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Включить тепловизор на снайперском винтовке")
								imgui.Separator()
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Ваш макрос [ Ваша кнопка ]")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Надеть/снять бронежилет")
							imgui.NewLine()
							imgui.EndChild()
							imgui.PopStyleColor(2)
							imgui.PopStyleVar()
						end
						if MenuListID == 5 then
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Важные документы")
							imgui.PopFont()
							imgui.CenterTextColoredRGB("{8f408f}Выберите документ, который вам нужен.")
							imgui.NewLine()
							if imgui.Button(fa.ICON_TASKS..u8" Уголовный кодекс", imgui.ImVec2(-1, 50)) then MenuListID = 51 end
							if imgui.Button(fa.ICON_TASKS..u8" Кодекс об Административных Правонарушениях", imgui.ImVec2(-1, 50)) then MenuListID = 52 end
							if imgui.Button(fa.ICON_TASKS..u8" Памятка к первым рангам", imgui.ImVec2(-1, 50)) then MenuListID = 53 end
							if imgui.Button(fa.ICON_TASKS..u8" Общее положение подразделения", imgui.ImVec2(-1, 50)) then MenuListID = 54 end
							if imgui.Button(fa.ICON_TASKS..u8" Правила общения на волне департамента", imgui.ImVec2(-1, 50)) then MenuListID = 55 end
						end
						if MenuListID == 51 then
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Углолвный кодекс")
							imgui.PopFont()
							imgui.NewLine()
							for line in getUKFile:gmatch('[^\r\n]+') do
								if line:find('imgui.CreatePaddingX') then
									getNum = line:match('imgui.CreatePaddingX%((%d+)%)')
									imgui.CreatePaddingX(tonumber(getNum));
								end
								if line:find("imgui.NewLine") then
									imgui.NewLine()
								end
								if line:find("imgui.Separator") then
									imgui.Separator()
								end
								if line:find('imgui.TextColoredRGB%(".+"%)') then
									getText = line:match('imgui.TextColoredRGB%("(.+)"%)')
									imgui.TextColoredRGB(getText)
								end
								if line:find('imgui.CenterTextColoredRGB%(".+"%)') then
									getText = line:match('imgui.CenterTextColoredRGB%("(.+)"%)')
									imgui.CenterTextColoredRGB(getText)
								end
							end
						end
						if MenuListID == 52 then
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Кодекс об Административных Правонарушениях")
							imgui.PopFont()
							imgui.NewLine()
							for line in getKoAPFile:gmatch('[^\r\n]+') do
								if line:find('imgui.CreatePaddingX') then
									getNum = line:match('imgui.CreatePaddingX%((%d+)%)')
									imgui.CreatePaddingX(tonumber(getNum));
								end
								if line:find("imgui.NewLine") then
									imgui.NewLine()
								end
								if line:find("imgui.Separator") then
									imgui.Separator()
								end
								if line:find('imgui.TextColoredRGB%(".+"%)') then
									getText = line:match('imgui.TextColoredRGB%("(.+)"%)')
									imgui.TextColoredRGB(getText)
								end
								if line:find('imgui.CenterTextColoredRGB%(".+"%)') then
									getText = line:match('imgui.CenterTextColoredRGB%("(.+)"%)')
									imgui.CenterTextColoredRGB(getText)
								end
							end
						end
						if MenuListID == 53 then
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Памятка к первым рангам")
							imgui.PopFont()
							imgui.NewLine()
							for line in getFirstRangsFile:gmatch('[^\r\n]+') do
								if line:find('imgui.CreatePaddingX') then
									getNum = line:match('imgui.CreatePaddingX%((%d+)%)')
									imgui.CreatePaddingX(tonumber(getNum));
								end
								if line:find("imgui.NewLine") then
									imgui.NewLine()
								end
								if line:find("imgui.Separator") then
									imgui.Separator()
								end
								if line:find('imgui.TextColoredRGB%(".+"%)') then
									getText = line:match('imgui.TextColoredRGB%("(.+)"%)')
									imgui.TextColoredRGB(getText)
								end
								if line:find('imgui.CenterTextColoredRGB%(".+"%)') then
									getText = line:match('imgui.CenterTextColoredRGB%("(.+)"%)')
									imgui.CenterTextColoredRGB(getText)
								end
							end
						end
						if MenuListID == 54 then
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Общее положение подразделения")
							imgui.PopFont()
							imgui.NewLine()
							for line in getObweePolojeniePodrazdelenia:gmatch('[^\r\n]+') do
								if line:find('imgui.CreatePaddingX') then
									getNum = line:match('imgui.CreatePaddingX%((%d+)%)')
									imgui.CreatePaddingX(tonumber(getNum));
								end
								if line:find("imgui.NewLine") then
									imgui.NewLine()
								end
								if line:find("imgui.Separator") then
									imgui.Separator()
								end
								if line:find('imgui.TextColoredRGB%(".+"%)') then
									getText = line:match('imgui.TextColoredRGB%("(.+)"%)')
									imgui.TextColoredRGB(getText)
								end
								if line:find('imgui.CenterTextColoredRGB%(".+"%)') then
									getText = line:match('imgui.CenterTextColoredRGB%("(.+)"%)')
									imgui.CenterTextColoredRGB(getText)
								end
							end
						end
						if MenuListID == 55 then
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Правила общения на волне департамента")
							imgui.PopFont()
							imgui.NewLine()
							for line in getdepartmentpravila:gmatch('[^\r\n]+') do
								if line:find('imgui.CreatePaddingX') then
									getNum = line:match('imgui.CreatePaddingX%((%d+)%)')
									imgui.CreatePaddingX(tonumber(getNum));
								end
								if line:find("imgui.NewLine") then
									imgui.NewLine()
								end
								if line:find("imgui.Separator") then
									imgui.Separator()
								end
								if line:find('imgui.TextColoredRGB%(".+"%)') then
									getText = line:match('imgui.TextColoredRGB%("(.+)"%)')
									imgui.TextColoredRGB(getText)
								end
								if line:find('imgui.CenterTextColoredRGB%(".+"%)') then
									getText = line:match('imgui.CenterTextColoredRGB%("(.+)"%)')
									imgui.CenterTextColoredRGB(getText)
								end
							end
						end
						if MenuListID == 4 then
							imgui.PushFont(LogoFont)
								imgui.CenterTextColoredRGB("{8f408f}Настройки GOV Secretary")
							imgui.PopFont()
							imgui.NewLine()
							imgui.PushFont(settingFont)
								imgui.TextColoredRGB("Кастомизация чатов")
							imgui.PopFont()
							imgui.SameLine(nil, 5); imgui.TextQuestion(u8"Заменяет стандаитный вид /r, /d на более красивый и удобный")
							imgui.SameLine(nil, 30); if mimgui_addons.ToggleButton("Test##1", cfg_customChats) then end
							imgui.NewLine()
							imgui.PushFont(settingFont)
								imgui.TextColoredRGB("Макрос бронежилета")
							imgui.PopFont()
							imgui.SameLine(nil, 5); imgui.TextQuestion(u8"Позволяет при нажатие определённыого клавиша надеть бронежилет")
							imgui.SameLine(nil, 30);
							if imgui.Button(vkeys.id_to_name(cfg_armourBind), imgui.ImVec2(60, 20), true) then 
								setBindNewKey = "Armour"
								ScriptMainMenu[0] = false
							end
							
							imgui.NewLine()
							imgui.PushFont(settingFont)
								imgui.TextColoredRGB("Фильтр контрактов")
							imgui.PopFont()
							imgui.SameLine(nil, 5); imgui.TextQuestion(u8"Филтрирует чат от объявлений хитов/сектантов")
							imgui.SameLine(nil, 30); if mimgui_addons.ToggleButton("Test##2", cfg_Contracts) then end
							imgui.NewLine()
							imgui.PushFont(settingFont)
								imgui.TextColoredRGB("Фильтр наборов")
							imgui.PopFont()
							imgui.SameLine(nil, 5); imgui.TextQuestion(u8"Филтрирует чат от объявлений наборов в мафии/банд")
							imgui.SameLine(nil, 30); if mimgui_addons.ToggleButton("Test##3", cfg_Invites) then end							
							imgui.NewLine()
							imgui.PushFont(settingFont)
								imgui.TextColoredRGB("Фильтр ордеров")
							imgui.PopFont()
							imgui.SameLine(nil, 5); imgui.TextQuestion(u8"Филтрирует чат от объявлений выдачи ордера")
							imgui.SameLine(nil, 30); if mimgui_addons.ToggleButton("Test##4", cfg_Orders) then end						
							imgui.NewLine()
							imgui.PushFont(settingFont)
								imgui.TextColoredRGB("Фильтр сообщений от администрации")
							imgui.PopFont()
							imgui.SameLine(nil, 5); imgui.TextQuestion(u8"Филтрирует чат от объявлений администрации")
							imgui.SameLine(nil, 30); if mimgui_addons.ToggleButton("Test##5", cfg_admSMS) then end
							imgui.NewLine()
							imgui.PushFont(settingFont)
								imgui.TextColoredRGB("Фильтр свадьб")
							imgui.PopFont()
							imgui.SameLine(nil, 5); imgui.TextQuestion(u8"Филтрирует чат от браокв")
							imgui.SameLine(nil, 30); if mimgui_addons.ToggleButton("Test##6", cfg_Proposes) then end
						end
					imgui.EndChild()
					imgui.PopStyleColor()
				imgui.PopStyleVar()
			imgui.End()
		imgui.PopStyleVar()
		imgui.PopStyleColor(2)
    end
)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(15000) end
	while not sampIsLocalPlayerSpawned() do  wait(0) end
	if sampGetCurrentServerAddress() ==  "176.32.37.62" then
		while isInGov == nil do
			wait(120)
			sampSendChat('/stats')
			openStats = true
			wait(2500)
		end
	else 
		sampAddChatMessage("** Секретарша: {585858}Произашла ошибка при авторизации в системе безопасности.{585858}. {8f408f} **", 0x8f408f) 
		thisScript():unload()
	end
	checkVers()
	sampRegisterChatCommand("sgov", function()
		ScriptMainMenu[0] = not ScriptMainMenu[0]
		lockPlayerControl(ScriptMainMenu[0])
	end)
	httpRequest("https://raw.githubusercontent.com/Maksim-Avdeenko/SWAT_Tools/main/FilesTXT/news.txt", nil, function(response, code, headers, status)
		if response then
			getChangeListFile = u8:decode(response)
		else
			print('Ошибка: ', code)
		end
	end)
	httpRequest("https://raw.githubusercontent.com/Maksim-Avdeenko/SWAT_Tools/main/FilesTXT/Criminal-Code.txt", nil, function(response, code, headers, status)
		if response then
			getUKFile = u8:decode(response)
		else
			print('Ошибка: ', code)
		end
	end)
	httpRequest("https://raw.githubusercontent.com/Maksim-Avdeenko/SWAT_Tools/main/FilesTXT/Administrative-Code.txt", nil, function(response, code, headers, status)
		if response then
			getKoAPFile = u8:decode(response)
		else
			print('Ошибка: ', code)
		end
	end)
	httpRequest("https://raw.githubusercontent.com/Maksim-Avdeenko/SWAT_Tools/main/FilesTXT/First-Rangs.txt", nil, function(response, code, headers, status)
		if response then
			getFirstRangsFile = u8:decode(response)
		else
			print('Ошибка: ', code)
		end
	end)
	httpRequest("https://raw.githubusercontent.com/Maksim-Avdeenko/SWAT_Tools/main/FilesTXT/Obwee-Polojenie.txt", nil, function(response, code, headers, status)
		if response then
			getObweePolojeniePodrazdelenia = u8:decode(response)
		else
			print('Ошибка: ', code)
		end
	end)
	httpRequest("https://raw.githubusercontent.com/Maksim-Avdeenko/SWAT_Tools/main/FilesTXT/PravilaDepartment.txt", nil, function(response, code, headers, status)
		if response then
			getdepartmentpravila = u8:decode(response)
		else
			print('Ошибка: ', code)
		end
	end)
    sampRegisterChatCommand("sfd",find)
	sampRegisterChatCommand("wtd", wanted_)
	sampRegisterChatCommand("shp", ship_)
	sampRegisterChatCommand("prs", pursuit_)
	sampRegisterChatCommand("govswat", gov_)
	sampRegisterChatCommand("transferdep", transfer_)
	sampRegisterChatCommand("sclearchat", clearchat)
    sampRegisterChatCommand("srecon", reconnect)
    sampRegisterChatCommand("fb", oocf)
    sampRegisterChatCommand("ub", oocu)
    sampRegisterChatCommand("rb", oocr)
    sampRegisterChatCommand("db", oocd)
    sampRegisterChatCommand("cb", oocc)
	sampRegisterChatCommand("pmir", pravilomirandy_)
	sampRegisterChatCommand("agc", agetcar_)
	sampRegisterChatCommand("su1.1", su1_1)
	sampRegisterChatCommand("su1.2", su1_2)
	sampRegisterChatCommand("su1.3", su1_3)
	sampRegisterChatCommand("su1.4", su1_4)
	sampRegisterChatCommand("su2.1", su2_1)
	sampRegisterChatCommand("su2.2", su2_2)
	sampRegisterChatCommand("su3.1", su3_1)
	sampRegisterChatCommand("su3.2", su3_2)
	sampRegisterChatCommand("su3.3", su3_3)
	sampRegisterChatCommand("su3.4", su3_4)
	sampRegisterChatCommand("su3.5", su3_5)
	sampRegisterChatCommand("su4.1", su4_1)
	sampRegisterChatCommand("su5.1", su5_1)
	sampRegisterChatCommand("su5.2", su5_2)
	sampRegisterChatCommand("su6.1", su6_1)
	sampRegisterChatCommand("su6.2", su6_2)
	sampRegisterChatCommand("su7.1", su7_1)
	sampRegisterChatCommand("su7.2", su7_2)
	sampRegisterChatCommand("su8.1", su8_1)
	sampRegisterChatCommand("su8.2", su8_2)
	sampRegisterChatCommand("su8.3", su8_3)
	sampRegisterChatCommand("su8.4", su8_4)
	sampRegisterChatCommand("su8.5", su8_5)
	sampRegisterChatCommand("su8.6", su8_6)
	sampRegisterChatCommand("su8.7", su8_7)
	sampRegisterChatCommand("su8.8", su8_8)
	sampRegisterChatCommand("su9.1", su9_1)
	sampRegisterChatCommand("su9.2", su9_2)
	sampRegisterChatCommand("su9.3", su9_3)
	sampRegisterChatCommand("su9.4", su9_4)
	sampRegisterChatCommand("su10.1", su10_1)
	sampRegisterChatCommand("su10.2", su10_2)
	sampRegisterChatCommand("su10.3", su10_3)
	sampRegisterChatCommand("su10.4", su10_4)
	sampRegisterChatCommand("su12.1", su12_1)
	sampRegisterChatCommand("su13.1", su13_1)
	sampRegisterChatCommand("su14.1", su14_1)
	sampRegisterChatCommand("su14.2", su14_2)
	sampRegisterChatCommand("su15.1", su15_1)
	sampRegisterChatCommand("su15.2", su15_2)
	sampRegisterChatCommand("su16.1", su16_1)
	sampRegisterChatCommand("su16.2", su16_2)
	sampRegisterChatCommand("su16.3", su16_3)
	sampRegisterChatCommand("su16.4", su16_4)
	sampRegisterChatCommand("su16.5", su16_5)
	sampRegisterChatCommand("su17.1", su17_1)
	sampRegisterChatCommand("su17.2", su17_2)
	sampRegisterChatCommand("su18.1", su18_1)
	sampRegisterChatCommand("su18.2", su18_2)
    lua_thread.create(function()
		while true do wait(0) 
			if ifddd == true then 
				sampSendChat(string.format("/find %d", ifdd)) 
				targetid = ifdd
				wait(3000)
			end
		end 
    end)
    while true do wait(0)
		if setBindNewKey ~= nil then
			local sw, sh = getScreenResolution()
			lockPlayerControl(true)
			sampToggleCursor(true)
			renderFontDrawText(font, "Изменение настройки бинда. Нажимайте на любую клавишу:", sw / 2 - renderGetFontDrawTextLength(font, "Изменение настройки бинда. Нажимайте на любую клавишу:") / 2, sh / 2, 0xFFFFFFFF, true)
            renderFontDrawText(font, "BACKSPACE - отмена", sw / 2 - renderGetFontDrawTextLength(font, "ESC - отмена") / 2, sh / 2 + 20, 0xFFFFFFFF, true)
		end
		if isKeyJustPressed(cfg_armourBind) and setBindNewKey == nil and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() then sampSendChat("/usearm") end
		getGunUpgrades()
   end
end

function sampev.onShowDialog(dialogid, style, title, button1, button2, text)
    if openStats and dialogid == 1500 then
        for line in text:gmatch('[^\r\n]+') do
			if line:find('Организация: %{......%}Правительство')  then
				isInGov = true
			end
            if isInGov then
                if line:find('Ранг:') then
                    if playerRangName == "Неизвестно" and playerRang == 0 then
                        playerRangName, playerRang = line:match('Ранг: %{......%}(.+) %[(%d+)%]')
                    end
                end
                if line:find('Выговоры:') then
                    playerWarns = line:match('Выговоры: %{......%}(.*)%/.*')
                end
            end
        end
       if isInGov == true then
            sampAddChatMessage("** Дистепчер: {585858}Приветствую, "..playerRangName..". На связи секретарша Правительство {8f408f}[ /SGOV ] {8f408f}**", 0x8f408f)
        else
			sampAddChatMessage("** Дистепчер: {585858}Произошла ошибка при авторизации в системе безопасности.{585858}. {8f408f} **", 0x8f408f)
			thisScript():unload()
        end
		isInGov = true
        openStats = false
        return false
	end
end
function sampGetPlayerIdByNickname(nick)
    local _, myid = sampGetPlayerIdByCharHandle(playerPed)
    if tostring(nick) == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 999 do if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == tostring(nick) then return i end end
end
function sampev.onServerMessage(color, message)
	if cfg_customChats[0] == true then
		if message:find('%* %[.+%] %{?.?.?.?.?.?.?%}?.+ %{?.?.?.?.?.?.?%}?%w+%_%w+%{?.?.?.?.?.?.?%}?%[%d+%]: //%s?.+ %*%*') and color == -8224086 or color == -11908533 then
			local frac, tPart1, tPart2 = string.match(message, "%* %[(.+)%] (%{?.?.?.?.?.?.?%}?.+ %{?.?.?.?.?.?.?%}?%w+%_%w+%{?.?.?.?.?.?.?%}?%[%d+%]): //%s?(.+) %*%*")
			sampAddChatMessage("["..frac.."-OOC] "..tPart1..": "..tPart2, 0xff8282)
			return false
		elseif message:find('%* %[.+%] %{?.?.?.?.?.?.?%}?.+ %{?.?.?.?.?.?.?%}?%w+%_%w+%{?.?.?.?.?.?.?%}?%[%d+%]: .+ %*%*') and color == -8224086 or color == -11908533 then
			local frac, tPart1, tPart2 = string.match(message, "%* %[(.+)%] (%{?.?.?.?.?.?.?%}?.+ %{?.?.?.?.?.?.?%}?%w+%_%w+%{?.?.?.?.?.?.?%}?%[%d+%]): (.+) %*%*")
			sampAddChatMessage("["..frac.."-IC] "..tPart1..": "..tPart2, 0xff8282)
			return false
		elseif message:find('^%*%* (.+) %{?.?.?.?.?.?.?%}?(%w+%_%w+)%{?.?.?.?.?.?.?%}?: //%s?(.+)') and color == -86 or color == -11908533 then
			local pRang, pNick, pText = string.match(message, "^%*%* (.+) %{?.?.?.?.?.?.?%}?(%w+%_%w+)%{?.?.?.?.?.?.?%}?: //%s?(.+)")
			sampAddChatMessage("[R-OOC] "..pRang.." {ffffff}"..pNick.."["..sampGetPlayerIdByNickname(pNick).."]: "..pText, 0x00C6FF)
			return false
		elseif message:find('^%*%* (.+) (%{?.?.?.?.?.?.?%}?)(%w+%_%w+)%{?.?.?.?.?.?.?%}?: (.+)') and color == -86 or color == -11908533 then
			local pRang, pNick, pText = string.match(message, "^%*%* (.+) %{?.?.?.?.?.?.?%}?(%w+%_%w+)%{?.?.?.?.?.?.?%}?: (.+)")
			sampAddChatMessage("[R-IC] "..pRang.." {ffffff}"..pNick.."["..sampGetPlayerIdByNickname(pNick).."]: "..pText, 0x00C6FF)
			return false
		end
	end
    if cfg_Contracts[0] == true then
        if message:find('%* %[.*Реклама%]:%{......%}.+, %{......%}Контакт: [^Неизвестный]') or message:find('%* Обработал:{......} .+ %*') then
            print(message)
            return false
        end
    end
    if cfg_Invites[0] == true then
        if (color == -86 or color == -858993494) and (message:find("%*%*%p+%{") or message:find("%[ %{00cc00%}Открыт %{ffffff%}| %{00cc00%}/invites %{ffffff%}%]") or message:find("Открыт призыв в NGSA: %[ %{333300%}Открыт %{ffffff%}|")) then
            print(message)
            return false
        end
    end
    if cfg_Orders[0] == true then
        if (color == 869072810 and message:find("выдал ордер адвокату") or (color == -86 or color == -858993494) and (message:find("%*%*%p+%P") or message:find("%a+_%a+:"))) then
            print(message)
            return false
        end
    end
    if cfg_admSMS[0] == true then
        if (message:find("%{ff9000%}%* %[ADM%]%a+_%a+%[%d+%]:") or message:find("%{0088ff%}%(%( %a+_%a+%[%d+%]%: %{FFFFFF%}")) then
            print(message)
            return false
        end
    end
    if not cfg_Proposes[0] == true then
        if color == -86 and (message:find("%{0088ff%}___________________________________________________________________________________________________________") or message:find("%{0088ff%}%[Pears Project%]: %{aeff00%}Поздравляем")) then
            print(message)
            return false
        end
    end
end

function find(param) 
    local id = string.match(param, '(%d+)') 
        if ifddd ~= true then 
            if id ~= nil then
				if sampIsPlayerConnected(id) then
					ifdd = id 
					ifddd = true
					targetid = ifdd
					sampAddChatMessage("** Секретарша: {585858}Вы запустили преследование за {8f408f}"..sampGetPlayerNickname(targetid).."{585858}. {8f408f}**", 0x8f408f)
				else
					sampAddChatMessage("** Секретарша: {585858}Боец, такого человека не существует в штате... {8f408f}**", 0x8f408f) end
			else 
                sampAddChatMessage("** Секретарша: {585858}Боец, прошу уточнить запрос {8f408f}[ /fd ID игрока ] **", 0x8f408f) 
            end 
        else 
            ifddd = false
            sampAddChatMessage("** Секретарша: {585858}Хорошо, вы прекратили преследование за {8f408f}"..sampGetPlayerNickname(targetid).."{585858}. {8f408f}**", 0x8f408f) 
			targetid = -1
	   end 
end

function wanted_()
    lua_thread.create(function()
    sampSendChat("/wanted")
    end)
end

function ship_(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/ship %d", id))
  else
	sampAddChatMessage("** Дистепчер: {585858}Кинуть шипы под колеса [ /sh ID ] {8f408f} **", 0x8f408f)
  end
end

function pursuit_(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/pursuit %d", id))
  else
	sampAddChatMessage("** Дистепчер: {585858}Начать преследование [ /pr ID ] {8f408f} **", 0x8f408f)
  end
end

function gov_()
	if tonumber(playerRang) >= 8 then
		lua_thread.create(function()
			sampAddChatMessage("** Дистепчер: {585858}Начинаем вещать в государственные новости! {8f408f} **", 0x8f408f)
			wait(1000)
			sampSendChat("/d Внимание, департамент. Новости SWAT в эфире!")
			wait(5000)
			sampSendChat("/gov Открыт приём заявлений на зачисление в ряди этитного подразделения SWAT.")
			wait(5000)
			sampSendChat("/gov Для записи на собеседование Вы можете оставить своё электронное резюме на официальном портале.")
			wait(1000)
			sampSendChat("/d Спасибо за внимание! Окончил вещание.")
		end)
	else sampAddChatMessage("** Дистепчер: {585858}Недостаточно прав для выполнения этой операции! [ 8+ Rank ] {8f408f} **", 0x8f408f) end
end

function transfer_()
	if tonumber(playerRang) >= 8 then
		lua_thread.create(function()
			sampAddChatMessage("** Дистепчер: {585858}Объявляем о трансферах в SWAT. {8f408f} **", 0x8f408f)
			wait(1500)
			sampSendChat("/d Внимание, коллеги. Открыты трансферы в элитное подразделение SWAT.")
			wait(5000)
			sampSendChat("/d Вся информация находиться на официальном портале подразделения.")
		end)
	else sampAddChatMessage("** Дистепчер: {585858}Недостаточно прав для выполнения этой операции! [ 8+ Rank ] {8f408f} **", 0x8f408f) end
end

function imgui.CreatePaddingX(padding_custom)
	padding_custom = padding_custom or 8 
	imgui.SetCursorPosX(imgui.GetCursorPos().x + padding_custom)
end
function imgui.CreatePaddingY(padding_custom)
	padding_custom = padding_custom or 8
	imgui.SetCursorPosY(imgui.GetCursorPos().y + padding_custom)
end
function imgui.CreatePadding(padding_custom,padding_custom2)
	padding_custom, padding_custom2 = padding_custom or 8, padding_custom2 or 8
	imgui.CreatePaddingX(padding_custom)
	imgui.CreatePaddingY(padding_custom2)
end

function getGunUpgrades()
	local weapon = getCurrentCharWeapon(playerPed)
	--------------------------- [ PRICEL ] ---------------------------
	if weapon ~= 0 then
		if isKeyDown(VK_LMENU) and isKeyJustPressed(VK_RBUTTON) and not isCharInAnyCar(PLAYER_PED) and not sampIsChatInputActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive() then
			pircelEnabled = not pircelEnabled
			if pircelEnabled == true then
				notf.addNotification(string.format("Вы успешно активировали постоянный прицел."), 5, 1) 
			end
			if pircelEnabled == false then
				notf.addNotification(string.format("Вы успешно деактивировали постоянный прицел."), 5, 1) 
			end
		end
		if pircelEnabled == true then
			setGameKeyState(6, 255)
		end
	end
	if weapon == 34 then
		if isKeyDown(VK_RBUTTON) or pircelEnabled == true then
			-------------------------- [ N-VISION ] --------------------------
			if isKeyJustPressed(VK_1) and not isCharInAnyCar(PLAYER_PED) and not sampIsChatInputActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive() then
				nightEnabled = not nightEnabled
				if nightEnabled == true then
					notf.addNotification(string.format("Вы успешно активировали прибор ночного видения снайперской винтовки."), 5, 1) 
					setInfraredVision(false)
					infraredEnabled = false
					setNightVision(true)
					nightEnabled = true
				end
				if nightEnabled == false then
					notf.addNotification(string.format("Вы успешно деактивировали прибор ночного видения снайперской винтовки."), 5, 1) 
					setInfraredVision(false)
					infraredEnabled = false
					setNightVision(false)
					nightEnabled = false
				end
			end
			-------------------------- [ I-VISION ] --------------------------
			if isKeyJustPressed(VK_2) and not isCharInAnyCar(PLAYER_PED) and not sampIsChatInputActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive() then
				infraredEnabled = not infraredEnabled
				if infraredEnabled == true then
					notf.addNotification(string.format("Вы успешно активировали тепловизор снайперской винтовки."), 5, 1) 
					setNightVision(false)
					nightEnabled = false
					setInfraredVision(true)
					infraredEnabled = true
				end
				if infraredEnabled == false then
					notf.addNotification(string.format("Вы успешно деактивировали тепловизор снайперской винтовки."), 5, 1) 
					setNightVision(false)
					nightEnabled = false
					setInfraredVision(false)
					infraredEnabled = false
				end
			end
		end
	end
end

function onWindowMessage(msg, wparam, lparam)
	if msg == 0x100 or msg == 0x104 then
		if wparam == 0x08 and not isPauseMenuActive() then
			setBindNewKey = nil
		end
		if bit.band(lparam, 0x40000000) == 0 then
			if setBindNewKey == "Armour" then
				cfg_armourBind = wparam
				setBindNewKey = nil
			end
		end
	end
	if msg == 0x100 or msg == 0x101 then
		if wparam == 0x1B and not isPauseMenuActive() then
			if ScriptMainMenu[0] and not sampIsDialogActive() then
				consumeWindowMessage(true, false)
				if msg == 0x101 then
					ScriptMainMenu[0] = false
					lockPlayerControl(ScriptMainMenu[0])
                end
            end
        end
    end
end

function clearchat()
    memory.fill(sampGetChatInfoPtr() + 306, 0x0, 25200)
    memory.write(sampGetChatInfoPtr() + 306, 25562, 4, 0x0)
    memory.write(sampGetChatInfoPtr() + 0x63DA, 1, 1)
end

function reconnect(param)
    time = tonumber(param)
    if time ~= nil and time >= 5 and time <= 15 then
        res = true
    else
        notf.addNotification(string.format("Реконнект. | Используйте: /srecon 5-15"), 3, 2)
    end
end

function su1_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 4 1.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 1.1 [ /su1.1 ID ] {8f408f} **", 0x8f408f)
  end
end

function su1_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 5 1.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 1.2 [ /su1.2 ID ] {8f408f} **", 0x8f408f)
  end
end

function su1_3(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 1.3", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 1.3 [ /su1.3 ID ] {8f408f} **", 0x8f408f)
  end
end

function su1_4(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 1.4", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 1.4 [ /su1.4 ID ] {8f408f} **", 0x8f408f)
  end
end

function su2_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 2.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 2.1[ /su2.1 ID ] {8f408f} **", 0x8f408f)
  end
end

function su2_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 2.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 2.2 [ /su2.2 ID ] {8f408f} **", 0x8f408f)
  end
end

function su3_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 2 3.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 3.1 [ /su3.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su3_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 2 3.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 3.2 [ /su3.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su3_3(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 1 3.3", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 3.3 [ /su3.3 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su3_4(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 2 3.4", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 3.4 [ /su3.4 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su3_5(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 2 3.5", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 3.5 [ /su3.5 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su4_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 1 4.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 4.1 [ /su4.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su5_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 2 5.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 5.1 [ /su5.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su5_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 3 5.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 5.2 [ /su5.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su6_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 6.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 6.1 [ /su6.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su6_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 6.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 6.2 [ /su6.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su7_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 7.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 7.1 [ /su7.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su7_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 7.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 7.2 [ /su7.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su8_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 5 8.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 8.1 [ /su8.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su8_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 1 8.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 8.2 [ /su8.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su8_3(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 1 8.3", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 8.3 [ /su8.3 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su8_4(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 3 8.4", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 8.4 [ /su8.4 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su8_5(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 2 8.5", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 8.5 [ /su8.5 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su8_6(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 1 8.6", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 8.6 [ /su8.6 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su8_7(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 2 8.7", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 8.7 [ /su8.7 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su8_8(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 4 8.8", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 8.8 [ /su8.8 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su9_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 4 9.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 9.1 [ /su9.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su9_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 4 9.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 9.2 [ /su9.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su9_3(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 4 9.3", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 9.3 [ /su9.3 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su9_4(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 1 9.4", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 9.4 [ /su9.4 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su10_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 3 10.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 10.1 [ /su10.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su10_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 5 10.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 10.2 [ /su10.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su10_3(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 2 10.3", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 10.3 [ /su10.3 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su10_4(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 3 10.4", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 10.4 [ /su10.4 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su12_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 2 12.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 12.1 [ /su12.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su13_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 13.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 13.1 [ /su13.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su14_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 4 14.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 14.1 [ /su14.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su14_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 4 14.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 14.2 [ /su14.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su15_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 3 15.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 15.1 [ /su15.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su15_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 15.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 15.2 [ /su15.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su16_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 3 16.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 16.1 [ /su16.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su16_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 3 16.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 16.2 [ /su16.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su16_3(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 16.3", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 16.3 [ /su16.3 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su16_4(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 16.4", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 16.4 [ /su16.4 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su16_5(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 16.5", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 16.5 [ /su16.5 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su17_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 4 17.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 17.1 [ /su17.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su17_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 17.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 17.2 [ /su17.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su18_1(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 2 18.1", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 18.1 [ /su18.1 ID ] {8f408f} **", 0x8f408f) 
  end
end

function su18_2(param)
  local id = string.match(param, '(%d+)')
  if id ~= nil then
	sampSendChat(string.format("/su %d 6 18.2", id))
  else
	sampAddChatMessage("** Дистепчер: {585858} Выдать розыск за 18.2 [ /su18.2 ID ] {8f408f} **", 0x8f408f) 
  end
end

function pravilomirandy_()
    lua_thread.create(function()
    sampSendChat("/z Вас задержал сотрудник правоохранительных органов.")
    wait(1500)
    sampSendChat("/z Вы имеете право хранить молчание.")
    wait(1500)
    sampSendChat("/z Всё, что вы скажете, может и будет использовано против вас в суде.")
    wait(1500)
    sampSendChat("/z Ваш адвокат может присутствовать при допросе.")
    wait(1500)
    sampSendChat("/z Если вы не можете оплатить услуги адвоката, он будет предоставлен вам государством.")
    wait(1500)
    sampSendChat("/z Вам были зачитаны Ваши права. Вы арестованы!")
    end)
end

function agetcar_()
    lua_thread.create(function()
    sampSendChat("/agetcar")
    end)
end

function oocf(param) 
	local text = string.match(param, '%s*(.+)') 
		if text ~= nil then 
			sampSendChat(string.format("/f // %s", text)) 
	else 
		notf.addNotification(string.format("Рация фракции. | OOC\n\nИспользуйте: /fb Текст"), 5, 2) 
    end
end

function oocu(param) 
	local text = string.match(param, '%s*(.+)') 
		if text ~= nil then 
			sampSendChat(string.format("/u // %s", text)) 
	else 
        notf.addNotification(string.format("Рация банд и мафий. | OOC\n\nИспользуйте: /ub Текст"), 5, 2) 
    end
end

function oocr(param) 
	local text = string.match(param, '%s*(.+)') 
		if text ~= nil then 
			sampSendChat(string.format("/r // %s", text)) 
	else 
        notf.addNotification(string.format("Канал фракции. | OOC\n\nИспользуйте: /rb Текст"), 5, 2) 
    end
end

function oocd(param) 
	local text = string.match(param, '%s*(.+)') 
		if text ~= nil then 
		sampSendChat(string.format("/d // %s", text)) 
	else 
        notf.addNotification(string.format("Канал департамента. | OOC\n\nИспользуйте: /db Текст"), 5, 2) 
    end
end

function oocc(param) 
	local text = string.match(param, '%s*(.+)') 
		if text ~= nil then 
			sampSendChat(string.format("/c // %s", text)) 
	else 
        notf.addNotification(string.format("Рация семьи. | OOC\n\nИспользуйте: /сb Текст"), 5, 2) 
    end
end

function sampev.onPlayerQuit(playerID)
	if ifddd == true and targetid == playerID then
		ifddd = false
		sampAddChatMessage("** Секретарша: {585858}Преследование за {8f408f}"..sampGetPlayerNickname(targetID).."{585858} прекращено. Он покинул штат. {8f408f}**", 0x8f408f) 
		targetid = -1
	end
end

function save()
	Config.CORE.customChats = cfg_customChats[0]
	Config.CORE.armourBind = cfg_armourBind
	
	
	Config.FILTERS.Contracts = cfg_Contracts[0]
	Config.FILTERS.Invites = cfg_Invites[0]
	Config.FILTERS.Orders = cfg_Orders[0]
	Config.FILTERS.admSMS = cfg_admSMS[0]
	Config.FILTERS.Proposes = cfg_Proposes[0]
	
    if inicfg.save(Config, '..\\GOV\\Settings.ini') then 
		print("{8f408f}[ GOV ]: {ffffff}Сохранение настроек прошло успешно.")
    else
		print("{8f408f}[ GOV ]: {ffffff}При сохранении настроек произашла ошибка.")
    end
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
		save()
        lockPlayerControl(false)
        showCursor(false, false)
        setNightVision(false)
        setInfraredVision(false)
    end
end