script_name("{ff7e7e}Hospital Helper [2.99]")
script_description('Кроссплатформенный скрипт - хелпер для игроков которые работают в больницах в SAMP Arizona RP')
script_author("MTG MODS")
script_version("2.99")

require "lib.moonloader"
require 'encoding'.default = 'CP1251'
local u8 = require 'encoding'.UTF8

-----------------------------------------------ПОДКЛЮЧЕНИЕ JSON-----------------------------------------------
local function deepcopy(o, seen)
    seen = seen or {}
    if o == nil then return nil end
    if seen[o] then return seen[o] end

    local no
    if type(o) == 'table' then
        no = {}
        seen[o] = no

        for k, v in next, o, nil do
            no[deepcopy(k, seen)] = deepcopy(v, seen)
        end
        setmetatable(no, deepcopy(getmetatable(o), seen))
    else
        no = o
    end
    return no
end

local function deepmerge(a, b)
    for k, v in next, b, nil do
        if a[k] == nil then
            a[deepcopy(k)] = deepcopy(v)
        else
            if type(v) == 'table' and type(a[k]) == 'table' then
                deepmerge(a[k], v)
            end
        end
    end
end

local function load(default, filepath)

    local file = io.open(filepath, 'r')

    if file then
        local contents = file:read('*a')
        file:close()

        if #contents == 0 then
            return deepcopy(default)
        end

        local result, loaded = pcall(decodeJson, contents)

        if not result or not loaded then
            if not result then
                print('jsoncfg: failed to decode json, error:', loaded)
            end
            return deepcopy(default)
        end

        deepmerge(loaded, default)
        return loaded
    else
        return deepcopy(default)
    end
end

function save(data, filepath)
    local file, errstr = io.open(filepath, 'w')

    if file then
        local result, encoded = pcall(encodeJson, data)

        if result then
            file:write(encoded)
        else
            print('jsoncfg: failed to encode json, error:', encoded)
        end

        file:close()

        return result
    else
        print('jsoncfg: failed to open file, error:', errstr)
        return false
    end
end

local settings = {}

local default_settings = {

	general = {
		name_surname = '',
		accent = '[Иностранный акцент]:',
		fraction = 'Не имеется',
		fraction_tag = 'Неизвестно',
		fraction_rank = 'Неизвестно',
		fraction_rank_number = 0,
		sex = 'Неизвестно',
		expel_reason = 'Н.П.Б.',
		anti_trivoga = true,
		heal_in_chat = true,
		auto_uval = false,
		accent_enable = false,
		rp_chat = true,
		version = '2.99'
	},
	
	price = {
		heal = 15000,
		heal_vc = 50,
		healbad = 300000,
		healactor = 300000,
		healactor_vc = 1000,
		medosm = 300000,
		ant = 25000,
		recept = 5000,
		tatu = 300000,
		med7 = 30000,
		med14 = 50000,
		med30 = 70000,
		med60 = 110000,
		mticket = 300000,
	},
	
	waiting = {
		my_wait = '1.500'
	},
	
	note = {
		my_note = ''
	},
	
	commands = {
	
		{ cmd = 'zd' , description = 'Привествие игрока' , text = 'Здраствуйте, я #my_ru_nick - #fraction_rank #fraction_tag.&Чем я могу вам помочь?', arg = '' , enable = true },
		
		{ cmd = 'go' , description = 'Позвать игрока за собой' , text = 'Хорошо #get_nick(#arg_id), следуйте за мной.', arg = '#arg_id' , enable = true },
		
		{ cmd = 'cure' , description = 'Поднять игрока из стадии' ,  text = '/todo Что-то ему вообще плохо*оглядывая человека без сознания&/cure #arg_id&/me наклоняется над человек, затем прощупывает пульс на сонной артерии.&/do Пульс отсутствует.&/me начинает делать человеку непрямой массаж сердца, время от времени проверяя пульс.&/do Спустя несколько минут сердце человека началось биться.&/do Человек пришел в сознание.&/todo Отлично*улыбаясь' , arg = '#arg_id' , enable = true },
		
		{ cmd = 'gd' , description = 'Экстренный вызов (/godeath)' ,  text = '/me достаёт из кармана свой телефон и заходит в базу данных #fraction_tag.&/me просматривает информацию и включает навигатор к выбранному месту экстренного вызова.&/godeath #arg_id' , arg = '#arg_id' , enable = true },
	
		{ cmd = 'hl' , description = 'Обычное лечение игроков' , text = '/me достаёт из своего мед.кейса нужное лекарство и передаёт его человеку напротив.&/todo Принимайте это лекарство, оно вам поможет*улыбаясь&/heal #arg_id #price_heal', arg = '#arg_id' , enable = true },
		
		{ cmd = 'hme' , description = 'Лечение самого себя' ,  text = '/me достаёт из своего мед.кейса лекарство и принимает его.&/heal #my_id #price_heal' , arg = '' , enable = true },
		
		{ cmd = 'hla' , description = 'Лечение охранника игрока' ,  text = '/me достаёт из своего мед.кейса лекарство и передаёт его человеку напротив.&/todo Давайте своему охраннику это лекарство, оно ему поможет*улыбаясь&/healactor #arg_id #price_actorheal' , arg = '#arg_id' , enable = true },
		
		{ cmd = 'hlb' , description = 'Лечение игрока от наркозависимости' ,  text = '/me достаёт из своего мед.кейса таблетки от наркозависимости и передаёт их пациенту напротив.&/todo Принимайте эти таблетки, и в скором времени Вы излечитесь от наркозависимости*улыбаясь&/healbad #arg_id' , arg = '#arg_id' , enable = true },
		
		{ cmd = 'medin' , description = 'Оформление мед.страховки игроку' ,  text = 'Для оформления мед.страховки Вам необходимо оплатить определнную cумму.&Стоимость зависит от срока действия будущей мед.страховки.&На 1 неделю - $4ОО.ООО. На 2 недели - $8ОО.ООО. На 3 недели - $1.2ОО.ООО.&/me достаёт из своего мед.кейса пустой бланк мед.страховки, ручку и печать #fraction_tag.&/me открывает бланк мед.страховки и начинает его заполнять, затем ставит печать #fraction_tag.&И так, скажите, на какой срок Вам оформить мед.страховку?&/me полностю заполнив бланк мед.страховки убирает ручку и печать обратно в свой мед.кейс.&/givemedinsurance #arg_id&/todo Вот ваша мед.страховка, берите*протягивая бланк с мед.страховкой человеку напротив себя' , arg = '#arg_id' , enable = true },
		
		{ cmd = 'expel' , description = 'Выгнать игрока из больницы' ,  text = 'Вы больше не можете здесь находиться, я выгоняю вас из больницы!&/me схватив человека ведёт к выходу из больницы и закрывает за ним дверь.&/expel #arg_id #expel_reason' , arg = '#arg_id' , enable = true },
		
		{ cmd = 'unstuff' , description = 'Удаление татуировки у игрока' ,  text = 'Хорошо, сейчас я удалю ваши татуировки.&/do Аппарат для выведения тату находится в правом кармане.&/me засовывает руку в карман и достаёт из него аппарат для выведения тату.&/do Аппарат в правой руке.&/me держа аппарат в руках осмотривает пациента&/me начинает аппаратом выводить татутировки с тела пациента.&/unstuff #arg_id #price_tatu&/me закончив процесс выведения татуировки выключает аппрарат и убирает его в карман.' , arg = '#arg_id' , enable = true },
		
		{ cmd = 'mt' , description = 'Мед.обследования для военного билета' ,  text = 'Хорошо, сейчас я проведу вам мед.обследование для получения военного билета&/me достаёт из мед.кейса стерильные перчатки и надевает их на руки.&/do Перчатки на руках.&/todo Начнём мед.обследование*улыбаясь.&/mticket #arg_id #price_mticket&/n get_nick, примите предложение в /offer для продолжения мед.обследования!' , arg = '#arg_id' , enable = true },

		{ cmd = 'pilot' , description = 'Мед.осмотр для пилотов' ,  text = 'Хорошо, сейчас я проведу вам мед.осмотр для пилотов.&/medcheck #arg_id #price_medosm&/n #get_nick(#arg_id), примите предложение в /offer для продолжения мед.осмотра!&/n Пока вы не примите предложение, мы не сможем начать!&/me достаёт из мед.кейса стерильные перчатки и надевает их на руки.&/do Перчатки на руках.&/todo Начнём мед.осмотр*улыбаясь.&Сейчас я проверю ваше горло, откройте рот и высуните язык.&/me достаёт из мед.кейса фонарик и включив его осматривает горло человека напротив.&Хорошо, можете закрывать рот, сейчас я проверю ваши глаза.&/me проверяет реакцию человека на свет, посветив фонарик в глаза.&/do Зрачки глаз обследуемого человека сузились.&/todo Отлично*выключая фонарик и убирая его в мед.кейс&Такс, сейчас я проверю ваше сердцебиение, поэтому приподнимите верхную одежду!&/me достаёт из мед.кейса стетоскоп и приложив его к груди человека проверяет сердцебиение.&/do Сердцебиение в районе 65 ударов в минуту.&/todo С сердцебиением у вас все в порядке*убирая стетоскоп обратно в мед.кейс&/me снимает со своих рук использованные перчатки и выбрасывает их.&Ну что-ж я могу вам сказать, со здоровьем у вас все в порядке, вы свободны!' , arg = '#arg_id' , enable = true },
	
	},

	commands_manage = {
	
		{ cmd = 'inv' , description = 'Принятие игрока в фракцию' , text = '/do В кармане халата есть связка с ключами от раздевалки.&/me достаёт из халата один ключ из связки ключей от раздевалки.&/todo Возьмите, это ключ от нашей раздевалки*передавая ключ человеку напротив&/invite #arg_id' , arg = '#arg_id', enable = true },
		
		{ cmd = 'uval' , description = 'Увольнение игрока из фракции' , text = '/me достаёт из кармана свой телефон и заходит в базу данных #fraction_tag.&/me изменяет информацию о сотруднике и убирает телефон обратно в карман.&/uninvite #arg_id #arg2&/r Сотрудник #get_ru_nick(#arg_id) был уволен по причине: #arg2' , arg = '#arg_id #arg2', enable = true },
		
		{ cmd = 'vig' , description = 'Выдача выговора игроку' , text = '/me достаёт из кармана свой телефон и заходит в базу данных #fraction_tag.&/me изменяет информацию о сотруднике и убирает телефон обратно в карман.&/fwarn #arg_id #arg2&/r Сотруднику #get_ru_nick(#arg_id) выдан выговор! Причина: #arg2' , arg = '#arg_id #arg2', enable = true },
		
		{ cmd = 'unvig' , description = 'Снятие выговора игроку' , text = '/me достаёт из кармана свой телефон и заходит в базу данных #fraction_tag.&/me изменяет информацию о сотруднике и убирает телефон обратно в карман.&/unfwarn #arg_id&/r Сотруднику #get_ru_nick(#arg_id) был снят выговор!' , arg = '#arg_id', enable = true },
		
		{ cmd = 'gr' , description = 'Повышение/понижение игрока' , text = '/me достаёт из кармана свой телефон и заходит в базу данных #fraction_tag.&/me изменяет информацию о сотруднике и убирает телефон обратно в карман.&/giverank #arg_id #arg2&/r Сотрудник #get_ru_nick(#arg_id) получил новую должность!' , arg = '#arg_id #arg2', enable = true},
	
	},

}

local workingDirectory = getWorkingDirectory()
local configDirectory = workingDirectory .. "/config"
local path = configDirectory .. "/HospitalHelperSettings.json"

if not doesDirectoryExist(configDirectory) then
    createDirectory(configDirectory)
end

if doesFileExist(path) then
    settings = load(settings, path)
else
    settings = default_settings
    save(settings, path)
end

local reset_settings_bool = false

if tostring(settings.general.version) ~= tostring(thisScript().version) then
	settings = default_settings 
	save(settings, path)
	reset_settings_bool = true
	thisScript():reload()
end	

--------------------------------------------------------------------------------------------------------------

if MONET_DPI_SCALE == nil then MONET_DPI_SCALE = 1.0 end
function isMonetLoader() return MONET_VERSION ~= nil end

--------------------------------------------------------------------------------------------------------------

local ffi = require 'ffi'
local fa = require('fAwesome6_solid')
local imgui = require('mimgui')
local new = imgui.new
local MainWindow, LeaderFastMenu, FastMenu, MedCardMenu, MedInsuranceMenu, FastHealMenu, ReceptMenu, AntibiotikMenu = new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool()
local MedOsmotrMenu1, MedOsmotrMenu2, MedOsmotrMenu3, MedOsmotrMenu4, MedOsmotrMenu5 = new.bool(), new.bool(), new.bool(), new.bool(), new.bool()
local BinderWindow = new.bool()
local MembersWindow = new.bool()
local ComboTags = new.int()
local item_list = {u8'Без аргумента', u8'#arg (принимает что угодно, буквы/цифры/символы)', u8'#arg_id (принимает только ID игрока)', u8'#arg_id #arg2 (принимает 2 аругмента: ID игрока и второе что угодно'}
local ImItems = imgui.new['const char*'][#item_list](item_list)
local medcard_days = new.int()
local recepts = new.int()
local insurance_week = new.int()
local medosmtype = new.int()
local antibiotiks = new.int(1)
local checkbox_accent_enable = new.bool(settings.general.accent_enable)
local input_accent = new.char[256](u8(settings.general.accent))
local input_name_surname = new.char[256](u8(settings.general.name_surname))
local input_expel_reason = new.char[256](u8(settings.general.expel_reason))
local input_fraction_tag = new.char[256](u8(settings.general.fraction_tag))
local input_heal = new.char[256](u8(settings.price.heal))
local input_heal_vc = new.char[256](u8(settings.price.heal_vc))
local input_healbad = new.char[256](u8(settings.price.healbad))
local input_healactor = new.char[256](u8(settings.price.healactor))
local input_healactor_vc = new.char[256](u8(settings.price.healactor_vc))
local input_medosm = new.char[256](u8(settings.price.medosm))
local input_mticket = new.char[256](u8(settings.price.mticket))
local input_recept = new.char[256](u8(settings.price.recept))
local input_ant = new.char[256](u8(settings.price.ant))
local input_tatu = new.char[256](u8(settings.price.tatu))
local input_med7 = new.char[256](u8(settings.price.med7))
local input_med14 = new.char[256](u8(settings.price.med14))
local input_med30 = new.char[256](u8(settings.price.med30))
local input_med60 = new.char[256](u8(settings.price.med60))
local input_text_note_temp = settings.note.my_note:gsub('&', '\n')
local input_text_note = new.char[8192](u8(input_text_note_temp))

local slider = new.float(tonumber(settings.waiting.my_wait))
local sizeX, sizeY = getScreenResolution()

local message_color = 0xFF7E7E
local message_color_hex = '{FF7E7E}'

local PlayerID = nil
local player_id = 0
local check_stats = false
local anti_flood_auto_uval = false

local medcheck = false
local medcheck_no_medcard = false
local medcard_narko = 0
local medcard_status = ''

local heal_in_chat = false
local heal_in_chat_player_id = nil

local spawncar_bool = false

local uninviteoff_reason = ''
local uninviteoff_reason_dialog = false

local givemedinsurance_dialog = false

local dialog_invite = false

local vc_vize_bool = false
local vc_vize_player_id = 0

local godeath_player_id = 0
local godeath_locate = ''
local godeath_city = ''

local members = {}
local members_new = {}
local members_check = false
local members_fraction = ''
local update_members_check = false

local change_cmd_bool = false
local change_cmd = ''
local change_description = ''
local change_text = ''
local change_arg = ''

local tagReplacements = {

	my_id = function() return select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)) end,
    my_nick = function() return sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) end,
	my_ru_nick = function() return settings.general.name_surname end,
	fraction = function() return settings.general.fraction end,
	fraction_tag = function() return settings.general.fraction_tag end,
	fraction_rank = function() return settings.general.fraction_rank end,
	fraction_rank_number = function() return settings.general.fraction_rank_number end,
	expel_reason = function() return settings.general.expel_reason end,
	price_heal = function()
		if u8(sampGetCurrentServerName()):find("Vice City") then
			return settings.price.heal_vc
		else
			return settings.price.heal
		end
	end,
	price_actorheal = function()
		if u8(sampGetCurrentServerName()):find("Vice City") then
			return settings.price.healactor_vc
		else
			return settings.price.healactor
		end
	end,
	price_medosm = function() return settings.price.medosm end,
	price_mticket = function() return settings.price.mticket end,
	price_ant = function() return settings.price.ant end,
	price_recept = function() return settings.price.recept end,
	price_tatu = function() return settings.price.tatu end,
	price_med7 = function() return settings.price.med7 end,
	price_med14 = function() return settings.price.med14 end,
	price_med30 = function() return settings.price.med30 end,
	price_med60 = function() return settings.price.med60 end,
	sex = function() 
		if settings.general.sex == 'Женщина' then
			local temp = 'а'
			return temp
		else
			local temp = ''
			return temp
		end
	end,
	
	
}

function main()

	if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(0) end 
	
	if not sampIsLocalPlayerSpawned() then 
		sampAddChatMessage('[Hospital Helper] {ffffff}Инициализация хелпера прошла успешно!',message_color)
		sampAddChatMessage('[Hospital Helper] {ffffff}Для полной загрузки хелпера сначало заспавнитесь (войдите на сервер)',message_color)
		repeat wait(0) until sampIsLocalPlayerSpawned()
	end
	
	sampAddChatMessage('[Hospital Helper] {ffffff}Загрузка хелпера прошла успешно!', message_color)
	sampAddChatMessage('[Hospital Helper] {ffffff}Чтоб открыть меню хелпера ' .. (isMonetLoader() and 'введите команду ' .. message_color_hex .. '/hh' or 'нажмите клавишу ' .. message_color_hex .. 'F2 {ffffff}или введите команду ' .. message_color_hex .. '/hh'), message_color)
	
	if settings.general.name_surname == '' then
		settings.general.name_surname = TranslateNick(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))))
		input_name_surname = new.char[256](u8(settings.general.name_surname))
		save(settings, path)
		check_stats = true
		sampSendChat('/stats')
	end

	sampRegisterChatCommand("hh", function() MainWindow[0] = not MainWindow[0]  end)
	sampRegisterChatCommand("hm", show_fast_menu)
	sampRegisterChatCommand("mb", function() members_new = {} members_check = true sampSendChat("/members")  end)
	
	sampRegisterChatCommand("osm",medosm)
	
	for _, command in ipairs(settings.commands) do
	
		if command.enable then
		
			sampRegisterChatCommand(command.cmd, function(arg)
				local arg_check = false
				local modifiedText = command.text
				
	
				if command.arg == '#arg' then
					if arg and arg ~= '' then
						modifiedText = modifiedText:gsub('#arg', arg or "")
						arg_check = true
					else
						sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [аргумент]', message_color)
						play_error_sound()
					end
				elseif command.arg == '#arg_id' then
					if arg and arg ~= '' and isParamID(arg) then
						arg = tonumber(arg)
						modifiedText = modifiedText:gsub('#get_nick%(#arg_id%)', sampGetPlayerNickname(arg) or "")
						modifiedText = modifiedText:gsub('#get_ru_nick%(#arg_id%)', TranslateNick(sampGetPlayerNickname(arg)) or "")
						modifiedText = modifiedText:gsub('#arg_id', arg or "")
						arg_check = true
					else
						sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока]', message_color)
						play_error_sound()
					end
				elseif command.arg == '#arg_id #arg2' then
					if arg and arg ~= '' then
						local arg_id, arg2 = arg:match('(%d+) (.+)')
						if arg_id and arg2 and isParamID(arg_id) then
							arg_id = tonumber(arg_id)
							modifiedText = modifiedText:gsub('#get_nick%(#arg_id%)', sampGetPlayerNickname(arg_id) or "")
							modifiedText = modifiedText:gsub('#get_ru_nick%(#arg_id%)', TranslateNick(sampGetPlayerNickname(arg_id)) or "")
							modifiedText = modifiedText:gsub('#arg_id', arg_id or "")
							modifiedText = modifiedText:gsub('#arg2', arg2 or "")
							arg_check = true
						else
							sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока] [аргумент]', message_color)
							play_error_sound()
						end
					else
						sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока] [аргумент]', message_color)
						play_error_sound()
					end
				elseif command.arg == '' then
					
					arg_check = true
				end

				if arg_check then
				
					lua_thread.create(function()
					
						local lines = {}

						for line in string.gmatch(modifiedText, "[^&]+") do
							table.insert(lines, line)
						end

						for _, line in ipairs(lines) do
						
							for tag, replacement in pairs(tagReplacements) do
								local success, result = pcall(string.gsub, line, "#" .. tag, replacement())
								if success then
									line = result
								else
									sampAddChatMessage('[Hospital Helper] {ffffff}Данный тэг не существует!', message_color)
								end
							end

							sampSendChat(line)
							
							wait(get_my_wait())
						end
						
					end)
				end
			end)
		end
	end

	sampRegisterChatCommand("inv",invite)
	sampRegisterChatCommand("uval",uninvite)
	sampRegisterChatCommand("vig",fwarn)
	sampRegisterChatCommand("unvig",unfwarn)
	sampRegisterChatCommand("gr",giverank)
	sampRegisterChatCommand("giverank",giverank)
    sampRegisterChatCommand("spawncar",spawncar)
	sampRegisterChatCommand("vc",vc_vize)
	
	sampRegisterChatCommand("rec",recept)
	sampRegisterChatCommand("recept",recept)
	sampRegisterChatCommand("ant",antibiotik)
	sampRegisterChatCommand("antibiotik",antibiotik)
	sampRegisterChatCommand("mc",medcard)
	sampRegisterChatCommand("medcard",medcard)

	while true do
		wait(0)
		
		if MembersWindow[0] and not update_members_check then
			update_members()
		end
		
		if not isMonetLoader() then
		
			if heal_in_chat and isKeyDown(VK_RETURN) and not sampIsDialogActive() and not sampIsChatInputActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then
			   command("/heal #arg_id",heal_in_chat_player_id)
				heal(heal_in_chat_player_id)
				heal_in_chat = false
				heal_in_chat_id = nil
			end
			
			if isKeyDown(VK_F2) and not MainWindow[0] then
				MainWindow[0] = true
			end
			
			if isKeyDown(VK_F3) then
				
				command("/heal #my_id", 0)
				wait(500)
			end
			
			local valid, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
			if valid and doesCharExist(ped) then
				local result, id = sampGetPlayerIdByCharHandle(ped)
				if result and id ~= -1 and isKeyJustPressed(VK_R) and isKeyJustPressed(VK_RBUTTON) and not LeaderFastMenu[0] then
					show_fast_menu(id)
				end
			end
		
		end
		
	end

end

function fast_heal_in_chat(id)

	id = tonumber(id)
	
	if sampIsPlayerConnected(id) then
		local _, ped = sampGetCharHandleBySampPlayerId(id)
		local nick = sampGetPlayerNickname(id)
		
		if _ then 
			local ppx, ppy, ppz = getCharCoordinates(PLAYER_PED)
			local localx, localy, localz = getCharCoordinates(ped)
			local x = tostring(localx):sub(1,9)
			local y = tostring(localy):sub(1,9)
			local z = tostring(localz):sub(1,4)
			if math.floor(getDistanceBetweenCoords3d(ppx, ppy, ppz, x, y, z)) > 4 and math.floor(getDistanceBetweenCoords3d(ppx, ppy, ppz, x, y, z)) <= 30 then
				sampAddChatMessage('[Hospital Helper] {ffffff}Игрок '..nick..' просит вылечить его, но вы слишком далеко от него!',message_color)
			elseif math.floor(getDistanceBetweenCoords3d(ppx, ppy, ppz, x, y, z)) <= 4 then
			
				if isMonetLoader() then
			
					sampAddChatMessage('[Hospital Helper] {ffffff}Чтоб вылечить игрока '..nick..', в течении 5-ти секунд нажмите кнопку',message_color)
					heal_in_chat_player_id = id
					lua_thread.create(function() 
						heal_in_chat = true
						FastHealMenu[0] = true
						wait(5000)
						FastHealMenu[0] = false
						heal_in_chat = false
					end)
			
				else
				
					sampAddChatMessage('[Hospital Helper] {ffffff}Чтоб вылечить игрока '..nick..', в течении 5-ти секунд нажмите клавишy {00ccff}Enter',message_color)
					heal_in_chat_player_id = id
					lua_thread.create(function() 
						heal_in_chat = true
						wait(5000)
						heal_in_chat = false
					end)
			
				end
			end
		end
	end

end

function command (cmd,id)

id = tonumber(id)

for _, command in ipairs(settings.commands) do
	
		if command.text:find(cmd) then
				
		   	local modifiedText = command.text
				
           	modifiedText = modifiedText:gsub('#get_nick%(#arg_id%)', sampGetPlayerNickname(id) or "")
		   	modifiedText = modifiedText:gsub('#get_ru_nick%(#arg_id%)', TranslateNick(sampGetPlayerNickname(id)) or "")
	   		modifiedText = modifiedText:gsub('#arg_id', id or "")
				
					lua_thread.create(function()
					
						local lines = {}

						for line in string.gmatch(modifiedText, "[^&]+") do
							table.insert(lines, line)
						end

						for _, line in ipairs(lines) do
						
							for tag, replacement in pairs(tagReplacements) do
								local success, result = pcall(string.gsub, line, "#" .. tag, replacement())
								if success then
									line = result
								else
									sampAddChatMessage('[Hospital Helper] {ffffff}Данный тэг не существует!', message_color)
								end
							end

							sampSendChat(line)
							
							wait(get_my_wait())
						end
						
					end)
		end
end
end

function medosm(id)
	if isParamID(id) then
		lua_thread.create(function()
			player_id = tonumber(id)
			sampSendChat("Сейчас я проведу Вам мед.осмотр, дайте мне вашу мед.карту для проверки.")
			medcheck = true
			MedOsmotrMenu2[0] = true
			wait(get_my_wait())
			sampSendChat("/n "..sampGetPlayerNickname(player_id)..", введите /showmc "..select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)).." чтоб показать мне мед.карту.")
		end)
	else
		sampAddChatMessage('[Hospital Helper] {ffffff}Используйте {00ccff}/osm [ID игрока]',message_color)
		play_error_sound()
	end
end
function medcard(id)
	if isParamID(id) then
		lua_thread.create(function()
			sampSendChat("Для оформления мед. карты Вам необходимо оплатить определенную сумму.")
			wait(get_my_wait())
			sampSendChat("Эта сумма зависит от строка действия будущей медкарты.")
			wait(get_my_wait())
			sampSendChat("Мед. карта на 7 дней - $"..settings.price.med7..", на 14 дней - $"..settings.price.med14..".")
			wait(get_my_wait())
			sampSendChat("Мед. карта на 30 дней - $"..settings.price.med30..", на 60 дней - $"..settings.price.med60..".")
			wait(get_my_wait())
			sampSendChat("Скажите, на какой срок Вам оформить мед. карту?")
			player_id = tonumber(id)
			MedCardMenu[0] = true
		end)
	else
		sampAddChatMessage('[Hospital Helper] {ffffff}Используйте {00ccff}/mc [ID] {ffffff}или {00ccff}/medcard [ID]',message_color)
		play_error_sound()
	end
end
function recept(id)
	if isParamID(id) then
		lua_thread.create(function()
			sampSendChat("Хорошо, стоимость одного рецепта составляет $"..settings.price.recept..".")
			wait(get_my_wait())
			sampSendChat("Скажите сколько Вам требуется рецептов, после чего мы продолжим.")
			wait(get_my_wait())
			sampSendChat("/n Внимание! В течении часа выдаётся максимум 5 рецептов!")
			player_id = tonumber(id)
			ReceptMenu[0] = true
		end)
	else
		sampAddChatMessage('[Hospital Helper] {ffffff}Используйте {00ccff}/rec [ID] {ffffff}или {00ccff}/recept [ID]',message_color)
		play_error_sound()
	end
end
function antibiotik(id)
	if isParamID(id) then
		lua_thread.create(function()
			sampSendChat("Хорошо, cтоимость одного антибиотика составляет $"..settings.price.ant..".")
			wait(get_my_wait())
			sampSendChat("Скажите сколько Вам требуется антибиотиков, после чего мы продолжим.")
			wait(get_my_wait())
			sampSendChat("/n Внимание! Вы можете купить от 1 до 20 антибитиков!")
			player_id = tonumber(id)
			AntibiotikMenu[0] = true
		end)
	else
		sampAddChatMessage('[Hospital Helper] {ffffff}Используйте {00ccff}/ant [ID] {ffffff}или {00ccff}/antibiotik [ID]',message_color)
		play_error_sound()
	end
end

function update_members()
	lua_thread.create(function()
		update_members_check = true
		wait(1500)
		if MembersWindow[0] then
			members_new = {} 
			members_check = true 
			sampSendChat("/members") 
		end
		wait(1500)
		update_members_check = false
	end)
end

function spawncar()
	if tonumber(settings.general.fraction_rank_number) == 9 or tonumber(settings.general.fraction_rank_number) == 10 then 
		lua_thread.create(function()
			sampSendChat("/rb Внимание! Через 10 секунд будет спавн транспорта больницы.")
			wait(2000)
			sampSendChat("/rb Займите транспорт, иначе он будет заспавнен.")
			wait(8000)	
			spawncar_bool = true
			sampSendChat("/lmenu")
		end)
	else
		sampAddChatMessage('[Hospital Helper] {ffffff}Эта команда доступна только лидеру и заместителям!',message_color)
		play_error_sound()
	end
end
function vc_vize(id)
	if tonumber(settings.general.fraction_rank_number) == 9 or tonumber(settings.general.fraction_rank_number) == 10 then 
		if isParamID(id) then
			lua_thread.create(function()
				sampSendChat("/me достаёт из кармана свой телефон и заходит в базу данных " .. settings.general.fraction_tag .. ".")
				wait(get_my_wait())
				sampSendChat("/me изменяет информацию о сотруднике и убирает телефон обратно в карман")
				wait(get_my_wait())
				vc_vize_player_id = tonumber(id)
				vc_vize_bool = true
				sampSendChat("/lmenu")
			end)
		elseif id:find('^(%w+_%w+)') then
			lua_thread.create(function()
				sampSendChat("/me достаёт из кармана свой телефон и заходит в базу данных " .. settings.general.fraction_tag .. ".")
				wait(get_my_wait())
				sampSendChat("/me изменяет информацию о сотруднике и убирает телефон обратно в карман")
				wait(get_my_wait())
				if sampIsConnectedByNick(id) then
					vc_vize_player_id = tonumber(sampGetIDByNick(id))
					vc_vize_bool = true
					sampSendChat("/lmenu")
				else
					sampAddChatMessage('[Hospital Helper] {ffffff}Игрока с таким ником сейчас нет на сервере!',message_color)
				end
			end)
		else
			sampAddChatMessage('[Hospital Helper] {ffffff}Используйте {00ccff}/vc [ID] {ffffff}или {00ccff}/vc [Nick_Name]',message_color)
			play_error_sound()
		end

	else
		sampAddChatMessage('[Hospital Helper] {ffffff}Эта команда доступна только лидеру и заместителям!',message_color)
		play_error_sound()
	end
end

require("samp.events").onServerMessage = function(color,text)
	
	--sampAddChatMessage('color = ' .. color .. ' , text = '..text,-1)
	
	if color == 766526463 and settings.general.auto_uval and not anti_flood_auto_uval and tonumber(settings.general.fraction_rank_number) == 9 or tonumber(settings.general.fraction_rank_number) == 10 then -- autouval

		if text:find("%[(.-)%] (.-) (.-)%[(.-)%]: (.+)") then -- /f /fb или /r /rb без тэга 
		
			lua_thread.create(function()
			
				local tag, rank, name, playerID, message = string.match(text, "%[(.-)%] (.+) (.-)%[(.-)%]: (.+)")
				
				if not message:find("], чтобы уволится ПСЖ,") and not message:find("], отправьте (.+) +++ чтобы уволится ПСЖ!") and not message:find("Сотрудник (.+) был уволен по причине (.+)") and message:find("ПСЖ") or message:find("псж") or message:find("увольте") or message:find("Увольте") or message:find("Увал") or message:find("увал") then
					
					PlayerID = playerID
					
					anti_flood_auto_uval = true
					wait(10)
					
					if tag == "R" then
						sampSendChat("/rb "..name.."["..playerID.."], отправьте /rb +++ чтобы уволится ПСЖ!")
					elseif tag == "F" then
						sampSendChat("/fb "..name.."["..playerID.."], отправьте /fb +++ чтобы уволится ПСЖ!")
					end
					
					wait(5000)
					anti_flood_auto_uval = false
				
					
				end
				
				if message == "(( +++ ))" and PlayerID == playerID then
					wait(10)
					uninvite(PlayerID.." ПСЖ")
				end
				
			end)
	
		elseif text:find("%[(.-)%] %[(.-)%] (.+) (.-)%[(.-)%]: (.+)") then -- /r или /f с тэгом
		
			lua_thread.create(function()

				local tag, tag2, rank, name, playerID, message = string.match(text, "%[(.-)%] %[(.-)%] (.+) (.-)%[(.-)%]: (.+)")
				
				if not message:find("], чтобы уволится ПСЖ,") and not message:find("], отправьте (.+) +++ чтобы уволится ПСЖ!") and not message:find("Сотрудник (.+) был уволен по причине (.+)") and message:find("ПСЖ") or message:find("псж") or message:find("увольте") or message:find("Увольте") or message:find("Увал") or message:find("увал") then
					
					PlayerID = playerID
					
					anti_flood_auto_uval = true
					wait(10)
					
					if tag == "R" then
						sampSendChat("/rb "..name.."["..playerID.."], отправьте /rb +++ чтобы уволится ПСЖ!")
					elseif tag == "F" then
						sampSendChat("/fb "..name.."["..playerID.."], отправьте /fb +++ чтобы уволится ПСЖ!")
					end
					
					wait(5000)
					anti_flood_auto_uval = false
					
				end 
				
				if message == "(( +++ ))" and PlayerID == playerID then
					wait(10)
					uninvite(PlayerID.." ПСЖ")
				end
					
			end)
		end
		
	end
	
	if text:find("{ffffff} Вам поступило предложение от игрока (.+)") and medcheck then
		lua_thread.create(function()
			wait(10)
			sampSendChat("/offer")
		end)
	end
	
	if color == -1 and text:find('говорит') and settings.general.heal_in_chat then
		local nick, id, message = text:match('(.+)%[(%d+)%] говорит:{B7AFAF} (.+)')
		if nick and id and message then
			if message:find('вылеч') or message:find('хил') or message:find('лек') or message:find('lek') or message:find('hil') then
				lua_thread.create(function()
					wait(10)
					fast_heal_in_chat(tonumber(id))
				end)
			end
		end
	end
	
	if color == -253326081 and text:find('кричит') and settings.general.heal_in_chat then
		local nick, id, message = text:match('(.+)%[(%d+)%] кричит: (.+)')
		if nick and id and message then
			if message:find('вылеч') or message:find('хил') or message:find('лек') or message:find('lek') or message:find('hil') then
				lua_thread.create(function()
					wait(10)
					fast_heal_in_chat(tonumber(id))
				end)
			end
		end
	end
	
	if text:find('Очевидец сообщает о пострадавшем человеке в районе (.+) %((.+)%).') then
		godeath_locate, godeath_city = text:match('Очевидец сообщает о пострадавшем человеке в районе (.+) %((.+)%).')
		return false
	end
	
	if text:find('%(%( Чтобы принять вызов, введите /godeath (%d+). Оплата за вызов (.+) %)%)') then
		godeath_player_id = text:match('%(%( Чтобы принять вызов, введите /godeath (%d+). Оплата за вызов (.+) %)%)')
		godeath_player_id = tonumber(godeath_player_id)
		sampAddChatMessage('[Hospital Helper] {ffffff}Из города {00ccff}' .. godeath_city .. ' {ffffff}поступил экстренный вызов о пострадавшем человеке {00ccff}' .. sampGetPlayerNickname(godeath_player_id), 0xff7e7e)
		sampAddChatMessage('[Hospital Helper] {ffffff}Чтобы принять экстренный вызов, используйте {00ccff}/gd '.. godeath_player_id .. '{ffffff} или {00ccff}/godeath '.. godeath_player_id, message_color)
		return false
	end
	
	if text:find("{FFFFFF}(.-) принял ваше предложение вступить к вам в организацию.") then
		local PlayerName = text:match("{FFFFFF}(.-) принял ваше предложение вступить к вам в организацию.")
		sampSendChat("/r "..TranslateNick(PlayerName).." - наш новый сотрудник!")
	end
	
end
require("samp.events").onSendChat = function(text)
	
	local ignore = {
		[")"] = true,
		["))"] = true,
		["("] = true,
		["(("] = true,
		["xD"] = true,
		["q"] = true,
		["(+)"] = true,
		["(-)"] = true,
		[":)"] = true,
		[":("] = true,
		["=)"] = true,
		[":p"] = true,
		[";p"] = true,
		["(rofl)"] = true,
		["XD"] = true,
		["(agr)"] = true,
		["O.o"] = true,
		[">.<"] = true,
		[">:("] = true,
		["<3"] = true,
	}
	if ignore[text] then
		return {text}
	end
	
	if settings.general.rp_chat then
		text = text:sub(1, 1):rupper()..text:sub(2, #text) 
		if not text:find('(.+)%.') and not text:find('(.+)%!') and not text:find('(.+)%?') then
			text = text .. '.'
		end
	end
	
	if settings.general.accent_enable then
		text = settings.general.accent .. ' ' .. text 
	end
	
	return {text}

end
require("samp.events").onShowDialog = function(dialogid, style, title, button1, button2, text)
	
	--sampAddChatMessage(dialogid,-1)

	if dialogid == 25685 and medcheck then -- medosm
		sampSendDialogResponse(25685, 1,0,0)
		return false
	end
	
	if dialogid == 25686 and medcheck then -- medosm
		sampSendDialogResponse(25686, 1,5,0)
		return false
	end
	
	if dialogid == 1234 and not text:find("Законопослушность") and medcheck then -- medcard
		
		medcard_narko = math.floor(text:match("{CEAD2A}Наркозависимость: (.+){FFFFFF}"))
		medcard_status = text:match("Мед. Карта %[(.+)%]\n")
		
		MedOsmotrMenu2[0] = false
		MedOsmotrMenu3[0] = true
		
		sampSendChat("/me берёт в руки мед.карту и начинает осматриват её, после отдает мед.карту обратно")
		
		sampSendDialogResponse(1234, 1,0,0)
		return false
		
	end

	if dialogid == 131 then -- /hme
		if text:find(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))) then
			sampSendDialogResponse(131, 1,0,0)
			return false
		end
	end
	
	if dialogid == 15380 then -- выдача мед.карты
		if text:find("Полностью здоров") then
			sampAddChatMessage('[Hospital Helper] {ffffff}Ожидайте пока игрок подтвердит получение мед. карты',message_color)
			sampSendDialogResponse(15380, 1,0,0)
			return false
		end
	end
	
	if dialogid == 25449 and settings.general.anti_trivoga then -- тревожная кнопка
		sampSendDialogResponse(25449, 0, 0, 0)
		return false
	end
	
	if dialogid == 235 and check_stats then -- получение статистики
	
		if text:find("{FFFFFF}Пол: {B83434}%[(.-)]") then
			settings.general.sex = text:match("{FFFFFF}Пол: {B83434}%[(.-)]")
		end
		
		if text:find("{FFFFFF}Организация: {B83434}%[(.-)]") then
			settings.general.fraction = text:match("{FFFFFF}Организация: {B83434}%[(.-)]")
			if settings.general.fraction == 'Не имеется' then
				sampAddChatMessage('[Hospital Helper] {ffffff}Вы не состоите в организации!',message_color)
				settings.general.fraction_tag = "Неизвестно"
			else
				sampAddChatMessage('[Hospital Helper] {ffffff}Ваша организация обнаружена, это: '..settings.general.fraction, message_color)
				
				if settings.general.fraction == 'Больница ЛС' or settings.general.fraction == 'Больница LS' then
					settings.general.fraction_tag = 'LSMC'
				elseif settings.general.fraction == 'Больница ЛВ' or settings.general.fraction == 'Больница LV' then
					settings.general.fraction_tag = 'LVMC'
				elseif settings.general.fraction == 'Больница СФ' or settings.general.fraction == 'Больница SF' then
					settings.general.fraction_tag = 'SFMC'
				elseif settings.general.fraction == 'Больница Jefferson' or settings.general.fraction == 'Больница Джефферсон' then
					settings.general.fraction_tag = 'JMC'
				else
					settings.general.fraction_tag = 'Medical Center'
				end
				
				input_fraction_tag = new.char[256](u8(settings.general.fraction_tag))
				
				sampAddChatMessage('[Hospital Helper] {ffffff}Вашей организации присвоен тэг '..settings.general.fraction_tag .. ". Но вы можете изменить тэг в настройках", message_color)
				
			end
	
		end
		
		if text:find("{FFFFFF}Должность: {B83434}(.+)%((%d+)%)") then
			settings.general.fraction_rank, settings.general.fraction_rank_number = text:match("{FFFFFF}Должность: {B83434}(.+)%((%d+)%)(.+)Уровень розыска")
			sampAddChatMessage('[Hospital Helper] {ffffff}Ваша должность обнаружена, это: '..settings.general.fraction_rank.." ("..settings.general.fraction_rank_number..")", message_color)
		else
			settings.general.fraction_rank = "Неизвестно"
			settings.general.fraction_rank_number = 0
			sampAddChatMessage('[Hospital Helper] {ffffff}Произошла ошибка, не могу получить ваш ранг!',message_color)
		end
		
		save(settings, path)
		sampSendDialogResponse(235, 0,0,0)
		check_stats = false
		return false
	end

	if dialogid == 1214 and spawncar_bool then -- спавн т/с
	
		sampSendDialogResponse(1214, 2, 3, 0)
		spawncar_bool = false
		return false 
		
	end
	
	if dialogid == 1214 and vc_vize_bool then -- VS Visa [0]
		sampSendDialogResponse(1214, 1, 8, 0)
		return false 
	end
	
	if dialogid == 25744 and vc_vize_bool then -- VS Visa [1]
		lua_thread.create(function()
			vc_vize_bool = false
			sampSendDialogResponse(25744, 1, 0, tostring(vc_vize_player_id))
			wait(get_my_wait())
			sampSendChat("/r Сотруднику "..TranslateNick(sampGetPlayerNickname(tonumber(vc_vize_player_id))).." выдана виза для Vice City!")
		end)
		return false 
	end
	
	if dialogid == 25820 and vc_vize_bool then -- VS Visa [2]
		lua_thread.create(function()
			vc_vize_bool = false
			sampSendDialogResponse(25820, 1, 0, tostring(sampGetPlayerNickname(vc_vize_player_id)))
			wait(get_my_wait())
			sampSendChat("/r У сотрудника "..TranslateNick(sampGetPlayerNickname(tonumber(vc_vize_player_id))).." изьята виза для Vice City!")
		end)
		return false 
	end

	if dialogid == 26608 then --  arz fast menu
		sampSendDialogResponse(26608 , 0, 2, 0)
		return false 
	end

	--[[if dialogid == 15086 and uninviteoff_reason_dialog then -- увал в офлайне по нику
		sampSendDialogResponse(15086, 1, 0, uninviteoff_reason)
		uninviteoff_reason = ''
		uninviteoff_reason_dialog = false
		return false
	end]]

	if dialogid == 2015 and members_check then -- мемберс 

        local count = 0
        local next_page = false
        local next_page_i = 0
		
		members_fraction = string.match(title, '(.+)%(В сети')
		members_fraction = string.gsub(members_fraction, '{(.+)}', '')
		

        for line in text:gmatch('[^\r\n]+') do

            count = count + 1

            if not line:find('Ник') and not line:find('страница') then

				local color, nickname, id, rank, rank_number, warns, afk = string.match(line, '{(.+)}(.+)%((%d+)%)\t(.+)%((%d+)%)\t(%d+) %((%d+)')
			
				if color ~= nil and nickname ~= nil and id ~= nil and rank ~= nil and rank_number ~= nil and warns ~= nil and afk ~= nil then
				
					local working = false

					if color:find('FF3B3B') then
						working = false
					elseif color:find('FFFFFF') then
						working = true
					end
				
					table.insert(members_new, { nick = nickname, id = id, rank = rank, rank_number = rank_number, warns = warns, afk = afk, working = working })
				
				end

            end

            if line:match('Следующая страница') then
                next_page = true
                next_page_i = count - 2
            end
        end
		
        if next_page then
            sampSendDialogResponse(dialogid, 1, next_page_i, 0)
            next_page = false
            next_pagei = 0
        else
            sampSendDialogResponse(dialogid, 0, 0, 0)
			
			members = members_new
			
			members_check = false
		  
			MembersWindow[0] = true
		  
        end

        return false

    end

end
require("samp.events").onCreate3DText = function(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
   if text and text:find('Тревожная кнопка') and settings.general.anti_trivoga then -- удаление тревожной кнопки
		return false
	end
end

local russian_characters = {
    [168] = 'Ё', [184] = 'ё', [192] = 'А', [193] = 'Б', [194] = 'В', [195] = 'Г', [196] = 'Д', [197] = 'Е', [198] = 'Ж', [199] = 'З', [200] = 'И', [201] = 'Й', [202] = 'К', [203] = 'Л', [204] = 'М', [205] = 'Н', [206] = 'О', [207] = 'П', [208] = 'Р', [209] = 'С', [210] = 'Т', [211] = 'У', [212] = 'Ф', [213] = 'Х', [214] = 'Ц', [215] = 'Ч', [216] = 'Ш', [217] = 'Щ', [218] = 'Ъ', [219] = 'Ы', [220] = 'Ь', [221] = 'Э', [222] = 'Ю', [223] = 'Я', [224] = 'а', [225] = 'б', [226] = 'в', [227] = 'г', [228] = 'д', [229] = 'е', [230] = 'ж', [231] = 'з', [232] = 'и', [233] = 'й', [234] = 'к', [235] = 'л', [236] = 'м', [237] = 'н', [238] = 'о', [239] = 'п', [240] = 'р', [241] = 'с', [242] = 'т', [243] = 'у', [244] = 'ф', [245] = 'х', [246] = 'ц', [247] = 'ч', [248] = 'ш', [249] = 'щ', [250] = 'ъ', [251] = 'ы', [252] = 'ь', [253] = 'э', [254] = 'ю', [255] = 'я',
}
function string.rlower(s)
    s = s:lower()
    local strlen = s:len()
    if strlen == 0 then return s end
    s = s:lower()
    local output = ''
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 192 and ch <= 223 then -- upper russian characters
            output = output .. russian_characters[ch + 32]
        elseif ch == 168 then -- Ё
            output = output .. russian_characters[184]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end
function string.rupper(s)
    s = s:upper()
    local strlen = s:len()
    if strlen == 0 then return s end
    s = s:upper()
    local output = ''
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 224 and ch <= 255 then -- lower russian characters
            output = output .. russian_characters[ch - 32]
        elseif ch == 184 then -- ё
            output = output .. russian_characters[168]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end
function TranslateNick(name)
	if name:match('%a+') then
        for k, v in pairs({['ph'] = 'ф',['Ph'] = 'Ф',['Ch'] = 'Ч',['ch'] = 'ч',['Th'] = 'Т',['th'] = 'т',['Sh'] = 'Ш',['sh'] = 'ш', ['ea'] = 'и',['Ae'] = 'Э',['ae'] = 'э',['size'] = 'сайз',['Jj'] = 'Джейджей',['Whi'] = 'Вай',['lack'] = 'лэк',['whi'] = 'вай',['Ck'] = 'К',['ck'] = 'к',['Kh'] = 'Х',['kh'] = 'х',['hn'] = 'н',['Hen'] = 'Ген',['Zh'] = 'Ж',['zh'] = 'ж',['Yu'] = 'Ю',['yu'] = 'ю',['Yo'] = 'Ё',['yo'] = 'ё',['Cz'] = 'Ц',['cz'] = 'ц', ['ia'] = 'я', ['ea'] = 'и',['Ya'] = 'Я', ['ya'] = 'я', ['ove'] = 'ав',['ay'] = 'эй', ['rise'] = 'райз',['oo'] = 'у', ['Oo'] = 'У', ['Ee'] = 'И', ['ee'] = 'и', ['Un'] = 'Ан', ['un'] = 'ан', ['Ci'] = 'Ци', ['ci'] = 'ци', ['yse'] = 'уз', ['cate'] = 'кейт', ['eow'] = 'яу', ['rown'] = 'раун', ['yev'] = 'уев', ['Babe'] = 'Бэйби', ['Jason'] = 'Джейсон', ['liy'] = 'лий', ['ane'] = 'ейн', ['ame'] = 'ейм'}) do
            name = name:gsub(k, v) 
        end
		for k, v in pairs({['B'] = 'Б',['Z'] = 'З',['T'] = 'Т',['Y'] = 'Й',['P'] = 'П',['J'] = 'Дж',['X'] = 'Кс',['G'] = 'Г',['V'] = 'В',['H'] = 'Х',['N'] = 'Н',['E'] = 'Е',['I'] = 'И',['D'] = 'Д',['O'] = 'О',['K'] = 'К',['F'] = 'Ф',['y`'] = 'ы',['e`'] = 'э',['A'] = 'А',['C'] = 'К',['L'] = 'Л',['M'] = 'М',['W'] = 'В',['Q'] = 'К',['U'] = 'А',['R'] = 'Р',['S'] = 'С',['zm'] = 'зьм',['h'] = 'х',['q'] = 'к',['y'] = 'и',['a'] = 'а',['w'] = 'в',['b'] = 'б',['v'] = 'в',['g'] = 'г',['d'] = 'д',['e'] = 'е',['z'] = 'з',['i'] = 'и',['j'] = 'ж',['k'] = 'к',['l'] = 'л',['m'] = 'м',['n'] = 'н',['o'] = 'о',['p'] = 'п',['r'] = 'р',['s'] = 'с',['t'] = 'т',['u'] = 'у',['f'] = 'ф',['x'] = 'x',['c'] = 'к',['``'] = 'ъ',['`'] = 'ь',['_'] = ' '}) do
            name = name:gsub(k, v) 
        end
        return name
    end
	return name
end
function isParamID(id)
	
	if id ~= nil and tostring(id):find('%d') and not tostring(id):find('%D') and string.len(id) >= 1 and string.len(id) <= 3 then
		return true
	else
		return false
	end

end
function get_my_wait()
	return settings.waiting.my_wait*1000
end
function play_error_sound()
	if not isMonetLoader() then
		if sampIsLocalPlayerSpawned() then
			addOneOffSound(getCharCoordinates(PLAYER_PED),1149)
		end
	end
end
function show_fast_menu(id)
	
	if isParamID(id) then 
		player_id = tonumber(id)
		FastMenu[0] = true
	else 
		if isMonetLoader() then 
			sampAddChatMessage('[Hospital Helper] {ffffff}Используйте {00ccff}/hm [ID]',message_color)
		else
			sampAddChatMessage('[Hospital Helper] {ffffff}Используйте {00ccff}/hm [ID] {ffffff}или наведитесь на игрока через {00ccff}ПКМ + R',message_color) 
		end 
	end 
	
end

function sampIsConnectedByNick(nick_arg)
	local result = false
	for i = 0, sampGetMaxPlayerId() do
		if sampIsPlayerConnected(tonumber(i)) then
			local rnick = sampGetPlayerNickname(tonumber(i))
			if rnick == nick_arg then
				result = true
			end
		end
	end
	return result
end
function sampGetIDByNick(nick_arg)
	for i = 0, sampGetMaxPlayerId() do
		if sampIsPlayerConnected(tonumber(i)) then
			local rnick = sampGetPlayerNickname(tonumber(i))
			if rnick == nick_arg then
				return tonumber(i)
			end
		end
	end
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	fa.Init(14 * MONET_DPI_SCALE)
	dark_theme()
end)

local MainWindow = imgui.OnFrame(
    function() return MainWindow[0] end,
    function(player)
	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(600 * MONET_DPI_SCALE, 425	* MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		imgui.Begin(fa.HOSPITAL.." Hospital Helper##main", MainWindow, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize )
		
		if imgui.BeginTabBar('Tabs') then
		
			if imgui.BeginTabItem(fa.HOUSE..u8' Главное меню') then
			
				
				if imgui.BeginChild('##1', imgui.ImVec2(589 * MONET_DPI_SCALE, 172 * MONET_DPI_SCALE), true) then
				
					imgui.CenterText(fa.USER_DOCTOR .. u8' Информация про сотрудника')
					imgui.Separator()
					imgui.Columns(3)
					imgui.CenterColumnText(u8"Имя и Фамилия:")
					imgui.SetColumnWidth(-1, 230 * MONET_DPI_SCALE)
					imgui.NextColumn()
					imgui.CenterColumnText(u8(settings.general.name_surname))
					imgui.SetColumnWidth(-1, 250 * MONET_DPI_SCALE)
					imgui.NextColumn()
					if imgui.CenterColumnSmallButton(u8'Изменить##name_surname') then
						settings.general.name_surname = TranslateNick(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))))
						input_name_surname = new.char[256](u8(settings.general.name_surname))
						save(settings, path)
						imgui.OpenPopup(fa.USER_DOCTOR .. u8' Имя и Фамилия##name_surname')
					end
					if imgui.BeginPopupModal(fa.USER_DOCTOR .. u8' Имя и Фамилия##name_surname', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
						imgui.PushItemWidth(200 * MONET_DPI_SCALE)
						imgui.InputText(u8'##name_surname', input_name_surname, 256) 
						if imgui.Button(u8'Сохранить', imgui.ImVec2(200 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then -- обязательно создавайте такую кнопку, чтобы была возможность закрыть окно
							settings.general.name_surname = u8:decode(ffi.string(input_name_surname))
							save(settings, path)
							imgui.CloseCurrentPopup()
						end
						imgui.End()
					end
					
					imgui.SetColumnWidth(-1, 100 * MONET_DPI_SCALE)
					
					imgui.Columns(1)
					
					imgui.Separator()
					
					imgui.Columns(3)
					imgui.CenterColumnText(u8"Пол:")
					imgui.NextColumn()
					imgui.CenterColumnText(u8(settings.general.sex))
					imgui.NextColumn()
					if imgui.CenterColumnSmallButton(u8'Изменить##sex') then
					
						
					
						if settings.general.sex == 'Неизвестно' then
							check_stats = true
							sampSendChat('/stats')
						elseif settings.general.sex == 'Мужчина' then
							settings.general.sex = 'Женщина'
							save(settings, path)
						elseif settings.general.sex == 'Женщина' then
							settings.general.sex = 'Мужчина'
							save(settings, path)
						end
						
						sampAddChatMessage(settings.general.sex,-1)
						
					end
					imgui.Columns(1)
					
					imgui.Separator()
					
					imgui.Columns(3)
					imgui.CenterColumnText(u8"Акцент:")
					imgui.NextColumn()
					if checkbox_accent_enable[0] then
						imgui.CenterColumnText(u8(settings.general.accent))
					else 
						imgui.CenterColumnText(u8'Отключено')
					end
					imgui.NextColumn()
					if imgui.CenterColumnSmallButton(u8'Изменить##accent') then
						imgui.OpenPopup(fa.USER_DOCTOR .. u8' Акцент персонажа##accent')
					end
					if imgui.BeginPopupModal(fa.USER_DOCTOR .. u8' Акцент персонажа##accent', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
						
						if imgui.Checkbox('##checkbox_accent_enable', checkbox_accent_enable) then
							settings.general.accent_enable = checkbox_accent_enable[0]
							save(settings, path)
						end
						
						imgui.SameLine()
						
						imgui.PushItemWidth(170 * MONET_DPI_SCALE)
						imgui.InputText(u8'##accent_input', input_accent, 256) 
						
						imgui.Separator()
						if imgui.Button(u8'Сохранить', imgui.ImVec2(200 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then -- обязательно создавайте такую кнопку, чтобы была возможность закрыть окно
							settings.general.accent = u8:decode(ffi.string(input_accent))
							save(settings, path)
							imgui.CloseCurrentPopup()
						end
						imgui.End()
					end
					imgui.Columns(1)
					
					imgui.Separator()
					

					
					imgui.Columns(3)
					imgui.CenterColumnText(u8"Организация:")
					imgui.NextColumn()
					imgui.CenterColumnText(u8(settings.general.fraction))
					imgui.NextColumn()
					
					if imgui.CenterColumnSmallButton(u8'Изменить##fraction') then
						check_stats = true
						sampSendChat('/stats')
					end
					
					imgui.Columns(1)
					
					imgui.Separator()
					
					imgui.Columns(3)
					imgui.CenterColumnText(u8"Тэг организации:")
					imgui.NextColumn()
					imgui.CenterColumnText(u8(settings.general.fraction_tag))
					imgui.NextColumn()
					if imgui.CenterColumnSmallButton(u8'Изменить##fraction_tag') then
						imgui.OpenPopup(fa.USER_DOCTOR .. u8' Тэг организации##fraction_tag')
					end
					if imgui.BeginPopupModal(fa.USER_DOCTOR .. u8' Тэг организации##fraction_tag', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
						imgui.PushItemWidth(200 * MONET_DPI_SCALE)
						imgui.InputText(u8'##input_fraction_tag', input_fraction_tag, 256)
						imgui.Separator()
						if imgui.Button(u8'Сохранить', imgui.ImVec2(200 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then
							settings.general.fraction_tag = u8:decode(ffi.string(input_fraction_tag))
							save(settings, path)
							imgui.CloseCurrentPopup()
						end
						imgui.End()
					end
					imgui.Columns(1)
					
					imgui.Separator()
					
					imgui.Columns(3)
					imgui.CenterColumnText(u8"Должность в организации:")
					imgui.NextColumn()
					imgui.CenterColumnText(u8(settings.general.fraction_rank) .. " (" .. settings.general.fraction_rank_number .. ")")
					imgui.NextColumn()
					if imgui.CenterColumnSmallButton(u8"Изменить##rank") then
						check_stats = true
						sampSendChat('/stats')
					end
					imgui.Columns(1)
				
				imgui.EndChild()
				end
				
				if imgui.BeginChild('##2', imgui.ImVec2(589 * MONET_DPI_SCALE, 55 * MONET_DPI_SCALE), true) then
				
					imgui.CenterText(fa.CIRCLE_INFO .. u8' Дополнительная информация')
					imgui.Separator()
				
					imgui.Columns(3)
					imgui.CenterColumnText(u8"Причина выгона для /expel:")
					imgui.SetColumnWidth(-1, 230 * MONET_DPI_SCALE)
					imgui.NextColumn()
					imgui.CenterColumnText(u8(settings.general.expel_reason))
					imgui.SetColumnWidth(-1, 250 * MONET_DPI_SCALE)
					imgui.NextColumn()
					if imgui.CenterColumnSmallButton(u8'Изменить##expel_reason') then
						imgui.OpenPopup(fa.DOOR_OPEN .. u8' Изменить причину для выгона##expel_reason')
					end
					if imgui.BeginPopupModal(fa.DOOR_OPEN .. u8' Изменить причину для выгона##expel_reason', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
						imgui.PushItemWidth(200 * MONET_DPI_SCALE)
						imgui.InputText(u8'##expel_reason', input_expel_reason, 256) 
						if imgui.Button(u8'Сохранить', imgui.ImVec2(200 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then
							settings.general.expel_reason = u8:decode(ffi.string(input_expel_reason))
							save(settings, path)
							imgui.CloseCurrentPopup()
						end
						imgui.End()
					end
					imgui.SetColumnWidth(-1, 100 * MONET_DPI_SCALE)
					
					imgui.Columns(1)
					
					imgui.Separator()
					
					
					
					
				
				
				imgui.EndChild()
				end
				
				if imgui.BeginChild('##3', imgui.ImVec2(589 * MONET_DPI_SCALE, 125 * MONET_DPI_SCALE), true) then
				
					imgui.CenterText(fa.SITEMAP .. u8' Дополнительные функции')
					imgui.Separator()
					

					imgui.Columns(3)
					imgui.CenterColumnText(u8"Анти Тревожная Кнопка")
					imgui.SameLine(nil, 5) imgui.TextDisabled("[?]")
					if imgui.IsItemHovered() then
						imgui.SetTooltip(u8"Убирает тревожную кнопку которая находится за стойкой на 1 этаже\nТем самым вы не будете случайно вызывать МЮ из-за этой кнопки")
					end
					imgui.SetColumnWidth(-1, 230 * MONET_DPI_SCALE)
					imgui.NextColumn()
					if settings.general.anti_trivoga then
						imgui.CenterColumnText(u8'Включено')
					else
						imgui.CenterColumnText(u8'Отключено')
					end
					imgui.SetColumnWidth(-1, 250 * MONET_DPI_SCALE)
					imgui.NextColumn()
					if imgui.CenterColumnSmallButton(u8'Изменить##anti_trivoga') then
						settings.general.anti_trivoga = not settings.general.anti_trivoga
						save(settings, path)
					end
					imgui.SetColumnWidth(-1, 100 * MONET_DPI_SCALE)
					
					imgui.Columns(1)
					
					imgui.Separator()
					
					imgui.Columns(3)
					imgui.CenterColumnText(u8"Хил из чата")
					imgui.SameLine(nil, 5) imgui.TextDisabled("[?]")
					if imgui.IsItemHovered() then
						imgui.SetTooltip(u8"Позволяет нажатием одной кнопки быстро лечить пациентов которые просят чтоб их вылечили")
					end
					imgui.NextColumn()
					if settings.general.heal_in_chat then
						imgui.CenterColumnText(u8'Включено')
					else
						imgui.CenterColumnText(u8'Отключено')
					end
					imgui.NextColumn()
					if imgui.CenterColumnSmallButton(u8'Изменить##healinchat') then
						settings.general.heal_in_chat = not settings.general.heal_in_chat
						save(settings, path)
					end
					
					imgui.Columns(1)
					
					imgui.Separator()
					
					imgui.Columns(3)
					imgui.CenterColumnText(u8"RP Общение")
					imgui.SameLine(nil, 5) imgui.TextDisabled("[?]")
					if imgui.IsItemHovered() then
						imgui.SetTooltip(u8"Все ваши сообщения в чат автоматически будут с заглавной буквы и с точкой в конце")
					end
					imgui.NextColumn()
					if settings.general.rp_chat then
						imgui.CenterColumnText(u8'Включено')
					else
						imgui.CenterColumnText(u8'Отключено')
					end
					imgui.NextColumn()
					if imgui.CenterColumnSmallButton(u8'Изменить##rp_chat') then
						settings.general.rp_chat = not settings.general.rp_chat
						save(settings, path)
					end
					
					imgui.Columns(1)
					
					imgui.Separator()
					
					imgui.Columns(3)
					imgui.CenterColumnText(u8"Авто Увал")
					imgui.SameLine(nil, 5) imgui.TextDisabled("[?]")
					if imgui.IsItemHovered() then
						imgui.SetTooltip(u8"Автоматическое увольнение сотрудников, которые хотят увал ПСЖ\nФункция доступна только если вы 9/10 ранг!")
					end
					imgui.NextColumn()
					if settings.general.auto_uval then
						imgui.CenterColumnText(u8'Включено')
					else
						imgui.CenterColumnText(u8'Отключено')
					end
					imgui.NextColumn()
					if imgui.CenterColumnSmallButton(u8'Изменить##autouval') then
						if tonumber(settings.general.fraction_rank_number) == 9 or tonumber(settings.general.fraction_rank_number) == 10 then 
							settings.general.auto_uval = not settings.general.auto_uval
						else
							settings.general.auto_uval = false
							sampAddChatMessage('[Hospital Helper] {ffffff}Эта Функция доступна только лидеру и заместителям!',message_color)
						end
						save(settings, path)
					end
					
					imgui.Separator()
				
				imgui.EndChild()
				end
	
				imgui.EndTabItem()
			end
			
			if imgui.BeginTabItem(fa.RECTANGLE_LIST..u8' Команды и отыгровки') then 
				
				if imgui.BeginTabBar('Tabs2') then
				
					if imgui.BeginTabItem(fa.BARS..u8' Общие команды для всех рангов ') then 
							
						if imgui.BeginChild('##1', imgui.ImVec2(589 * MONET_DPI_SCALE, 333 * MONET_DPI_SCALE), true) then
				
							imgui.Columns(3)
							imgui.CenterColumnText(u8"Команда")
							imgui.SetColumnWidth(-1, 170 * MONET_DPI_SCALE)
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Описание")
							imgui.SetColumnWidth(-1, 300 * MONET_DPI_SCALE)
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Действие")
							imgui.SetColumnWidth(-1, 150 * MONET_DPI_SCALE)
							imgui.Columns(1)
							
							imgui.Separator()
							
							imgui.Columns(3)
							if isMonetLoader() then
								imgui.CenterColumnText(u8"/hh")
							else
								imgui.CenterColumnText(u8"/hh | F2")
							end
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Открыть главное меню хелпера")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Недоступно")
							imgui.Columns(1)
					
							imgui.Separator()
							
							imgui.Columns(3)
							if isMonetLoader() then
								imgui.CenterColumnText(u8"/hm | X2 клик по игроку")
							else
								imgui.CenterColumnText(u8"/hm | ПКМ + R")
							end
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Открыть быстрое меню взаимодействия")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Недоступно")
							imgui.Columns(1)
							
							imgui.Separator()
							
							imgui.Columns(3)
							imgui.CenterColumnText(u8"/mb")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Открыть список сотрудников в сети")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Недоступно")
							imgui.Columns(1)
							
							imgui.Separator()
							
							imgui.Columns(3)
							imgui.CenterColumnText(u8"/mс")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Выдать игроку мед.карту")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Недоступно")
							imgui.Columns(1)
							
							imgui.Separator()
							
							imgui.Columns(3)
							imgui.CenterColumnText(u8"/ant")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Выдать игроку антибиотики")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Недоступно")
							imgui.Columns(1)
							
							imgui.Separator()
							
							imgui.Columns(3)
							imgui.CenterColumnText(u8"/rec")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Выдать игроку рецепты")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Недоступно")
							imgui.Columns(1)
							
							imgui.Separator()
							
							imgui.Columns(3)
							imgui.CenterColumnText(u8"/osm")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Провести полный мед.осмотр игрока")
							imgui.NextColumn()
							imgui.CenterColumnText(u8"Недоступно")
							imgui.Columns(1)
							
							imgui.Separator()
							
							for _, command in ipairs(settings.commands) do
							
								imgui.Columns(3)
								
								if command.enable then
									imgui.CenterColumnText('/' .. u8(command.cmd))
									imgui.NextColumn()
									imgui.CenterColumnText(u8(command.description))
									imgui.NextColumn()
								else
									imgui.CenterColumnTextDisabled('/' .. u8(command.cmd))
									imgui.NextColumn()
									imgui.CenterColumnTextDisabled(u8(command.description))
									imgui.NextColumn()
								end
								
								imgui.Text('    ')
								
								imgui.SameLine()
								
								
								if command.enable then
									if imgui.SmallButton(fa.TOGGLE_ON .. '##'..command.cmd) then
										command.enable = not command.enable
										save(settings, path)
										sampUnregisterChatCommand(command.cmd)
									end
									if imgui.IsItemHovered() then
										imgui.SetTooltip(u8"Отключение команды /"..command.cmd)
									end
								else
									if imgui.SmallButton(fa.TOGGLE_OFF .. '##'..command.cmd) then
										command.enable = not command.enable
										save(settings, path)
										sampRegisterChatCommand(command.cmd, function(arg)
							
											local arg_check = false
											
											local modifiedText = command.text

											if command.arg == '#arg' then
												if arg and arg ~= '' then
													modifiedText = modifiedText:gsub('#arg', arg or "")
													arg_check = true
												else
													sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [аргумент]', message_color)
												end
											elseif command.arg == '#arg_id' then
												if arg and arg ~= '' and isParamID(arg) then
													modifiedText = modifiedText:gsub('#arg_id', arg or "")
													arg_check = true
												else
													sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока]', message_color)
												end
											elseif command.arg == '#arg_id #arg2' then
												if arg and arg ~= '' then
													local arg_id, arg2 = arg:match('(%d+) (.+)')
													if arg_id and arg2 and isParamID(arg_id) then
														modifiedText = modifiedText:gsub('#arg_id', arg_id or "")
														modifiedText = modifiedText:gsub('#arg2', arg2 or "")
														arg_check = true
													else
														sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока] [аргумент]', message_color)
													end
												else
													sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока] [аргумент]', message_color)
												end
											elseif command.arg == '' then
												arg_check = true
											end
											
											if arg_check then
												lua_thread.create(function()
													local lines = {}

													for line in string.gmatch(modifiedText, "[^&]+") do
														table.insert(lines, line)
													end

													for _, line in ipairs(lines) do
														for tag, replacement in pairs(tagReplacements) do
															local success, result = pcall(string.gsub, line, "#" .. tag, replacement())
															if success then
																line = result
															else
																sampAddChatMessage('[Hospital Helper] {ffffff}Данный тэг не существует!', message_color)
															end
														end

														sampSendChat(line)
														
														wait(get_my_wait())
													end
												end)
											end
											
										end)
									end
									if imgui.IsItemHovered() then
										imgui.SetTooltip(u8"Включение команды /"..command.cmd)
									end
								end
								
								imgui.SameLine()
								
								if imgui.SmallButton(fa.PEN_TO_SQUARE .. '##'..command.cmd) then
								
									change_description = command.description
									input_description = ffi.new("char[256]", u8(change_description))
									
									change_arg = command.arg
									if command.arg == '' then
										ComboTags[0] = 0
									elseif command.arg == '#arg' then	
										ComboTags[0] = 1
									elseif command.arg == '#arg_id' then
										ComboTags[0] = 2
									elseif command.arg == '#arg_id #arg2' then
										ComboTags[0] = 3
									end
									
									change_cmd = command.cmd
									input_cmd = ffi.new("char[256]", command.cmd)
									
									change_text = command.text:gsub('&', '\n')
									input_text = ffi.new("char[8192]", u8(change_text))
									
									
											
									BinderWindow[0] = true
									
								end
								if imgui.IsItemHovered() then
									imgui.SetTooltip(u8"Изменение команды /"..command.cmd)
								end
								
								--[[imgui.SameLine()
								
								if imgui.SmallButton(fa.CLONE .. '##'..command.cmd) then
									sampAddChatMessage('[Hospital Helper] {ffffff}Клонирование временно не доступно!', message_color)
								end
								if imgui.IsItemHovered() then
									imgui.SetTooltip(u8"Клонировать команду /"..command.cmd)
								end]]
								
								
								
								
								
								imgui.Columns(1)
								imgui.Separator()
								
								
							
							end
							
					
						imgui.EndChild()
					end
				
					
						imgui.EndTabItem()
					end
					
					if imgui.BeginTabItem(fa.BARS..u8' Команды для 9-10 рангов') then 
						if tonumber(settings.general.fraction_rank_number) == 9 or tonumber(settings.general.fraction_rank_number) == 10 then
							
							if imgui.BeginChild('##1', imgui.ImVec2(589 * MONET_DPI_SCALE, 333 * MONET_DPI_SCALE), true) then
				
								imgui.Columns(3)
								imgui.CenterColumnText(u8"Команда")
								imgui.SetColumnWidth(-1, 170 * MONET_DPI_SCALE)
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Описание")
								imgui.SetColumnWidth(-1, 300 * MONET_DPI_SCALE)
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Действие")
								imgui.SetColumnWidth(-1, 150 * MONET_DPI_SCALE)
								imgui.Columns(1)
								
								imgui.Separator()
								
								for _, command in ipairs(settings.commands_manage) do
							
									imgui.Columns(3)
									
									if command.enable then
										imgui.CenterColumnText('/' .. u8(command.cmd))
										imgui.NextColumn()
										imgui.CenterColumnText(u8(command.description))
										imgui.NextColumn()
									else
										imgui.CenterColumnTextDisabled('/' .. u8(command.cmd))
										imgui.NextColumn()
										imgui.CenterColumnTextDisabled(u8(command.description))
										imgui.NextColumn()
									end
									
									imgui.Text('    ')
									
									imgui.SameLine()
									
									if command.enable then
										if imgui.SmallButton(fa.TOGGLE_ON .. '##'..command.cmd) then
											command.enable = not command.enable
											save(settings, path)
											sampUnregisterChatCommand(command.cmd)
										end
										if imgui.IsItemHovered() then
											imgui.SetTooltip(u8"Отключение команды /"..command.cmd)
										end
									else
										if imgui.SmallButton(fa.TOGGLE_OFF .. '##'..command.cmd) then
											command.enable = not command.enable
											save(settings, path)
											sampRegisterChatCommand(command.cmd, function(arg)
								
												local arg_check = false
												
												local modifiedText = command.text

												if command.arg == '#arg' then
													if arg and arg ~= '' then
														modifiedText = modifiedText:gsub('#arg', arg or "")
														arg_check = true
													else
														sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [аргумент]', message_color)
													end
												elseif command.arg == '#arg_id' then
													if arg and arg ~= '' and isParamID(arg) then
														modifiedText = modifiedText:gsub('#arg_id', arg or "")
														arg_check = true
													else
														sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока]', message_color)
													end
												elseif command.arg == '#arg_id #arg2' then
													if arg and arg ~= '' then
														local arg_id, arg2 = arg:match('(%d+) (.+)')
														if arg_id and arg2 and isParamID(arg_id) then
															modifiedText = modifiedText:gsub('#arg_id', arg_id or "")
															modifiedText = modifiedText:gsub('#arg2', arg2 or "")
															arg_check = true
														else
															sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока] [аргумент]', message_color)
														end
													else
														sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока] [аргумент]', message_color)
													end
												elseif command.arg == '' then
													arg_check = true
												end
												
												if arg_check then
													lua_thread.create(function()
														local lines = {}

														for line in string.gmatch(modifiedText, "[^&]+") do
															table.insert(lines, line)
														end

														for _, line in ipairs(lines) do
															for tag, replacement in pairs(tagReplacements) do
																local success, result = pcall(string.gsub, line, "#" .. tag, replacement())
																if success then
																	line = result
																else
																	sampAddChatMessage('[Hospital Helper] {ffffff}Данный тэг не существует!', message_color)
																end
															end

															sampSendChat(line)
															
															wait(get_my_wait())
														end
													end)
												end
												
											end)
										end
										if imgui.IsItemHovered() then
											imgui.SetTooltip(u8"Включение команды /"..command.cmd)
										end
									end
									
									imgui.SameLine()
									
									if imgui.SmallButton(fa.PEN_TO_SQUARE .. '##'..command.cmd) then
									
										change_description = command.description
										input_description = ffi.new("char[256]", u8(change_description))
										
										change_arg = command.arg
										if command.arg == '' then
											ComboTags[0] = 0
										elseif command.arg == '#arg' then	
											ComboTags[0] = 1
										elseif command.arg == '#arg_id' then
											ComboTags[0] = 2
										elseif command.arg == '#arg_id #arg2' then
											ComboTags[0] = 3
										end
										
										change_cmd = command.cmd
										input_cmd = ffi.new("char[256]", command.cmd)
										
										change_text = command.text:gsub('&', '\n')
										input_text = ffi.new("char[8192]", u8(change_text))
										
										
												
										BinderWindow[0] = true
										
									end
									if imgui.IsItemHovered() then
										imgui.SetTooltip(u8"Изменение команды /"..command.cmd)
									end
									
									--[[imgui.SameLine()
									
									if imgui.SmallButton(fa.CLONE .. '##'..command.cmd) then
										sampAddChatMessage('[Hospital Helper] {ffffff}Клонирование временно не доступно!', message_color)
									end
									if imgui.IsItemHovered() then
										imgui.SetTooltip(u8"Клонировать команду /"..command.cmd)
									end]]
									
									
									imgui.Columns(1)
									imgui.Separator()
								
								end
								
								imgui.Columns(3)
								imgui.CenterColumnText(u8"/vc")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Выдать/изьять VC визу сотруднику")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Недоступно")
								imgui.Columns(1)
								
								imgui.Separator()
								
								imgui.Columns(3)
								imgui.CenterColumnText(u8"/spawncar")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Заспавнить т/с организации")
								imgui.NextColumn()
								imgui.CenterColumnText(u8"Недоступно")
								imgui.Columns(1)
								
								imgui.Separator()
								
								imgui.EndChild()
							end
							
						else
							imgui.Text(u8" У вас нет доступа к данным командам, так как вы "..settings.general.fraction_rank_number..u8" ранг.")
						end
						imgui.EndTabItem() 
					end
					
					if imgui.BeginTabItem(fa.BARS..u8' Дополнительные функции') then 
						
						imgui.BulletText(u8" Будет доступно в версии 3.1!")
						
						imgui.EndTabItem() 
					end
				
				
					imgui.EndTabBar() 
					
				end
				
				imgui.EndTabItem()
				
			end
			
			if imgui.BeginTabItem(fa.MONEY_CHECK_DOLLAR..u8' Ценовая политика') then 
				
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Лечение игрока (SA $)', input_heal, 6) then
					settings.price.heal = u8:decode(ffi.string(input_heal))
					save(settings, path)
				end
				
				imgui.SameLine()
				
				imgui.SetCursorPosX(300 * MONET_DPI_SCALE)
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Лечение игрока (VC $)', input_heal_vc, 6) then
					settings.price.heal_vc = u8:decode(ffi.string(input_heal_vc))
					save(settings, path)
				end
				
				imgui.Separator()
				
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Лечение охранника (SA $)', input_healactor, 8) then
					settings.price.healactor = u8:decode(ffi.string(input_healactor))
					save(settings, path)
				end
				
				imgui.SameLine()
				imgui.SetCursorPosX(300 * MONET_DPI_SCALE)
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Лечение охранника (VC $)', input_healactor_vc, 8) then
					settings.price.healactor_vc = u8:decode(ffi.string(input_healactor_vc))
					save(settings, path)
				end
				
				imgui.Separator()
				
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Проведение мед. осмотра для пилотов', input_medosm, 8) then
					settings.price.medosm = u8:decode(ffi.string(input_medosm))
					save(settings, path)
				end
				
				imgui.Separator()
				
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Проведение мед. обследования для военного билета', input_mticket, 8) then
					settings.price.mticket = u8:decode(ffi.string(input_mticket))
					save(settings, path)
				end
				
				imgui.Separator()
				
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Выдача рецепта', input_recept, 8) then
					settings.price.recept = u8:decode(ffi.string(input_recept))
					save(settings, path)
				end
				
				imgui.Separator()
				
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Выдача антибиотика', input_ant, 8) then
					settings.price.ant = u8:decode(ffi.string(input_ant))
					save(settings, path)
				end
				
				imgui.Separator()
				
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Сведение татуировки', input_tatu, 8) then
					settings.price.tatu = u8:decode(ffi.string(input_tatu))
					save(settings, path)
				end
				
				imgui.Separator()
				
				
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Выдача мед.карты на 7 дней', input_med7, 8) then
					settings.price.med7 = u8:decode(ffi.string(input_med7))
					save(settings, path)
				end
				
			
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Выдача мед.карты на 14 дней', input_med14, 8) then
					settings.price.med14 = u8:decode(ffi.string(input_med14))
					save(settings, path)
				end
				
				imgui.Separator()
				
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Выдача мед.карты на 30 дней', input_med30, 8) then
					settings.price.med30 = u8:decode(ffi.string(input_med30))
					save(settings, path)
				end
				
				imgui.Separator()
				
				imgui.PushItemWidth(65 * MONET_DPI_SCALE)
				if imgui.InputText(u8'  Выдача мед.карты на 60 дней', input_med60, 8) then
					settings.price.med60 = u8:decode(ffi.string(input_med60))
					save(settings, path)
				end

				

			imgui.EndTabItem()
			end
			
			if imgui.BeginTabItem(fa.FILE_PEN..u8' Заметки') then 
		
				if imgui.InputTextMultiline("##text_multiple", input_text_note, 8192, imgui.ImVec2(590 * MONET_DPI_SCALE, 361 * MONET_DPI_SCALE)) then
					settings.note.my_note = u8:decode(ffi.string(input_text_note)):gsub('\n', '&')
					save(settings, path)	
				end
					
				imgui.EndTabItem()
			end
			
			if imgui.BeginTabItem(fa.GEAR..u8' Настройки') then 
			
					imgui.Text(fa.CIRCLE_USER..u8" Разработчик хелпера: MTG MODS")
					imgui.Separator()
					imgui.Text(fa.CIRCLE_INFO..u8" Версия хелпера, которая сейчас установлена у вас: "..thisScript().version)
					imgui.Separator()
					
					if isMonetLoader() then
						imgui.Text(fa.HEADSET..u8" Тех.поддержка по хелперу:")
						imgui.SameLine()
						imgui.Text('https://discord.com/invite/qBPEYjfNhv')
					else
						imgui.Text(fa.HEADSET..u8" Тех.поддержка по хелперу:")
						imgui.SameLine()
						imgui.Link('https://discord.com/invite/qBPEYjfNhv','https://discord.com/invite/qBPEYjfNhv')
					end
					
					imgui.Separator()
					
					if isMonetLoader() then
						imgui.Text(fa.GLOBE..u8" Тема хелпера на BlastHack:")
						imgui.SameLine()
						imgui.Text('https://www.blast.hk/threads/195388')
					else
						imgui.Text(fa.GLOBE..u8" Тема хелпера на BlastHack:")
						imgui.SameLine()
						imgui.Link('https://www.blast.hk/threads/195388','https://www.blast.hk/threads/195388')
					end
					
					--[[if imgui.Button(u8'Проверить наличие новых версий хелпера') then
						sampAddChatMessage('[Hospital Helper] {ffffff}Функция обновлений временно отсутствует!',message_color)
					end]]
					
					imgui.Separator()
					
					
					
					
			
				imgui.EndTabItem()
			end
		
		imgui.EndTabBar() end
		
		imgui.End()
		
    end
)

local FastMenuWindow = imgui.OnFrame(
    function() return FastMenu[0] end,
    function(player)
	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		--imgui.SetNextWindowSize(imgui.ImVec2(300 * MONET_DPI_SCALE, 415 * MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		imgui.Begin(fa.USER_INJURED..' '..sampGetPlayerNickname(player_id)..'['..player_id..']##FastMenu', FastMenu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize )
		
		if imgui.Button(u8"Привествие",imgui.ImVec2(290 * MONET_DPI_SCALE, 30 * MONET_DPI_SCALE)) then
			
			FastMenu[0] = false
		end
		
		if imgui.Button(u8"Позвать за собой",imgui.ImVec2(290 * MONET_DPI_SCALE, 30 * MONET_DPI_SCALE)) then
			
			FastMenu[0] = false
		end
		
		if imgui.Button(u8"Обычное лечение",imgui.ImVec2(290 * MONET_DPI_SCALE, 30 * MONET_DPI_SCALE)) then
			command("/heal #arg_id",player_id)
			FastMenu[0] = false
		end
		
		if imgui.Button(u8"Лечение охранника",imgui.ImVec2(290 * MONET_DPI_SCALE, 30 * MONET_DPI_SCALE)) then
			command("/healactor #arg_id",player_id)
			FastMenu[0] = false
		end
		
		if imgui.Button(u8"Лечение от наркозависимости",imgui.ImVec2(290 * MONET_DPI_SCALE, 30 * MONET_DPI_SCALE)) then
			command("/healbad #arg_id",player_id)
			FastMenu[0] = false
		end
		
		if imgui.Button(u8"Оформление мед.страховки",imgui.ImVec2(290 * MONET_DPI_SCALE, 30 * MONET_DPI_SCALE)) then
			command("/givemedinsurance #arg_id",player_id)
			FastMenu[0] = false
		end
		
		if imgui.Button(u8"Оформление мед.карты",imgui.ImVec2(290 * MONET_DPI_SCALE, 30 * MONET_DPI_SCALE)) then
			medcard(player_id)
			FastMenu[0] = false
		end
		
		if imgui.Button(u8"Проведение мед.осмотра пилота",imgui.ImVec2(290 * MONET_DPI_SCALE, 30 * MONET_DPI_SCALE)) then
			command("/medcheck #arg_id",player_id)
			FastMenu[0] = false
		end
		
		if imgui.Button(u8"Выдача антибиотиков",imgui.ImVec2(290 * MONET_DPI_SCALE, 30 * MONET_DPI_SCALE)) then
			antibiotik(player_id)
			FastMenu[0] = false
		end
		
		if imgui.Button(u8"Выдача рецептов",imgui.ImVec2(290 * MONET_DPI_SCALE, 30 * MONET_DPI_SCALE)) then
			recept(player_id)
			FastMenu[0] = false
		end
		
		if imgui.Button(u8"Выгнать из больницы",imgui.ImVec2(290 * MONET_DPI_SCALE, 30 * MONET_DPI_SCALE)) then
			command("/expel #arg_id",player_id)
			FastMenu[0] = false
		end
	
		imgui.End()
		
    end
)

local MedCardMenu = imgui.OnFrame(
    function() return MedCardMenu[0] end,
    function(player)
	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY - 100  * MONET_DPI_SCALE), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		--imgui.SetNextWindowSize(imgui.ImVec2(340 * MONET_DPI_SCALE, 115 * MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		imgui.Begin(fa.HOSPITAL.." Hospital Helper##med", MedCardMenu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize )
		
		
		imgui.CenterText(u8'Мед.карта для игрока '..sampGetPlayerNickname(player_id))
		
		if imgui.RadioButtonIntPtr(u8" 7 дней ##0",medcard_days,0) then
			medcard_days[0] = 0
		end
		imgui.SameLine()
		
		if imgui.RadioButtonIntPtr(u8" 14 дней ##1",medcard_days,1) then
			medcard_days[0] = 1
		end
		imgui.SameLine()
		
		if imgui.RadioButtonIntPtr(u8" 30 дней ##2",medcard_days,2) then
			medcard_days[0] = 2
		end
		imgui.SameLine()
		
		if imgui.RadioButtonIntPtr(u8" 60 дней ##3",medcard_days,3) then
			medcard_days[0] = 3
		end
		
		imgui.Separator()
		
		local width = imgui.GetWindowWidth()
		local calc = imgui.CalcTextSize(u8"Выдать мед.карту")
		imgui.SetCursorPosX( width / 2 - calc.x / 2 )
		if imgui.Button(fa.ID_CARD_CLIP..u8" Выдать мед.карту") then
			
			lua_thread.create(function()
			
				sampSendChat("Хорошо, тогда приступим к оформлению.")
				wait(get_my_wait())
				sampSendChat("/me достаёт из своего мед.кейса пустую мед.карту, ручку и печать ".. settings.general.fraction_tag .. ".")
				wait(get_my_wait())
				sampSendChat("/me открывает пустую мед.карту и начинает её заполнять, затем ставит печать ".. settings.general.fraction_tag .. ".")
				wait(get_my_wait())
				sampSendChat("/me полностю заполнив мед.карту убирает ручку и печать обратно в свой мед.кейс.")
				wait(get_my_wait())
				sampSendChat("/todo Вот ваша мед.карта, берите*протягивая заполненную мед.карту человеку напротив себя")
				wait(get_my_wait())
	
				if medcard_days[0] == 0 then
					sampSendChat("/medcard "..player_id.." 3 0 "..settings.price.med7)
				elseif medcard_days[0] == 1 then
					sampSendChat("/medcard "..player_id.." 3 1 "..settings.price.med14)
				elseif medcard_days[0] == 2 then
					sampSendChat("/medcard "..player_id.." 3 2 "..settings.price.med30)
				elseif medcard_days[0] == 3 then
					sampSendChat("/medcard "..player_id.." 3 3 "..settings.price.med60)
				end
				
			end)
			MedCardMenu[0] = false
			
		end
		
		imgui.End()
		
    end
)

local ReceptMenu = imgui.OnFrame(
    function() return ReceptMenu[0] end,
    function(player)
	

		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY - 100  * MONET_DPI_SCALE), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(340 * MONET_DPI_SCALE, 130 * MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		imgui.Begin(fa.HOSPITAL.." Hospital Helper##recept", ReceptMenu, imgui.WindowFlags.NoCollapse )

		
        imgui.CenterText(u8'Рецепты для игрока '..sampGetPlayerNickname(player_id))
        imgui.CenterText(u8'(укажите кол-во рецептов для выдачи)')
	
		local buttonWidth = 40 * MONET_DPI_SCALE -- Adjust the width of the radio buttons as needed
		local totalButtonWidth = buttonWidth * 5 + imgui.GetStyle().ItemSpacing.x * 4
		local startPosX = imgui.GetWindowWidth() / 2 - totalButtonWidth / 2

		imgui.SetCursorPosX(startPosX)
		if imgui.RadioButtonIntPtr(u8" 1 ##rec0", recepts, 0) then
			recepts[0] = 0
		end

		imgui.SameLine()

		imgui.SetCursorPosX(startPosX + buttonWidth + imgui.GetStyle().ItemSpacing.x)
		if imgui.RadioButtonIntPtr(u8" 2 ##rec1", recepts, 1) then
			recepts[0] = 1
		end

		imgui.SameLine()

		imgui.SetCursorPosX(startPosX + 2 * (buttonWidth + imgui.GetStyle().ItemSpacing.x))
		if imgui.RadioButtonIntPtr(u8" 3 ##rec2", recepts, 2) then
			recepts[0] = 2
		end

		imgui.SameLine()

		imgui.SetCursorPosX(startPosX + 3 * (buttonWidth + imgui.GetStyle().ItemSpacing.x))
		if imgui.RadioButtonIntPtr(u8" 4 ##rec3", recepts, 3) then
			recepts[0] = 3
		end

		imgui.SameLine()

		imgui.SetCursorPosX(startPosX + 4 * (buttonWidth + imgui.GetStyle().ItemSpacing.x))
		if imgui.RadioButtonIntPtr(u8" 5 ##rec4", recepts, 4) then
			recepts[0] = 4
		end

		imgui.Separator()

        local width = imgui.GetWindowWidth()
        local calc = imgui.CalcTextSize(u8"Выдать рецепты")
        imgui.SetCursorPosX(width / 2 - calc.x / 2)


		if imgui.Button(fa.RECEIPT..u8" Выдать рецепты") then
			
			lua_thread.create(function()
				sampSendChat("Хорошо, сейчас я выдам вам рецепты.")
				wait(get_my_wait())
				sampSendChat("/me достаёт из своего мед.кейса бланк для оформления рецептов и начает его заполнять.")
				wait(get_my_wait())
				sampSendChat("/do Бланк успешно заполнен.")
				wait(get_my_wait())
				sampSendChat("/todo Вот, держите!*передавая бланк с рецептами человеку напротив")
				wait(get_my_wait())
				sampSendChat("/recept "..player_id.." "..tonumber(recepts[0])+1)
			end)
			ReceptMenu[0] = false
			
		end

        imgui.End()
		
    end
)

local AntibiotikMenu = imgui.OnFrame(
    function() return AntibiotikMenu[0] end,
    function(player)
	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY - 100 * MONET_DPI_SCALE), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		--imgui.SetNextWindowSize(imgui.ImVec2(340 * MONET_DPI_SCALE, 130 * MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		imgui.Begin(fa.HOSPITAL.." Hospital Helper##ant", AntibiotikMenu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize )
		
		
		imgui.CenterText(u8'Антибиотики для игрока '..sampGetPlayerNickname(player_id))
		imgui.CenterText(u8'(укажите кол-во антибиотиков для выдачи)')
		--imgui.SetCursorPosX(30)
		
		
		imgui.PushItemWidth(300*MONET_DPI_SCALE)
		imgui.SliderInt('', antibiotiks, 1, 20)

		imgui.Separator()
		
		local width = imgui.GetWindowWidth()
		local calc = imgui.CalcTextSize(u8"Выдать антибиотики")
		imgui.SetCursorPosX( width / 2 - calc.x / 2 )
		if imgui.Button(fa.CAPSULES..u8" Выдать антибиотики") then
			
			lua_thread.create(function()
				sampSendChat("Хорошо, сейчас я выдам вам антибиотики.")
				wait(get_my_wait())
				sampSendChat("/me открывает свой мед.кейс и достаёт из него пачку антибиотиков, после чего закрывает мед.кейс.")
				wait(get_my_wait())
				sampSendChat("/do Антибиотики находятся в руках.")
				wait(get_my_wait())
				sampSendChat("/todo Вот держите, употребляйте их строго по рецепту!*передавая антибиотики человеку напротив")
				wait(get_my_wait())
				sampSendChat("/antibiotik "..player_id.." "..antibiotiks[0])
			end)
			AntibiotikMenu[0] = false
			
		end
		
		imgui.End()
		
    end
)

local MedOsmotrMenu2 = imgui.OnFrame(
    function() return  MedOsmotrMenu2[0] end,
    function(player)
	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY - (100 * MONET_DPI_SCALE)), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(400 * MONET_DPI_SCALE, 130 * MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		imgui.Begin(fa.HOSPITAL.." Hospital Helper##medosm2",  MedOsmotrMenu2, imgui.WindowFlags.NoCollapse )
		
		imgui.CenterText(u8'Проведение мед.осмотра для игрока '..sampGetPlayerNickname(player_id))
		imgui.Separator()
		
		imgui.CenterText(u8"Ожидайте пока человек покажет вам мед.карту.")
			
		imgui.CenterText("")
		imgui.Separator()
		
		local width = imgui.GetWindowWidth()
		local calc = imgui.CalcTextSize(u8"У игрока нет мед.карты")
		imgui.SetCursorPosX( width / 2 - calc.x / 2 )
		if imgui.Button(fa.TRIANGLE_EXCLAMATION..u8" У игрока нет мед.карты") then
			lua_thread.create(function()
				MedOsmotrMenu2[0] = false
				sampSendChat("Это очень плохо что у вас нету мед.карты, её нужно будет оформить обязательно!")
				wait(get_my_wait())
				sampSendChat("/me достаёт из мед.кейса стерильные перчатки и надевает их на руки.")
				wait(get_my_wait())
				sampSendChat("/do Перчатки на руках.")
				wait(get_my_wait())
				sampSendChat("/todo Начнём мед.осмотр*улыбаясь.")
				wait(get_my_wait())
				sampSendChat("Сейчас я проверю ваше горло, откройте рот и высуните язык.")
				wait(get_my_wait())
				sampSendChat("/n Используйте /me открыл(-а) рот.")
				medcheck_no_medcard = true
				MedOsmotrMenu4[0] = true
			end)
		end
		
		imgui.End()
		
    end
)
local MedOsmotrMenu3 = imgui.OnFrame(
    function() return  MedOsmotrMenu3[0] end,
    function(player)
	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY - (100 * MONET_DPI_SCALE)), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(400 * MONET_DPI_SCALE, 130 * MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		imgui.Begin(fa.HOSPITAL.." Hospital Helper##medosm3",  MedOsmotrMenu3, imgui.WindowFlags.NoCollapse )
		
		imgui.CenterText(u8'Проведение мед.осмотра для игрока '..sampGetPlayerNickname(player_id))
		imgui.Separator()
		
		imgui.CenterText(fa.ID_CARD_CLIP..u8" Статус мед.карты: "..u8(medcard_status))
		imgui.CenterText(fa.CANNABIS..u8" Наркозависимость: "..medcard_narko)
		
		imgui.Separator()
		
		if not medcard_status == "Полностью здоровый(ая)" or tonumber(medcard_narko) > 0 then
		
			local width = imgui.GetWindowWidth()
			local calc = imgui.CalcTextSize(u8"Сообщить о проблеме и продолжить")
			imgui.SetCursorPosX( width / 2 - calc.x / 2 )
			
			if imgui.Button(fa.CIRCLE_RIGHT..u8" Сообщить о проблеме и продолжить") then
				lua_thread.create(function()
					MedOsmotrMenu3[0] = false
					if not medcard_status == "Полностью здоровый(ая)" and tonumber(medcard_narko) > 0 then
						sampSendChat("У вас есть наркозависимость "..tonumber(medcard_narko).." едениц, и статус здоровья "..medcard_status.."!")
					elseif tonumber(medcard_narko) > 0 then
						sampSendChat("У вас есть наркозависимость "..tonumber(medcard_narko).." едениц!")
					elseif not medcard_status == "Полностью здоровый(ая)" then
						sampSendChat("У вас статус здоровья "..medcard_status..", это очень плохо!")
					end
					wait(get_my_wait())
					sampSendChat("/me достаёт из мед.кейса стерильные перчатки и надевает их на руки.")
					wait(get_my_wait())
					sampSendChat("/do Перчатки на руках.")
					wait(get_my_wait())
					sampSendChat("/todo Начнём мед.осмотр*улыбаясь.")
					wait(get_my_wait())
					sampSendChat("Сейчас я проверю ваше горло, откройте рот и высуните язык.")
					wait(get_my_wait())
					sampSendChat("/n Используйте /me открыл(-а) рот.")
					MedOsmotrMenu4[0] = true
				end)
			end
			
		else
		
			local width = imgui.GetWindowWidth()
			local calc = imgui.CalcTextSize(u8"Продолжить")
			imgui.SetCursorPosX( width / 2 - calc.x / 2 )
			
			if imgui.Button(fa.CIRCLE_RIGHT..u8" Продолжить") then
				lua_thread.create(function()
					MedOsmotrMenu3[0] = false
					sampSendChat("Что-ж, с мед.картой у вас все в порядке, продолжим...")
					wait(get_my_wait())
					sampSendChat("/me достаёт из мед.кейса стерильные перчатки и надевает их на руки.")
					wait(get_my_wait())
					sampSendChat("/do Перчатки на руках.")
					wait(get_my_wait())
					sampSendChat("/todo Начнём мед.осмотр*улыбаясь.")
					wait(get_my_wait())
					sampSendChat("Сейчас я проверю ваше горло, откройте рот и высуните язык.")
					wait(get_my_wait())
					sampSendChat("/n Используйте /me открыл(-а) рот.")
					MedOsmotrMenu4[0] = true
				end)
			end
			
		end
		
		imgui.End()
		
    end
)
local MedOsmotrMenu4 = imgui.OnFrame(
    function() return  MedOsmotrMenu4[0] end,
    function(player)
	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY - (100 * MONET_DPI_SCALE)), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(400 * MONET_DPI_SCALE, 130 * MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		imgui.Begin(fa.HOSPITAL.." Hospital Helper##medosm4",  MedOsmotrMenu4, imgui.WindowFlags.NoCollapse )
		
		imgui.CenterText(u8'Проведение мед.осмотра для игрока '..sampGetPlayerNickname(player_id))
		imgui.Separator()
		
		imgui.CenterText(u8"Ожидайте пока человек откроет рот и нажмите кнопку.")
		imgui.CenterText("")
		imgui.Separator()
		
		local width = imgui.GetWindowWidth()
		local calc = imgui.CalcTextSize(u8"Продолжить")
		imgui.SetCursorPosX( width / 2 - calc.x / 2 )
		if imgui.Button(fa.CIRCLE_RIGHT..u8" Продолжить") then
			lua_thread.create(function()
				MedOsmotrMenu4[0] = false
				sampSendChat("/me достаёт из мед.кейса фонарик и включив его осматривает горло человека напротив.")
				wait(get_my_wait())
				sampSendChat("Хорошо, можете закрывать рот, сейчас я проверю ваши глаза.")
				wait(get_my_wait())
				sampSendChat("/me проверяет реакцию человека на свет, посветив фонарик в глаза.")
				wait(get_my_wait())
				sampSendChat("/do Зрачки глаз обследуемого человека сузились.")
				wait(get_my_wait())
				sampSendChat("/todo Отлично*выключая фонарик и убирая его в мед.кейс")
				wait(get_my_wait())
				sampSendChat("Такс, сейчас я проверю ваше сердцебиение, поэтому приподнимите верхную одежду!")
				wait(get_my_wait())
				sampSendChat("/n Используйте команду /showtatu чтоб снять верхную одежду!")
				MedOsmotrMenu5[0] = true
			end)
			
		end
		
		imgui.End()
		
    end
)
local MedOsmotrMenu5 = imgui.OnFrame(
    function() return  MedOsmotrMenu5[0] end,
    function(player)
	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY - (100 * MONET_DPI_SCALE)), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(400 * MONET_DPI_SCALE, 130 * MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		imgui.Begin(fa.HOSPITAL.." Hospital Helper##medosm5",  MedOsmotrMenu5, imgui.WindowFlags.NoCollapse )
		
		imgui.CenterText(u8'Проведение мед.осмотра для игрока '..sampGetPlayerNickname(player_id))
		imgui.Separator()

		imgui.CenterText(u8"Ожидайте пока человек приподнимит одежду и нажмите кнопку.")
		imgui.CenterText("")
		imgui.Separator()
		
		local width = imgui.GetWindowWidth()
		local calc = imgui.CalcTextSize(u8"Продолжить")
		imgui.SetCursorPosX( width / 2 - calc.x / 2 )
		if imgui.Button(fa.CIRCLE_RIGHT..u8" Продолжить") then
			lua_thread.create(function()
				MedOsmotrMenu5[0] = false
				sampSendChat("/me достаёт из мед.кейса стетоскоп и приложив его к груди человека проверяет сердцебиение.")
				wait(get_my_wait())
				sampSendChat("/do Сердцебиение в районе " .. math.random(55,85) .. " ударов в минуту.")
				wait(get_my_wait())
				sampSendChat("/todo С сердцебиением у вас все в порядке*убирая стетоскоп обратно в мед.кейс")
				wait(get_my_wait())
				sampSendChat("/me снимает со своих рук использованные перчатки и выбрасывает их")
				wait(get_my_wait())
				sampSendChat("Ну, что-ж я могу вам сказать...")
				wait(get_my_wait())
				
				if tonumber(medcard_narko) > 0 and not medcard_status == "Полностью здоровый(ая)" then
					sampSendChat("У вас есть наркозависимость и проблемы с мед.картой!")
					wait(get_my_wait())
					sampSendChat("Никуда не уходите, ожидайте пока я скажу что вам нужно делать")
				elseif tonumber(medcard_narko) > 0 then
					sampSendChat("У вас есть наркозависимость!")
					wait(get_my_wait())
					sampSendChat("Никуда не уходите, ожидайте пока я скажу что вам нужно делать")
				elseif medcheck_no_medcard then
					medcheck_no_medcard = false
					sampSendChat("Со здоровьем у вас все в порядке, но у вас нету мед.карты!")
					wait(get_my_wait())
					sampSendChat("Никуда не уходите, ожидайте пока я скажу что вам нужно делать")
				else
					sampSendChat("Со здоровьем у вас все в порядке!")
				end
				
				medcard_narko = 0
				medcard_status = ''
				
				medcheck = false
				
			end)
			
		end

		imgui.End()
		
    end
)

local binder_tags_text = [[
#my_id - Ваш игровой ID
#my_nick- Ваш игровой Nick
#my_ru_nick - Ваше Имя и Фамилия указанные в хелпере
#fraction - Ваша фракция указанная в хелпере
#fraction_tag - Ваш фракционнфый тэг указанный в хелпере
#fraction_rank - Название вашего фракционного ранга в хелпере
#fraction_rank_number - Номер вашего фракционного ранга в хелпере
#expel_reason - Причина для выгона из хелпера
#price_heal - Цена лечения пациентов
#price_actorheal - Цена лечения охранников
#price_medosm - Цена мед.осмотра для пилота
#price_tatu - Цена удаления татуировки
#price_mticket - Цена обследования военного билета 
#price_ant - Цена антибиотика
#price_recept - Цена рецепта
#price_med7 - Цена медккарты на 7 дней
#price_med14 - Цена медккарты на 14 дней
#price_med30 - Цена медккарты на 30 дней
#price_med60 - Цена медккарты на 60 дней

#sex - Добавляет букву "а" если в хелпере указан женский пол
#get_nick(#arg_id) - получить Nick игрока из аргумента ID игрока
#get_ru_nick(#arg_id) - получить Nick игрока на кирилице из аргумента ID игрока ]]

local BinderWindow = imgui.OnFrame(
    function() return BinderWindow[0] end,
    function(player)
	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(600 * MONET_DPI_SCALE, 425	* MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		
		imgui.Begin(fa.PEN_TO_SQUARE .. u8' Редактирование команды /' .. change_cmd, BinderWindow, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize  )
		
		if imgui.BeginChild('##binder_edit', imgui.ImVec2(589 * MONET_DPI_SCALE, 350 * MONET_DPI_SCALE), true) then
		
			imgui.CenterText(u8'Описание команды:')
			imgui.PushItemWidth(579 * MONET_DPI_SCALE)
			imgui.InputText("##input_description", input_description, 256)
			
			imgui.Separator()
			
			imgui.CenterText(u8'Команда для использования в чате (без /):')
			imgui.PushItemWidth(579 * MONET_DPI_SCALE)
			imgui.InputText("##input_cmd", input_cmd, 256)
			
			imgui.Separator()
			
			imgui.CenterText(u8'Аргументы которые принимает команда:')
	    	imgui.Combo(u8'',ComboTags, ImItems, #item_list)
		
	 	    imgui.Separator()
	
	        imgui.CenterText(u8'Текстовый бинд команды:')
		    if imgui.InputTextMultiline("##text_multiple", input_text, 8192, imgui.ImVec2(590 * MONET_DPI_SCALE, 161 * MONET_DPI_SCALE)) then
				input_text_string = u8:decode(ffi.string(input_text))
				input_text_string = input_text_string:gsub('\n', '&')
			end
			
		imgui.EndChild() end

		if imgui.Button(u8'Отмена', imgui.ImVec2(  (imgui.GetWindowWidth() / 3) - (5 * MONET_DPI_SCALE) , 35 * MONET_DPI_SCALE)) then
			BinderWindow[0] = false
		end
		imgui.SameLine()
		if imgui.Button(u8'Список доступных тэгов', imgui.ImVec2( (imgui.GetWindowWidth() / 3) - (10 * MONET_DPI_SCALE), 35 * MONET_DPI_SCALE)) then
			imgui.OpenPopup(fa.TAGS .. u8' Список всех доступных тэгов')
		end
		if imgui.BeginPopupModal(fa.TAGS .. u8' Список всех доступных тэгов', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
			imgui.Text(u8(binder_tags_text))
			imgui.Separator()
			if imgui.Button(u8'Закрыть', imgui.ImVec2(500 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then
				imgui.CloseCurrentPopup()
			end
			imgui.End()
		end
		imgui.SameLine()

		if imgui.Button(u8'Сохранить', imgui.ImVec2( (imgui.GetWindowWidth() / 3) - (10 * MONET_DPI_SCALE), 35 * MONET_DPI_SCALE)) then	
			
			if ffi.string(input_cmd):find('%W') or ffi.string(input_cmd) == '' or ffi.string(input_description) == '' or ffi.string(input_text) == '' then
			
				imgui.OpenPopup(fa.TRIANGLE_EXCLAMATION .. u8' Ошибка сохранения команды!')
				
			else
			
				local new_arg = ''
			
				if ComboTags[0] == 0 then
					new_arg = ''
				elseif ComboTags[0] == 1 then
					new_arg = '#arg'
				elseif ComboTags[0] == 2 then
					new_arg = '#arg_id'
				elseif ComboTags[0] == 3 then
					new_arg = '#arg_id #arg2'
				end
				
				local new_description = u8:decode(ffi.string(input_description))
				local new_command = u8:decode(ffi.string(input_cmd))
				local new_text = u8:decode(ffi.string(input_text)):gsub('\n', '&')
				
				for _, command in ipairs(settings.commands) do

					if command.cmd == change_cmd and command.description == change_description and command.arg == change_arg and command.text:gsub('&', '\n') == change_text then
						
						command.cmd = new_command
						command.arg = new_arg
						command.description = new_description
						command.text = new_text
						
						save(settings, path)
						
						if command.arg == '' then
							sampAddChatMessage('[Hospital Helper] {ffffff}Команда ' .. message_color_hex .. '/' .. new_command .. ' {ffffff}успешно сохранена!', message_color)
						elseif command.arg == '#arg' then
							sampAddChatMessage('[Hospital Helper] {ffffff}Команда ' .. message_color_hex .. '/' .. new_command .. ' [arg] {ffffff}успешно сохранена!', message_color)
						elseif command.arg == '#arg_id' then
							sampAddChatMessage('[Hospital Helper] {ffffff}Команда ' .. message_color_hex .. '/' .. new_command .. ' [ID] {ffffff}успешно сохранена!', message_color)
						elseif command.arg == '#arg_id #arg2' then
							sampAddChatMessage('[Hospital Helper] {ffffff}Команда ' .. message_color_hex .. '/' .. new_command .. ' [ID] [arg] {ffffff}успешно сохранена!', message_color)
						end
						
					
						
						sampUnregisterChatCommand(change_cmd)
						
						sampRegisterChatCommand(command.cmd, function(arg)
			
							local arg_check = false
							
							local modifiedText = command.text

							if command.arg == '#arg' then
								if arg and arg ~= '' then
									modifiedText = modifiedText:gsub('#arg', arg or "")
									arg_check = true
								else
									sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [аргумент]', message_color)
									play_error_sound()
								end
							elseif command.arg == '#arg_id' then
								if arg and arg ~= '' and isParamID(arg) then
									modifiedText = modifiedText:gsub('#get_nick%(#arg_id%)', sampGetPlayerNickname(arg) or "")
									modifiedText = modifiedText:gsub('#get_ru_nick%(#arg_id%)', TranslateNick(sampGetPlayerNickname(arg)) or "")
									modifiedText = modifiedText:gsub('#arg_id', arg or "")
									arg_check = true
								else
									sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока]', message_color)
									play_error_sound()
								end
							elseif command.arg == '#arg_id #arg2' then
								if arg and arg ~= '' then
									local arg_id, arg2 = arg:match('(%d+) (.+)')
									if arg_id and arg2 and isParamID(arg_id) then
										modifiedText = modifiedText:gsub('#get_nick%(#arg_id%)', sampGetPlayerNickname(arg_id) or "")
										modifiedText = modifiedText:gsub('#get_ru_nick%(#arg_id%)', TranslateNick(sampGetPlayerNickname(arg_id)) or "")
										modifiedText = modifiedText:gsub('#arg_id', arg_id or "")
										modifiedText = modifiedText:gsub('#arg2', arg2 or "")
										arg_check = true
									else
										sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока] [аргумент]', message_color)
										play_error_sound()
									end
								else
									sampAddChatMessage('[Hospital Helper] {ffffff}Используйте ' .. message_color_hex .. '/' .. command.cmd .. ' [ID игрока] [аргумент]', message_color)
									play_error_sound()
								end
							elseif command.arg == '' then
								arg_check = true
							end
							
							if arg_check then
								lua_thread.create(function()
									local lines = {}

									for line in string.gmatch(modifiedText, "[^&]+") do
										table.insert(lines, line)
									end

									for _, line in ipairs(lines) do
										for tag, replacement in pairs(tagReplacements) do
											local success, result = pcall(string.gsub, line, "#" .. tag, replacement())
											if success then
												line = result
											else
												sampAddChatMessage('[Hospital Helper] {ffffff}Данный тэг не существует!', message_color)
											end
										end

										sampSendChat(line)
										
										wait(get_my_wait())
									end
								end)
							end
							
						end)
						
						
					end

				end
				
				BinderWindow[0] = false
			
			end
			
		end
		if imgui.BeginPopupModal(fa.TRIANGLE_EXCLAMATION .. u8' Ошибка сохранения команды!', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
			
			if ffi.string(input_cmd):find('%W') then
				imgui.BulletText(u8" В команде можно использовать только англ. буквы и/или цифры!")
			elseif ffi.string(input_cmd) == '' then
				imgui.BulletText(u8" Команда не может быть пустая!")
			end
			
			if ffi.string(input_description) == '' then
				imgui.BulletText(u8" Описание команды не может быть пустое!")
			end
			
			if ffi.string(input_text) == '' then
				imgui.BulletText(u8" Бинд команды не может быть пустой!")
			end
			
			if imgui.Button(u8'Закрыть', imgui.ImVec2(500 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then
				imgui.CloseCurrentPopup()
			end
			
			imgui.End()
		end	
			
		
		
		imgui.End()
    end
)

local MembersWindow = imgui.OnFrame(
    function() return MembersWindow[0] end,
    function(player)

		if tonumber(#members) >= 16 then
			sizeYY = 413
		else
			sizeYY = 24.5 * ( tonumber(#members) + 1 )
		end

		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(600 * MONET_DPI_SCALE, sizeYY * MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		
		local add = ''
		
		if tonumber(#members) == 1 then
			add = u8'сотрудник'
		elseif tonumber(#members) > 1 and tonumber(#members) < 5 then
			add = u8'сотрудникa'
		elseif tonumber(#members) >= 5 then
			add = u8'сотрудников'
		end
		
		imgui.Begin(fa.BUILDING_SHIELD .. " " ..  u8(members_fraction) .. " - " .. #members .. ' ' .. add .. u8' онлайн', MembersWindow, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize )

		
		for i, v in ipairs(members) do

			imgui.Columns(3)
			
			local r, g, b
			if v.working then r, g, b = 255, 255, 255 else r, g, b = 255, 59, 59 end
			local imgui_RGBA = imgui.ImVec4(r / 255.0, g / 255.0, b / 255.0, 1)
			
			if tonumber(v.afk) > 0 and tonumber(v.afk) < 60 then
				imgui.CenterColumnColorText(imgui_RGBA, u8(v.nick) .. ' [' .. v.id .. '] [AFK ' .. v.afk .. 's]')
			elseif tonumber(v.afk) >= 60 then
				imgui.CenterColumnColorText(imgui_RGBA, u8(v.nick) .. ' [' .. v.id .. '] [AFK ' .. math.floor( tonumber(v.afk) / 60 ) .. 'm]')
			else
				imgui.CenterColumnColorText(imgui_RGBA, u8(v.nick) .. ' [' .. v.id .. ']')
			end
			
			imgui.SetColumnWidth(-1, 310 * MONET_DPI_SCALE)
			imgui.NextColumn()
			imgui.CenterColumnText(u8(v.rank) .. ' (' .. u8(v.rank_number) .. ')')
			imgui.SetColumnWidth(-1, 220 * MONET_DPI_SCALE)
			imgui.NextColumn()
			imgui.CenterColumnText(u8(v.warns .. '/3'))
			imgui.SetColumnWidth(-1, 75 * MONET_DPI_SCALE)
			imgui.Columns(1)
			imgui.Separator()
				
		end
		
		imgui.End()
		
    end
)

local FastHealMenu = imgui.OnFrame(
    function() return FastHealMenu[0] end,
    function(player)
	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY - 60), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		
		imgui.Begin(fa.HOSPITAL.." Hospital Helper##fast_heal", FastHealMenu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize  )
		
		local width = imgui.GetWindowWidth()
		local calc = imgui.CalcTextSize(fa.KIT_MEDICAL..u8' Вылечить '..sampGetPlayerNickname(heal_in_chat_player_id))
		
		if heal_in_chat then
			if imgui.Button(fa.KIT_MEDICAL..u8' Вылечить '..sampGetPlayerNickname(heal_in_chat_player_id)) then
				command("/heal #arg_id",heal_in_chat_player_id)
				heal_in_chat = false
				heal_in_chat_id = nil
				FastHealMenu[0] = false
			end
		end
		
		imgui.End()
		
    end
)

function imgui.Link(link, text)
    text = text or link
    local tSize = imgui.CalcTextSize(text)
    local p = imgui.GetCursorScreenPos()
    local DL = imgui.GetWindowDrawList()
    local col = { 0xFFFF7700, 0xFFFF9900 }
    if imgui.InvisibleButton("##" .. link, tSize) then os.execute("explorer " .. link) end
    local color = imgui.IsItemHovered() and col[1] or col[2]
    DL:AddText(p, color, text)
    DL:AddLine(imgui.ImVec2(p.x, p.y + tSize.y), imgui.ImVec2(p.x + tSize.x, p.y + tSize.y), color)
end
function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end
function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end
function imgui.CenterColumnTextDisabled(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.TextDisabled(text)
end
function imgui.CenterColumnColorText(imgui_RGBA, text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
	imgui.TextColored(imgui_RGBA, text)
end
function imgui.CenterColumnInputText(text,v,size)

	if text:find('^(.+)##(.+)') then
		local text1, text2 = text:match('(.+)##(.+)')
		imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - (imgui.CalcTextSize(text1).x / 2) - (imgui.CalcTextSize(v).x / 2 ))
	elseif text:find('^##(.+)') then
		imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2) ) - (imgui.CalcTextSize(v).x / 2 ) )
	else
		imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - (imgui.CalcTextSize(text).x / 2) - (imgui.CalcTextSize(v).x / 2 ))
	end   
	
	if imgui.InputText(text,v,size) then
		return true
	else
		return false
	end
	
end
function imgui.CenterColumnButton(text)

	if text:find('(.+)##(.+)') then
		local text1, text2 = text:match('(.+)##(.+)')
		imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text1).x / 2)
	else
		imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
	end
	
    if imgui.Button(text) then
		return true
	else
		return false
	end
end
function imgui.CenterColumnSmallButton(text)

	if text:find('(.+)##(.+)') then
		local text1, text2 = text:match('(.+)##(.+)')
		imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text1).x / 2)
	else
		imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
	end
	
    if imgui.SmallButton(text) then
		return true
	else
		return false
	end
	
end
function imgui.CenterTextDisabled(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.TextDisabled(text)
end

function dark_theme()

	imgui.SwitchContext()
    imgui.GetStyle().WindowPadding = imgui.ImVec2(5 * MONET_DPI_SCALE, 5 * MONET_DPI_SCALE)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5 * MONET_DPI_SCALE, 5 * MONET_DPI_SCALE)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5 * MONET_DPI_SCALE, 5 * MONET_DPI_SCALE)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2 * MONET_DPI_SCALE, 2 * MONET_DPI_SCALE)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
    imgui.GetStyle().IndentSpacing = 0
    imgui.GetStyle().ScrollbarSize = 10 * MONET_DPI_SCALE
    imgui.GetStyle().GrabMinSize = 10 * MONET_DPI_SCALE
    imgui.GetStyle().WindowBorderSize = 1 * MONET_DPI_SCALE
    imgui.GetStyle().ChildBorderSize = 1 * MONET_DPI_SCALE
    imgui.GetStyle().PopupBorderSize = 1 * MONET_DPI_SCALE
    imgui.GetStyle().FrameBorderSize = 1 * MONET_DPI_SCALE
    imgui.GetStyle().TabBorderSize = 1 * MONET_DPI_SCALE
	imgui.GetStyle().WindowRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().ChildRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().FrameRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().PopupRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().ScrollbarRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().GrabRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().TabRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    
    imgui.GetStyle().Colors[imgui.Col.Text]                   = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Border]                 = imgui.ImVec4(0.25, 0.25, 0.26, 0.54)
    imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.51, 0.51, 0.51, 1.00)
    imgui.GetStyle().Colors[imgui.Col.CheckMark]              = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Button]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Header]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Separator]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = imgui.ImVec4(0.07, 0.10, 0.15, 0.97)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(1.00, 0.00, 0.00, 0.35)
    imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
    imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
    imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.12, 0.12, 0.12, 0.95)
	
	
	
end

if isMonetLoader() then 

	local ml = require("monetloader")
	local touch_events = ml.touch_events

	local lastClick = nil
	local lastClickTime = nil
	local doubleClickThreshold = 0.5
	local clickRadius = 10
	
	function onTouch(type, id, x, y)
	
		--sampAddChatMessage(""..x..","..y.." "..type, -1)
		
		local currentTime = os.clock()

		if type == touch_events.PUSH and lastClick ~= nil and distance(lastClick, {x,y}) <= clickRadius and currentTime - lastClickTime <= doubleClickThreshold then
		
			local px,py,pz = convertScreenCoordsToWorld3D(x,y, 5)
			local x2, y2, z2 = getCharCoordinates(PLAYER_PED)
			local dist = getDistanceBetweenCoords3d(px, py, pz, x2, y2, z2)

			if (dist < 15) then
				local id = getNearestPlayerByCoordinates(px,py,pz, 2)

				if id ~= nil then
					show_fast_menu(id)
				end
			end
			lastClick = nil
			lastClickTime = nil
			
		elseif type == touch_events.PUSH then
			lastClick = {x,y}
			lastClickTime = currentTime
		end
	end
	
	function getNearestPlayerByCoordinates(x, y, z, maxDistance)
		local nearestPlayerId = nil
		local minDist = nil
		if maxDistance == nil then maxDistance = math.huge end

		for k, ped in pairs(getAllChars()) do
			local px, py, pz = getCharCoordinates(ped)
			local dist = getDistanceBetweenCoords3d(x, y, z, px, py, pz)
			if dist ~= 0 and dist <= maxDistance and (minDist == nil or dist < minDist) then
				local res, id = sampGetPlayerIdByCharHandle(ped)
				if res then
					minDist = dist
					nearestPlayerId = id
				end
			end
		end

		return nearestPlayerId
	end

	function distance(point1, point2)
		local dx = point1[1] - point2[1]
		local dy = point1[2] - point2[2]
		return math.sqrt(dx*dx + dy*dy)
	end

end

function onScriptTerminate(script, game_quit)

    if script == thisScript() and not game_quit and not reset_settings_bool then
		
		sampAddChatMessage('[Hospital Helper] {ffffff}Произошла неизвестная ошибка, хелпер приостановил свою работу!', message_color)
		
		if not isMonetLoader() then 
			sampAddChatMessage('[Hospital Helper] {ffffff}Используйте {00ccff}CTRL {ffffff}+ {00ccff}R {ffffff}чтобы перезапустить хелпер.', message_color)
		end
		
		play_error_sound()
		
    end
	
end