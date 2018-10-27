local tiled = Entity.wrapp(ygGet("tiled"))
local jrpg_fight = Entity.wrapp(ygGet("jrpg-fight"))
local dialogue_box = Entity.wrapp(ygGet("DialogueBox"))
local lpcs = Entity.wrapp(ygGet("lpcs"))
local phq = Entity.wrapp(ygGet("phq"))
local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local npcs = Entity.wrapp(ygGet("phq.npcs"))
local scenes = Entity.wrapp(ygGet("phq.scenes"))
saved_scenes = nil
dialogues = Entity.new_array()
o_dialogues = nil
local window_width = 800
local window_height = 600
local pj_pos = nil

local PIX_PER_FRAME = 6
local TURN_LENGTH = 20000

local NO_COLISION = 0
local NORMAL_COLISION = 1
local CHANGE_SCENE_COLISION = 2
local PHQ_SUP = 0
local PHQ_INF = 1

local LPCS_LEFT = 9
local LPCS_DOWN = 10
local LPCS_RIGHT = 11
local LPCS_UP = 8

DAY_STR = {"monday", "tuesday", "wensday", "thursday",
	   "friday", "saturday", "sunday"}

local function dressUp(caracter)
   if caracter.equipement == nil then
      return
   end
   local e = caracter.equipement
   local objs = phq.objects
   caracter.clothes = nil
   local clothes = Entity.new_array(caracter, "clothes")

   if e.feet then
      local cur_o = objs[yeGetString(e.feet)]
      if (cur_o.path) then
	 yeCreateString(cur_o.path:to_string(), clothes)
      end
   end
   if e.torso then
      local cur_o = objs[yeGetString(e.torso)]
      if (cur_o.path) then
	 yeCreateString(cur_o.path:to_string(), clothes)
      end
   end
   if caracter.hair then
      yeCreateString("hair/" .. caracter.sex:to_string() .. "/" ..
		     caracter.hair[0]:to_string() .. "/" ..
		     caracter.hair[1]:to_string() .. ".png",
		     clothes)
   end
end

local function reposScreenInfo(ent, x0, y0)
   ywCanvasObjSetPos(ent.night_r, x0, y0)
   ywCanvasObjSetPos(ent.life_txt, x0 + 360, y0 + 10)
   ywCanvasObjSetPos(ent.life_nb, x0 + 410, y0 + 10)
   dialogue_box.set_pos(ent.box, 40 + x0, 40 + y0)
end

local function reposeCam(main)
   local canvas = main.mainScreen
   local upCanvas = main.upCanvas
   local pjPos = Pos.wrapp(ylpcsHandePos(main.pj))
   local x0 = pjPos:x() - window_width / 2
   local y0 = pjPos:y() - window_height / 2

   ywPosSet(canvas.cam, x0, y0)
   ywPosSet(upCanvas.cam, x0, y0)
   reposScreenInfo(main, x0, y0)
end


function checkNpcPresence(obj, npc, scene)
   if npc == nil then
      return false
   end
   local cur_time = phq.env.time:to_string()
   local obj_time = obj.Time

   if obj_time then
      print(yeStrCaseCmp(obj_time, cur_time), yeGetString(obj_time), cur_time)
      if yeStrCaseCmp(obj_time, cur_time) ~= 0 then
	 return false
      end
   end

   print("checkNpcPresence", npc.calendar)
   if npc.calendar then
      local day_calenday = npc.calendar[DAY_STR[phq.env.day:to_int() + 1]]
      print(day_calenday, yeType(day_calenday))
      if day_calenday == nil then
	 day_calenday = npc.calendar.everyday
      end
      if yeType(day_calenday) == YSTRING then
	 return yeGetString(day_calenday) == scene
      elseif day_calenday ~= nil then
	 return yeGetString(day_calenday[cur_time]) == scene
      end
      return false
   end
   return true
end

function init_phq(mod)
   Widget.new_subtype("phq", "create_phq")
   Widget.new_subtype("phq-new-game", "create_new_game")

   mod = Entity.wrapp(mod)
   mod.backToGame = Entity.new_func("backToGame")
   mod.StartFight = Entity.new_func("StartFight")
   mod.DrinkBeer = Entity.new_func("DrinkBeer")
   mod.openStore = Entity.new_func("openStore")
   mod.GetDrink = Entity.new_func("GetDrink")
   mod.load_game = Entity.new_func("load_game")
   mod.continue = Entity.new_func("continue")
   mod.newGame = Entity.new_func("newGame")
   mod.printMessage = Entity.new_func("printMessage")
   mod.sleep = Entity.new_func("sleep")
   mod.actionOrPrint = Entity.new_func("actionOrPrint")
   mod.startDialogue = Entity.new_func("startDialogue")
   mod.playSnake = Entity.new_func("playSnake")
   mod.playAstShoot = Entity.new_func("playAstShoot")
   mod.playVapp = Entity.new_func("playVapp")
   mod.pay = Entity.new_func("pay")
   mod.takeObject = Entity.new_func("takeObject")
   mod.PjLeave = Entity.new_func("PjLeave")
   mod.vnScene = Entity.new_func("vnScene")
   mod.increase = Entity.new_func("increase")
   mod.recive = Entity.new_func("recive")
end

function load_game(entity, save_dir)
   local game = ygGet("phq:menus.game")
   game = Entity.wrapp(game)
   game.saved_dir = save_dir
   game.saved_data = ygFileToEnt(YJSON, save_dir.."/misc.json")
   yeDestroy(game.saved_data)
   local pj = ygFileToEnt(YJSON, save_dir.."/pj.json")
   phq.pj = pj
   yeDestroy(pj)
   local env = ygFileToEnt(YJSON, save_dir.."/env.json")
   pj_pos = ygFileToEnt(YJSON, save_dir.."/pj-pos.json")
   saved_scenes = Entity._wrapp_(ygFileToEnt(YJSON,
					       save_dir.."/saved-scenes.json"),
				   true)
   phq.env = env
   local events = File.jsonToEnt(save_dir.."/evenements.json")
   phq.events = events
   yeDestroy(env)
   --local tmp = ygFileToEnt(YJSON, save_dir.."/npcs.json")
   yCallNextWidget(entity);
end

function continue(entity)
   return load_game(entity, "./saved/cur")
end

function saveCurDialogue(main)
   saved_scenes[main.cur_scene_str:to_string()] = {}
   saved_scenes[main.cur_scene_str:to_string()].o = main.mainScreen.objects
   local p = yePatchCreate(o_dialogues, dialogues)
   saved_scenes[main.cur_scene_str:to_string()].d = Entity.wrapp(p)
   yeDestroy(p)
end

function saveGame(main, saveDir)
   print(saveDir)
   local destDir = "./saved/" .. saveDir
   local misc = Entity.new_array()

   yuiMkdir("./saved")
   yuiMkdir(destDir)
   misc.cur_scene_str = main.cur_scene_str
   saveCurDialogue(main)
   ygEntToFile(YJSON, destDir .. "/pj-pos.json", ylpcsHandePos(main.pj))
   --ygEntToFile(YJSON, destDir .. "/npcs.json", npcs)
   ygEntToFile(YJSON, destDir .. "/pj.json", phq.pj)
   ygEntToFile(YJSON, destDir .. "/evenements.json", phq.events)
   ygEntToFile(YJSON, destDir .. "/misc.json", misc)
   ygEntToFile(YJSON, destDir .. "/env.json", phq.env)
   ygEntToFile(YJSON, destDir .. "/saved-scenes.json", saved_scenes)
end

function saveGameCallback(wid)
   saveGame(Entity.wrapp(ywCntWidgetFather(wid)), "cur")
end

function checkTiledCondition(actionable)
   local conditionOp = actionable.Condition

   if conditionOp == nil then
      return true
   end
   local condition = Entity.new_array()
   yeCreateString(yeGetString(conditionOp), condition);
   yePushBack(condition, yeGet(actionable, "ConditionArg0"));
   yePushBack(condition, yeGet(actionable, "ConditionArg1"));
   local ret = yeCheckCondition(condition);
   return ret
end

function CheckColisionTryChangeScene(main, cur_scene, direction)
   if cur_scene.out and cur_scene.out[direction] then
      local dir_info = cur_scene.out[direction]
      local nextSceneTxt = nil
      if dir_info.to then
	 nextSceneTxt = yeGetString(yeToLower(dir_info.to))
      else
	 nextSceneTxt = yeGetString(yeToLower(dir_info))
      end
      load_scene(main, nextSceneTxt, yeGetIntAt(dir_info, "entry"))
      return true
   end
   return false
end

local function CheckColisionExit(col, ret)
   yeDestroy(col)
   return ret
end

function CheckColision(main, canvasWid, pj)
   local pjPos = ylpcsHandePos(pj)
   local colRect = ywRectCreate(ywPosX(pjPos) + 10, ywPosY(pjPos) + 30,
			       20, 20)
   local col = ywCanvasNewCollisionsArrayWithRectangle(canvasWid, colRect)

   col = Entity.wrapp(col)
   local i = 0
   while i < yeLen(main.exits) do
      local rect = main.exits[i].rect
      if ywRectCollision(rect, colRect) then
	 local nextSceneTxt = yeGetString(yeToLower(main.exits[i].nextScene))
	 load_scene(main, nextSceneTxt, yeGetInt(main.exits[i].entry))
	 yeDestroy(colRect)
	 return CheckColisionExit(col, CHANGE_SCENE_COLISION)
      end
      i = i + 1
   end
   yeDestroy(colRect)

   local cur_scene = main.cur_scene
   if ywPosX(pjPos) < 0 then
      if CheckColisionTryChangeScene(main, cur_scene, "left") then
	 return CheckColisionExit(col, CHANGE_SCENE_COLISION)
      else
	 return CheckColisionExit(col, NORMAL_COLISION)
      end
   elseif ywPosY(pjPos) + 30 < 0 then
      if CheckColisionTryChangeScene(main, cur_scene, "up") then
	 return CheckColisionExit(col, CHANGE_SCENE_COLISION)
      else
	 return CheckColisionExit(col, NORMAL_COLISION)
      end
   elseif ywPosX(pjPos) + lpcs.w_sprite > canvasWid["tiled-wpix"]:to_int() then
      if CheckColisionTryChangeScene(main, cur_scene, "right") then
	 return CheckColisionExit(col, CHANGE_SCENE_COLISION)
      else
	 return CheckColisionExit(col, NORMAL_COLISION)
      end
   elseif ywPosY(pjPos) + lpcs.h_sprite > canvasWid["tiled-hpix"]:to_int() then
      if CheckColisionTryChangeScene(main, cur_scene, "down") then
	 return CheckColisionExit(col, CHANGE_SCENE_COLISION)
      else
	 return CheckColisionExit(col, NORMAL_COLISION)
      end
   end

   i = 0
   while i < yeLen(col) do
      local obj = col[i]
      if yeGetIntAt(obj, "Collision") == 1 then
	 return CheckColisionExit(col, NORMAL_COLISION)
      end
      i = i + 1
   end
   return CheckColisionExit(col, NO_COLISION)
end

function pushMainMenu(main)
   local mn = Menu.new_entity()

   mn:push("back to game", Entity.new_func("backToGame"))
   mn:push("status", Entity.new_func("pushStatus"))
   mn:push("inventory", Entity.new_func("invList"))
   mn:push("save game", Entity.new_func("saveGameCallback"))
   mn:push("main menu", "callNext")
   mn.ent.background = "rgba: 255 255 255 190"
   mn.ent["text-align"] = "center"
   mn.ent.next = main.next
   ywPushNewWidget(main, mn.ent)
end

function phq_action(entity, eve, arg)
   entity = Entity.wrapp(entity)
   entity.tid = entity.tid + 1
   eve = Event.wrapp(eve)
   local st_hooks = entity.st_hooks
   local st_hooks_len = yeLen(entity.st_hooks)

   if yeGetInt(entity.current) > 1 then
      return NOTHANDLE
   end

   local i = 0
   while i < st_hooks_len do
      local st_hook = st_hooks[i]
      local stat_name = yeGetKeyAt(st_hooks, i)
      local stat = phq.pj[stat_name]

      if stat then
	 local cmp_t = st_hook.comp_type
	 if (cmp_t:to_int() == 0 and stat > st_hook.val) or
	 (cmp_t:to_int() == 1 and stat < st_hook.val) then
	    print(yeGetKeyAt(st_hooks, i),
		  st_hook.val, st_hook.comp_type)
	    st_hook.hook(ent)
	 end
      end
      i = i + 1
   end
   if entity.box_t then
      if entity.box_t > 100 then
	 dialogue_box.rm(entity.upCanvas, entity.box)
	 entity.box = nil
	 entity.box_t = nil
      else
	 entity.box_t = entity.box_t + 1
      end
   elseif entity.sleep then
      if doSleep(entity, Canvas.wrapp(entity.upCanvas)) == false then
	 return YEVE_ACTION
      end
   end
   NpcTurn(entity)
   while eve:is_end() == false do
       if eve:type() == YKEY_DOWN then
	  if eve:key() == Y_ESC_KEY then
	     pushMainMenu(entity)
	     return YEVE_ACTION
	  elseif eve:is_key_up() then
             entity.pj.move.up_down = -1
             entity.pj.y = LPCS_UP
	  elseif eve:is_key_down() then
             entity.pj.move.up_down = 1
             entity.pj.y = LPCS_DOWN
	  elseif eve:is_key_left() then
             entity.pj.move.left_right = -1
             entity.pj.y = LPCS_LEFT
	  elseif eve:is_key_right() then
             entity.pj.move.left_right = 1
             entity.pj.y = LPCS_RIGHT
	  elseif eve:key() == Y_M_KEY then
	     pushMetroMenu(entity)
	     return YEVE_ACTION
          elseif eve:key() == Y_SPACE_KEY or eve:key() == Y_ENTER_KEY then
             local pjPos = ylpcsHandePos(entity.pj)
             local x_add = 0
             local y_add = 0

             pjPos = Pos.wrapp(pjPos)
             if entity.pj.y:to_int() == LPCS_UP then
                y_add = -25
                x_add = lpcs.w_sprite / 2
             elseif entity.pj.y:to_int() == LPCS_LEFT then
                x_add = -25
                y_add = lpcs.h_sprite / 2
             elseif entity.pj.y:to_int() == LPCS_DOWN then
                y_add = lpcs.h_sprite + 20
                x_add = lpcs.w_sprite / 2
             else
                y_add = lpcs.h_sprite / 2
                x_add = lpcs.w_sprite + 20
             end
             local r = Rect.new(pjPos:x() + x_add, pjPos:y() + y_add, 10, 10)
	     local e_actionables = entity.actionables
             local i = 0

	     while  i < yeLen(e_actionables) do
		if ywRectCollision(r.ent, e_actionables[i].rect) and
		checkTiledCondition(e_actionables[i]) then
		   local args = { e_actionables[i].Arg0, e_actionables[i].Arg1,
				  e_actionables[i].Arg2, e_actionables[i].Arg3 }

		   return yesCall(ygGet(e_actionables[i].Action:to_string()),
				  entity:cent(), e_actionables[i]:cent(), args[1],
				  args[2], args[3], args[4])
		end
		i = i + 1
	     end

	     local col = ywCanvasNewCollisionsArrayWithRectangle(entity.mainScreen, r:cent())
             col = Entity.wrapp(col)
             --print("action !", Pos.wrapp(pjPos.ent):tostring(), Pos.wrapp(r.ent):tostring(), yeLen(col))
	     i = 0
             while i < yeLen(col) do
                local dialogue = col[i].dialogue
		if startDialogue(entity, col[i], dialogue) == YEVE_ACTION then
		   yeDestroy(col)
		   return YEVE_ACTION
		end
                i = i + 1
             end
             yeDestroy(col)
	  end

        elseif eve:type() == YKEY_UP then
	  if eve:is_key_up() then
	     entity.pj.move.up_down = 0
	  elseif eve:is_key_down() then
	     entity.pj.move.up_down = 0
	  elseif eve:is_key_left() then
	     entity.pj.move.left_right = 0
	  elseif eve:is_key_right() then
	     entity.pj.move.left_right = 0
          end
          entity.pj.x = 0
       end
       eve = eve:next()
   end

   walkDoStep(entity, entity.pj)

   local mvPos = Pos.new(PIX_PER_FRAME * entity.pj.move.left_right,
			 PIX_PER_FRAME * entity.pj.move.up_down)
    ylpcsHandlerMove(entity.pj, mvPos.ent)
    local col_rel = CheckColision(entity, entity.mainScreen, entity.pj)
    if col_rel == NORMAL_COLISION then
       mvPos:opposite()
       ylpcsHandlerMove(entity.pj, mvPos.ent)
    end
    reposeCam(entity)
    return YEVE_ACTION
end

function destroy_phq(entity)
   local ent = Entity.wrapp(entity)

   tiled.deinit()
   ent.mainScreen = nil
   ent.upCanvas = nil
   ent.current = 0
end

function load_scene(ent, sceneTxt, entryIdx)
   local mainCanvas = Canvas.wrapp(ent.mainScreen)
   local upCanvas = Canvas.wrapp(ent.upCanvas)
   local x = 0
   local y = 0

   if ent.cur_scene_str then
      saveCurDialogue(ent)
   end

   ent.npc_act = {}
   ent.cur_scene_str = sceneTxt
   local scene = scenes[sceneTxt]

   scene = Entity.wrapp(scene)

   -- clean old stuff :(
   upCanvas.ent.objs = {}
   upCanvas.ent.cam = Pos.new(0, 0).ent
   mainCanvas.ent.objs = {}
   mainCanvas.ent.objects = {}
   tiled.fileToCanvas(scene.tiled:to_string(), mainCanvas.ent:cent(),
		      upCanvas.ent:cent())
   o_dialogues = File.jsonToEnt(yeGetString(scene.dialogues))
   yeCopy(o_dialogues, dialogues)
   if saved_scenes[ent.cur_scene_str:to_string()] then
      ent.mainScreen.objects = saved_scenes[ent.cur_scene_str:to_string()].o
      local patch = saved_scenes[ent.cur_scene_str:to_string()].d
      if (yeType(patch) == YARRAY) then
	 yePatchAply(dialogues, patch)
      end
      tmpp = yePatchCreate(o_dialogues, dialogues)
   end
   mainCanvas.ent.cam = Pos.new(0, 0).ent
   -- Pj info:

   local objects = ent.mainScreen.objects
   local i = 0
   local npc_idx = 0
   local j = 0
   local k = 0
   ent.npcs = {}
   ent.exits = {}
   ent.actionables = {}
   ent.cur_scene = scene
   local e_npcs = ent.npcs
   local e_exits = ent.exits
   local e_actionables = ent.actionables
   while i < yeLen(objects) do
      local obj = objects[i]
      local layer_name = obj.layer_name
      local npc = npcs[yeGetString(yeGet(obj, "name"))]

      if layer_name:to_string() == "NPC" and
	 checkNpcPresence(obj, npc, sceneTxt) then

	 dressUp(npc)
	 npc = lpcs.createCaracterHandler(npc, mainCanvas.ent, e_npcs)
	 --print("obj (", i, "):", obj, npcs[obj.name:to_string()], obj.rect)
	 local pos = Pos.new_copy(obj.rect)
	 pos:sub(20, 50)
	 lpcs.handlerMove(npc, pos.ent)
	 if yeGetString(obj.Rotation) == "left" then
	    lpcs.handlerSetOrigXY(npc, 0, LPCS_LEFT)
	 elseif yeGetString(obj.Rotation) == "right" then
	    lpcs.handlerSetOrigXY(npc, 0, LPCS_RIGHT)
	 elseif yeGetString(obj.Rotation) == "down" then
	    lpcs.handlerSetOrigXY(npc, 0, LPCS_DOWN)
	 else
	    lpcs.handlerSetOrigXY(npc, 0, LPCS_UP)
	 end
	 lpcs.handlerRefresh(npc)
	 npc = Entity.wrapp(npc)
	 npc.canvas.Collision = 1
	 npc.canvas.is_npc = 1
	 npc.char.name = obj.name:to_string()
	 npc.canvas.dialogue = obj.name:to_string()
	 npc.canvas.current = npc_idx
	 npc_idx = npc_idx + 1
      elseif layer_name:to_string() == "Entries" then
	 e_exits[j] = obj
	 j = j + 1
      elseif layer_name:to_string() == "Actionable" then
	 e_actionables[k] = obj
	 k = k + 1
      end
      i = i + 1
   end
   print("4")

   if entryIdx < 0 or e_exits[entryIdx] == nil then
      x = 300
      y = 200
   else
      local rect = e_exits[entryIdx].rect
      local side = yeGetString(e_exits[entryIdx].side)
      x = ywRectX(rect)
      y = ywRectY(rect)
      if side == "up" then
	 y = y - 75
      elseif side == "down" then
	 y = y + ywRectH(rect) + 15
      elseif side == "left" then
	 x = x - 45
      else
	 x = x + ywRectW(rect) + 45
      end
   end
   print("5")
   if pj_pos then
      ylpcsHandlerSetPos(ent.pj, pj_pos)
      yeDestroy(pj_pos)
      pj_pos = nil
   else
      ylpcsHandlerSetPos(ent.pj, Pos.new(x, y).ent)
   end
   lpcs.handlerSetOrigXY(ent.pj, 0, 10)
   lpcs.handlerRefresh(ent.pj)

   if scene.exterior and phq.env.time:to_string() == "night" then
      ent.night_r = upCanvas:new_rect(0, 0, "rgba: 0 0 26 127",
				      Pos.new(window_width,
					      window_height).ent).ent
   end
   print("6")

   ent.life_txt = ywCanvasNewTextExt(upCanvas.ent, 360, 10,
				     Entity.new_string("life: "),
				     "rgba: 255 255 255 255")
   upCanvas:remove(ent.life_nb )
   ent.life_nb = ywCanvasNewTextExt(upCanvas.ent, 410, 10,
				    Entity.new_string(math.floor(phq.pj.life:to_int())),
				    "rgba: 255 255 255 255")
   reposeCam(ent)
   print("7")
end

function add_stat_hook(entity, stat, hook, val, comp_type)
   print("ADDD !!")
   entity.st_hooks[stat] = {}
   entity.st_hooks[stat].hook = ygGet(hook)
   entity.st_hooks[stat].val = val
   entity.st_hooks[stat].comp_type = comp_type
end

function create_phq(entity)
    local container = Container.init_entity(entity, "stacking")
    local ent = container.ent
    local scenePath = nil

    ent.tid = 0
    ent.cur_scene_str = nil
    tiled.setAssetPath("./tileset");
    jrpg_fight.objects = phq.objects
    print("jrpg_fight.objects", jrpg_fight.objects)

    ent.st_hooks = {}
    add_stat_hook(ent, "drunk", "FinishGame", 99, PHQ_SUP)
    add_stat_hook(ent, "life", "FinishGame", 0, PHQ_INF)
    yJrpgFightSetCombots("phq.combots")
    if ent.saved_data then
       print(ent.saved_data)
       scenePath = ent.saved_data.cur_scene_str
    else
       scenePath = Entity.new_string("house1")
    end
    Entity.new_func("phq_action", ent, "action")
    local mainCanvas = Canvas.new_entity(entity, "mainScreen")
    local upCanvas = Canvas.new_entity(entity, "upCanvas")
    ent["turn-length"] = TURN_LENGTH
    ent.entries = {}
    ent.background = "rgba: 127 127 127 255"
    ent.entries[0] = mainCanvas.ent
    ent.entries[1] = upCanvas.ent
    local ret = container:new_wid()
    ent.destroy = Entity.new_func("destroy_phq")
    ent.soundcallgirl = ySoundLoad("./callgirl.mp3")
    ent.pj = nil
    dressUp(phq.pj)
    lpcs.createCaracterHandler(phq.pj, mainCanvas.ent, ent, "pj")
    load_scene(ent, yeGetString(yeToLower(scenePath)), 0)
    ent.pj.move = {}
    ent.pj.move.up_down = 0
    ent.pj.move.left_right = 0
    return ret
end
