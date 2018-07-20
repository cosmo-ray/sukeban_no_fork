local phq = Entity.wrapp(ygGet("phq"))

local geekDescription = "I do undersatdn this 'mouse magic'\nthat make me thine bidding"
local idoleDescription = "You need a new tailor,  your clothes are absolutely dreadful!"
local bruteDescription = "So I kicked him in the head 'til he was dead. Mahahahahaha!"
local wormsCoinoisseurDescription = "Surface-dwellers can be so stupid !"
local descArray = {geekDescription, idoleDescription,
		   bruteDescription, wormsCoinoisseurDescription}
local GEEK_ARCHETYPE = 0
local IDOLE_ARCHETYPE = 1
local BRUTE_ARCHETYPE = 2
local WORMS_COINOISSEUR_ARCHETYPE = 3

function newGameAction(menu, eve, arg)
   local game = Entity.wrapp(ygGet("phq:menus.game"))
   game.saved_data = nil
   game.saved_dir = nil
   local archetype = ywMenuGetCurrent(menu)
   phq.pj.stats = {}
   phq.pj.knowledge = {}
   phq.pj.drunk = 0
   phq.pj.stats.charisme = 0
   phq.pj.stats.strength = 0
   phq.pj.stats.smart = 0
   phq.pj.archetype = archetype
   phq.pj.life = phq.pj.max_life
   saved_scenes = Entity.new_array()
   if archetype == GEEK_ARCHETYPE then
      phq.pj.knowledge.computer = 5
      phq.pj.knowledge.animu = 5
      phq.pj.stats.smart = 3
   elseif archetype == IDOLE_ARCHETYPE then
      phq.pj.knowledge.fashion = 5
      phq.pj.stats.charisme = 3
      phq.pj.stats.strength = 1
   elseif archetype == BRUTE_ARCHETYPE then
      phq.pj.knowledge.slang = 5
      phq.pj.stats.charisme = 1
      phq.pj.stats.strength = 3
   elseif archetype == WORMS_COINOISSEUR_ARCHETYPE then
      phq.pj.knowledge.worms = 5
      phq.pj.stats.smart = 1
   end
   yesCall((ygGet("callNext")), menu);
end

function newGameMoveOn(menu, current, cur_entry)
   local tx = ywCntGetEntry(ywCntWidgetFather(menu), 1)
   current = yLovePtrToNumber(current)
   yeSetString(yeGet(tx, "text"), descArray[current + 1])
   return YEVE_NOACTION;
end

function create_new_game(entity)
   local container = Container.init_entity(entity, "vertical")
   entity = Entity.wrapp(entity)
   entity.background = "rgba: 127 127 127 255"
   entity.entries = {}
   entity.entries[0] = {}
   local mn = entity.entries[0]
   mn.size = 30
   mn["<type>"] = "menu"
   mn.next = "phq:menus.game"
   mn.moveOn = Entity.new_func("newGameMoveOn")
   mn.entries = {}
   mn.entries[0] = {}
   mn.entries[0].text = "Geek"
   mn.entries[0].action = Entity.new_func("newGameAction")
   mn.entries[1] = {}
   mn.entries[1].text = "Idole"
   mn.entries[1].action = Entity.new_func("newGameAction")
   mn.entries[2] = {}
   mn.entries[2].text = "Brute"
   mn.entries[2].action = Entity.new_func("newGameAction")
   mn.entries[3] = {}
   mn.entries[3].text = "Worms Conoisseur"
   mn.entries[3].action = Entity.new_func("newGameAction")
   entity.entries[1] = {}
   local txt = entity.entries[1]
   txt["<type>"] = "text-screen"
   txt.text = geekDescription
   local ret = container:new_wid()
   return ret
end