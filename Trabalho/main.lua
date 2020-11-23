-- title:  Coronga;
-- author: Douglas, Richard e Otavio;
-- desc: RPG acao 2d;
-- script: lua.

local CAM_W = 240
local CAM_H = 136
local CELL = 8
local DRAW_X = 120
local DRAW_Y = 64
local CENTER_WIDTH = (CAM_W/2-30)
local CENTER_HEIGHT = (CAM_H/2-18)
local t = 0

local states_enemy = {
	STOP = "STOP",
	PURSUIT = "PURSUIT"
}

local tiles = {
	PLAYER = 260,
	BOX = 232,
	DOOR = 96,
	ENEMY = 292,
	ALCOOL = 384,
	MASK = 352,
	HEART = 360,
	NPC = 416,
	END_GAME = 1,
	HEALTH = 365,
	SHIELD = 381,
	COIN = 416,
	EMPTY_H_S = 380,
	TITLE = 352,
	TITLE_LENGTH = 12,
	TITLE_HEIGHT = 4
}

local sound_effects = {
	DOOR = 1,
	INIT = 3,
	SWORD = 4,
	END_GAME = 5
}

local const_direction = {
	UP = 1,
	DOWN = 2,
	LEFT = 3,
	RIGHT = 4
}

local constants = {
	VIEW_ENEMY = 50,
	SPEED_ENEMY = 0.5,

	ABOUT = "Desenvolvido por Douglas, Richard, Otavio.",

	SCORE = "Pontos: ",
	COINS_PLAYER = "Moedas: ",

	ENEMY = "ENEMY",
	PLAYER = "PLAYER",
	SWORD = "SWORD",
	COIN = "COIN",
	ALCOOL = "ALCOOL",
	MASK = "MASK",
	HEART = "HEART",
	NPC = "NPC",

	ROUND_1 = "ROUND_1",
	ROUND_2 = "ROUND_2",
	ROUND_3 = "ROUND_3",
	ROUND_4 = "ROUND_4",
	ROUND_5 = "ROUND_5",
}

local player = {}
local window = {}
local end_game = {}
local dialog = nil
local dialog_pos = 1
local text_pos = 1
local menu = {item = 0}

local round_actual = {}
local round_1 = {}
local round_2 = {}
local round_3 = {}
local round_4 = {}
local round_5 = {}


------------------------------------------
-- collision class
local function is_collision_objects(object_a, object_b)
	return math.abs(object_a.x - object_b.x) < CELL
		and math.abs(object_a.y - object_b.y) < CELL
end

local function start_dialog()
	if dialog ~= nil
  and dialog[dialog_pos] ~= nil then
	  local str = dialog[dialog_pos]
    local len = string.len(str)

		if btnp(5) and text_pos >= 2 then
		  if text_pos < len then
			  text_pos = len
		  else
			  text_pos = 1
			  dialog_pos = dialog_pos + 1
			end
		end

	  if dialog_pos <= #dialog then
		  rect(5, 105, 230, 30, 5)
			rectb(5, 105, 230, 30, 15)
		  print(
        string.sub(str, 1, text_pos),
        10,
        110,
        15,
        false,
        1,
        true
      )
			if text_pos < len and t % 4 == 0 then
				text_pos = text_pos + 1
			end
		else
		  dialog_pos = 1
			dialog = nil
		end

		if dialog	and dialog_pos == #dialog then
			if btnp(0) then
				menu.item = 0
			elseif btnp(1) then
				menu.item = 1
			end

			spr(364, 7, 115+menu.item*5, 14)

			if btnp(4) then
				if menu.item == 0 then
					if player.coins - 10 >= 0 then
						player.coins = player.coins - 10
						player.shield = player.shield + 2
					end
				elseif menu.item == 1 then
					if player.coins - 5 >= 0 then
						player.coins = player.coins - 5
						player.health = player.health + 1
					end
				end
			end
		end
	end
end

local function check_collision_objects(personal, newPosition, time)
	for _, npc in pairs(round_actual.Npcs) do
		if personal.tag == constants.PLAYER
		and is_collision_objects(newPosition, npc) then
		  return npc.make_collision_npc_with_player()
		end
	end

	for _, box in pairs(round_actual.Boxes) do
		if personal.tag == constants.PLAYER
		and is_collision_objects(newPosition, box) then
		  return box.make_collision_box_with_player(time)
		end
	end

	for i, enemy in pairs(round_actual.Enemies) do
		if is_collision_objects(newPosition, enemy) then
			if personal.tag == constants.PLAYER then
				return enemy.make_collision_enemy_with_player(i)
			elseif personal.tag == constants.SWORD then
				return enemy.make_collision_enemy_with_sword(i)
			end
		end
	end

	for _, door in pairs(round_actual.Doors) do
	  if personal.tag == constants.PLAYER
		and is_collision_objects(newPosition, door) then
		  return door.make_collision_door_with_player(time)
		end
	end

	for i, coin in pairs(round_actual.Coins) do
		if personal.tag == constants.PLAYER
		and is_collision_objects(newPosition, coin) then
			return coin.make_collision_coin_with_player(i)
		end
	end

	for i, alcool in pairs(round_actual.Alcools) do
		if personal.tag == constants.PLAYER
		and is_collision_objects(newPosition, alcool) then
			return alcool.make_collision_alcool_with_player(i)
		end
	end

	for i, heart in pairs(round_actual.Hearts) do
		if personal.tag == constants.PLAYER
		and is_collision_objects(newPosition, heart) then
			return heart.make_collision_heart_with_player(i)
		end
	end

	for i, mask in pairs(round_actual.Masks) do
		if personal.tag == constants.PLAYER
		and is_collision_objects(newPosition, mask) then
			return mask.make_collision_mask_with_player(i)
		end
	end

	if round_actual.next_round
	and is_collision_objects(newPosition, round_actual.next_round) then
		return round_actual.update_round()
	end

	return false
end

local function distancy(e, p)
	return math.max(math.abs(e.x-p.x), math.abs(e.y-p.y))
end

local function lerp(a, b, q)
	return (1 - q) * a + q * b
end

local function DisplayHUD()
	local h_s = 0

	print(constants.SCORE..player.score, 0, 0)

	for _ = 1, player.health do
		h_s = h_s + 1

		spr(
			tiles.HEALTH,
			CELL * (h_s - 1),
			CELL,
			14 -- cor de fundo
		)
	end

	for _ = 1, player.maxHealth - player.health do
		h_s = h_s + 1

		spr(
			tiles.EMPTY_H_S,
			CELL * (h_s - 1),
			CELL,
			14 -- cor de fundo
		)
	end

	h_s = 0

	for i = 1, player.shield do
		h_s = h_s + 1

		spr(
			tiles.SHIELD,
			CELL * (i - 1),
			CELL * 2,
			14 -- cor de fundo
		)
	end

	for _ = 1, player.maxShield - player.shield do
		h_s = h_s + 1

		spr(
			tiles.EMPTY_H_S,
			CELL * (h_s - 1),
			CELL * 2,
			14 -- cor de fundo
		)
	end

	if player.coins > 0 then
		print(constants.COINS_PLAYER..player.coins, CAM_W - (CELL * 7), 0)
	end
end

local function draw_map()
	local ccx = cam.x / CELL + (cam.x % CELL == 0 and 1 or 0)
	local ccy = cam.y / CELL + (cam.y % CELL == 0 and 1 or 0)

  map(
    15 - ccx,
    8 - ccy,
    31,
    18,
    (cam.x % CELL) - CELL,
    (cam.y % CELL) - CELL
	)
end

local function update_cam()
	cam.x = math.min(DRAW_X, lerp(cam.x, DRAW_X - player.x, 0.05))
  cam.y = math.min(DRAW_Y, lerp(cam.y, DRAW_Y - player.y, 0.05))
end

local function update_game(time)
	player.update(time)

	check_collision_objects(player, player, time)

	round_actual.update(time)

	update_cam()
end

local function update_window(time)
	if btn(4) then
    window = Window.GAME
	end
end

local function final_match()
	window = Window.END_GAME
end

-- Base class --
local function Base()
	local self = {
		tag = "",
		sprite = nil,
		x = 0,
		y = 0,
		background = 6,
		direction = const_direction.up,
		collided = false,
		visible = false,
		timeout = 0,
		dx = 0,
		dy = 0,
		tl = {x = 0, y = 0},
		tr = {x = 0, y = 0},
		bl = {x = 0, y = 0},
		br = {x = 0, y = 0},
		new_position = {}
	}

	function self.is_collision(point)
		return mget(
			(point.x / CELL) + (CELL * 2),
			(point.y / CELL) + (CELL + 1)
		) >= 128
	end

	function self.check_water(point)
		local px = (point.x / CELL) + (CELL * 2)
		local py = (point.y / CELL) + (CELL + 1)

		return mget(px, py) == 34
				or mget(px, py) == 35
				or mget(px, py) == 50
				or mget(px, py) == 51
	end

	function self.move(personal, delta, direction_actual, time)
		self.new_position.x = personal.x + delta.x
		self.new_position.y = personal.y + delta.y

		if check_collision_objects(personal, self.new_position, time) then
			return false
		end

		self.tl.x = personal.x - 7 + delta.x
		self.tl.y = personal.y - 8 + delta.y

		self.tr.x = personal.x + 5 + delta.x
		self.tr.y = personal.y - 8 + delta.y

		self.br.x = personal.x + 5 + delta.x
		self.br.y = personal.y + 7 + delta.y

		self.bl.x = personal.x - 7 + delta.x
		self.bl.y = personal.y + 7 + delta.y

		if not self.is_collision(self.tl)
		and not self.is_collision(self.tr)
		and not self.is_collision(self.br)
		and not self.is_collision(self.bl) then
			if personal.curAnim
			and personal.curAnim.ended then
				personal.curAnim.reset()
			end

			personal.x = personal.x + delta.x
			personal.y = personal.y + delta.y
			personal.direction = direction_actual
		end
	end

	function self.draw()
		if self.visible then
			local block_x = cam.x + self.x
			local block_y = cam.y + self.y

			spr(
				self.sprite,
				block_x,
				block_y,
				self.background, -- cor de fundo
				1, -- escala
				0, -- espelhar
				0, -- rotacionar
				2, -- quantidade de blocos direita
				2 -- quantidade de blocos esquerda
			)
		end
	end

	function self.update(time)
		return true
	end

	function self.reset()
		self.collided = false
	end

	return self
end

-- Animation class --
local function Anim(span, frames, loop)
	local self = {
		span = span,
		indx = 0,
		frame = nil,
		frames = frames,
		loop = loop,
		tick = 0,
		ended = false
	}

	function self.update(time)
		if time >= self.tick
		and #self.frames > 0 then
			if self.loop then
				self.indx = (self.indx + 1) % #self.frames
				self.frame = self.frames[self.indx + 1]
				self.ended = false
			else
				self.indx = self.indx < #self.frames and self.indx + 1 or #self.frames
				self.frame = self.frames[self.indx]

				if self.indx == #self.frames then
					self.ended = true
				end
			end
			self.tick = time + self.span
		end
	end

	function self.random_indx()
		self.indx = math.random(#self.frames)
	end

	function self.reset()
		self.indx = 0
		self.ended = false
	end

	return self
end

-- Box class --
local function Box(x, y)
	local self = Base()
	self.sprite = tiles.BOX
	self.background = 1
	self.x = x
	self.y = y
	self.anim = Anim(20, {232, 234, 236}, false)
	self.coins = math.random(15)
	self.visible = true

	function self.update(time)
		if self.collided then
			self.anim.update(time)
			self.sprite = self.anim.frame
		end

		return true
	end

	function self.make_collision_box_with_player()
		self.collided = true
		player.coins = player.coins + self.coins
		self.coins = 0

		return true
	end

	return self
end

-- Door class --
local function Door(x, y, player_x, player_y)
	local self = Base()
	self.tag = constants.DOOR
	self.sprite = tiles.DOOR
	self.x = x
	self.y = y
	self.player_x = player_x
	self.player_y = player_y
	self.anim = Anim(5, {160, 162}, false)
	self.visible = true

	function self.update(time)
		if self.collided then
			self.anim.update(time)
			self.sprite = self.anim.frame

			if self.anim.ended then
				window = Window.TRANSACTION_ROUND
				self.home()
			end
		end

		return true
	end

	function self.make_collision_door_with_player()
		self.collided = true

		return true
	end

	function self.home()
		player.x = self.player_x
		player.y = self.player_y
	end

	return self
end

-- Coin class --
local function Coin(x, y)
	local self = Base()
	self.tag = constants.COIN
	self.sprite = tiles.COIN
	self.x = x
	self.y =	y
	self.anim = Anim(15, {392, 394}, true)
	self.background = 1
	self.visible = true

	function self.update(time)
		self.anim.update(time)
		self.sprite = self.anim.frame

		return true
	end

	function self.make_collision_coin_with_player(index)
		player.coins = player.coins + 1
		table.remove(round_actual.Coins, index)

		return false
	end

	return self
end

-- Alcool class --
local function Alcool(x, y)
	local self = Base()
	self.tag = constants.ALCOOL
	self.sprite = tiles.ALCOOL
	self.x = x
	self.y =	y
	self.anim = Anim(15, {384, 386}, true)
	self.background = 1
	self.visible = true

	function self.update(time)
		self.anim.update(time)
		self.sprite = self.anim.frame

		return true
	end

	function self.make_collision_alcool_with_player(index)
		if player.shield + 1 <= player.maxShield then
			player.shield = player.shield + 1
			table.remove(round_actual.Alcools, index)

			return true
		end

		return false
	end

	return self
end

-- Heart class --
local function Heart(x, y)
	local self = Base()
	self.tag = constants.HEART
	self.sprite = tiles.HEART
	self.x = x
	self.y =	y
	self.anim = Anim(15, {360, 362}, true)
	self.background = 14
	self.visible = true

	function self.update(time)
		self.anim.update(time)
		self.sprite = self.anim.frame

		return true
	end

	function self.make_collision_heart_with_player(index)
		if player.health + 1 <= player.maxHealth then
			player.health = player.health + 1
			table.remove(round_actual.Hearts, index)

			return true
		end

		return false
	end

	return self
end

-- Mask class --
local function Mask(x, y)
	local self = Base()
	self.tag = constants.MASK
	self.sprite = tiles.MASK
	self.x = x
	self.y =	y
	self.anim = Anim(15, {352, 354}, true)
	self.background = 1
	self.visible = true

	function self.update(time)
		self.anim.update(time)
		self.sprite = self.anim.frame

		return true
	end

	function self.make_collision_mask_with_player(index)
		if player.shield + 1 <= player.maxShield then
			if player.shield + 2 <= player.maxShield then
				player.shield = player.shield + 2
			else
				player.shield = player.shield + 1
			end
			table.remove(round_actual.Masks, index)

			return true
		end

		return false
	end

	return self
end

-- Enemy class --
local function Enemy(x, y)
	local self = Base()
	self.tag = constants.ENEMY
	self.sprite = tiles.ENEMY
	self.state = states_enemy.STOP
	self.background = 14
	self.x = x
	self.y =	y
	self.dx = 0
	self.dy = 0
	self.anims = {
		Anim(10, {288, 290}, false),
		Anim(10, {292, 294}, false),
		Anim(10, {296, 298}, false),
		Anim(10, {300, 302}, false)
	}
	self.curAnim = nil
	self.visible = true

	function self.update(time)
		if distancy(self, player) < constants.VIEW_ENEMY
		and not self.check_water(player.tl)
		and not self.check_water(player.tr)
		and not self.check_water(player.bl)
		and not self.check_water(player.br) then
			self.state = states_enemy.PURSUIT
		else
			self.state = states_enemy.STOP
		end

		if self.state == states_enemy.PURSUIT then
			self.dx = 0
			self.dy = 0

			if player.y > self.y then
				self.dy = constants.SPEED_ENEMY

				if player.x == self.x then
					self.direction = const_direction.DOWN
				end
			elseif player.y < self.y then
				self.dy = -constants.SPEED_ENEMY

				if player.x == self.x then
					self.direction = const_direction.UP
				end
			end

			self.move(self, {x = self.dx, y = self.dy}, self.direction, time)

			self.dx = 0
			self.dy = 0

			if player.x > self.x then
				self.dx = constants.SPEED_ENEMY
				self.direction = const_direction.RIGHT
			elseif player.x < self.x then
				self.dx = -constants.SPEED_ENEMY
				self.direction = const_direction.LEFT
			end

			self.move(self, {x = self.dx, y = self.dy}, self.direction, time)

			self.curAnim = self.anims[self.direction]
			self.curAnim.update(time)
			self.sprite = self.curAnim.frame
		end
	end

	function self.make_collision_enemy_with_sword(index)
		table.remove(round_actual.Enemies, index)
		player.score = player.score + math.random(10)

		return false
	end

	function self.make_collision_enemy_with_player(index)
		player.damaged = true

		if player.shield > 0 then
			player.shield = player.shield - 1
		elseif player.health > 0 then
			player.health = player.health - 1
		end

		if player.shield == 0 and player.health == 0 then
			window = Window.GAME_OVER

			return true
		else
			table.remove(round_actual.Enemies, index)
		end

		return false
	end

	return self
end

-- Sword class --
local function Sword(x, y)
	local self = Base()
	self.tag = constants.SWORD
	self.x = x
	self.y = y
	self.background = 0
	self.anims = {
		Anim(10, {322, 324}, false),	-- UP
		Anim(10, {334, 328}, false),	-- DOWN
		Anim(10, {322, 320}, false),	-- LEFT
		Anim(10, {330, 332}, false)		-- RIGHT
	}
	self.delta = {
		{x = 0, y = - 10},
		{x = 0, y = 10},
		{x = -10, y = 0},
		{x = 10, y = 0}
	}
	self.curAnim = nil
	self.visible = false
	self.timeout = 0

	function self.update(time)
		if player.direction then
			self.x = player.x + self.delta[player.direction].x
			self.y = player.y + self.delta[player.direction].y

			self.curAnim = self.anims[player.direction]
			self.curAnim.update(time)
			self.sprite = self.curAnim.frame

			if btn(4) and dialog == nil then
				self.visible = true
				self.timeout = 15
			end
		end

		if self.visible then
			check_collision_objects(self, self, time)

			if self.curAnim and self.curAnim.ended then
				self.curAnim.reset()
			end

			self.timeout = self.timeout - 1
			if self.timeout <= 0 then
				self.visible = false
			end
		end
	end

	return self
end

local function Round(x,	y,	player_x,	player_y,	map, tag)
	local self = Base()
	self.tag = tag
	self.srite = tiles.DOOR
	self.x = x
	self.y = y
	self.player_x = player_x
	self.player_y = player_y
	self.background = 0
	self.visible = true
	self.map = map
	self.timeout = 30
	self.t = 0
	self.Coins = {}
	self.Enemies = {}
	self.Doors = {}
	self.Boxes = {}
	self.Alcools = {}
	self.Hearts = {}
	self.Masks = {}
	self.Npcs = {}
	self.next_round = nil

	function self.update_round()
		window = Window.TRANSACTION_ROUND

		round_actual = self.next_round
		player.x = round_actual.player_x
		player.y = round_actual.player_y
		constants.SPEED_ENEMY = constants.SPEED_ENEMY + 0.1
		self.sync_round()
	end

	function self.sync_round()
		sync(4, round_actual.map)
	end

	function self.draw()
		for _, box in pairs(self.Boxes) do box.draw() end
		for _, enemy in pairs(self.Enemies) do enemy.draw() end
		for _, door in pairs(self.Doors) do door.draw() end
		for _, coin in pairs(self.Coins) do coin.draw() end
		for _, alcool in pairs(self.Alcools) do alcool.draw() end
		for _, heart in pairs(self.Hearts) do heart.draw() end
		for _, mask in pairs(self.Masks) do mask.draw() end
		for _, npc in pairs(self.Npcs) do npc.draw() end
	end

	function self.update(time)
		for _, box in pairs(self.Boxes) do box.update(time) end
		for _, enemy in pairs(self.Enemies) do enemy.update(time) end
		for _, door in pairs(self.Doors) do door.update(time) end
		for _, coin in pairs(self.Coins) do coin.update(time) end
		for _, alcool in pairs(self.Alcools) do alcool.update(time) end
		for _, heart in pairs(self.Hearts) do heart.update(time) end
		for _, mask in pairs(self.Masks) do mask.update(time) end
		for _, npc in pairs(self.Npcs) do npc.update(time) end
	end

	function self.reset()
		for _, box in pairs(self.Boxes) do box.reset() end
		for _, enemy in pairs(self.Enemies) do enemy.reset() end
		for _, door in pairs(self.Doors) do door.reset() end
		for _, coin in pairs(self.Coins) do coin.reset() end
		for _, alcool in pairs(self.Alcools) do alcool.reset() end
		for _, heart in pairs(self.Hearts) do heart.reset() end
		for _, mask in pairs(self.Masks) do mask.reset() end
		for _, npc in pairs(self.Npcs) do npc.reset() end
	end

	return self
end

-- NPC class --
local function NPC(x, y, dialog_npc)
	local self = Base()
	self.tag = constants.NPC
	self.sprite = tiles.NPC
	self.x = x
	self.y =	y
	self.anim = Anim(15, {416, 418, 420, 422}, true)
	self.dialog = dialog_npc or nil
	self.background = 6
	self.visible = true

	function self.update(time)
		self.anim.update(time)
		self.sprite = self.anim.frame

		return true
	end

	function self.make_collision_npc_with_player()
		if btn(5) then
			dialog = self.dialog
		end

		return true
	end

	return self
end

-- Player class --
local function Player(x, y, sword)
	local self = Base()
	self.tag = constants.PLAYER
	self.sprite = tiles.PLAYER
	self.x = x
	self.y = y
	self.background = 6
	self.sword = sword
	self.health = 3
	self.maxHealth = 8
	self.shield = 0
	self.maxShield = 5
	self.coins = 0
	self.score = 0
	self.anims = {
		up = Anim(9, {256, 258}, false),
		down = Anim(9, {260, 262}, false),
		left = Anim(9, {264, 266}, false),
		right = Anim(9, {268, 270}, false),
		up_water = Anim(9, {396, 398}, false),
		down_water = Anim(9, {428, 430}, false),
		left_water = Anim(9, {460, 462}, false),
		right_water = Anim(9, {492, 494}, false)
	}
	self.delta = {
		{x = 0, y = -1},	-- up
		{x = 0, y = 1},		-- down
		{x = -1, y = 0},	-- left
		{x = 1, y = 0}		-- right
	}
	self.curAnim = nil
	self.damaged = false
	self.timeout = 30

	function self.draw()
		player.sword.draw()

		local block_x, block_y = (cam.x + self.x), (cam.y + self.y)

		if self.damaged
		and (time()//250) % 2 ~= 0
		and self.timeout > 0 then
			self.timeout = self.timeout - 1
			return
		elseif self.timeout == 0 then
			self.damaged = false
			self.timeout = 30
		end

		spr(
			self.sprite,
			block_x,
			block_y,
			self.background, -- cor de fundo
			1, -- escala
			0, -- espelhar
			0, -- rotacionar
			2, -- quantidade de blocos direita
			2 -- quantidade de blocos esquerda
		)
	end

	function self.update(time)
		if dialog == nil then
			for keyword = 0, 3 do
				if btn(keyword) then
					if btn(0) then self.curAnim = self.anims.up	end
					if btn(1) then self.curAnim = self.anims.down	end
					if btn(2) then self.curAnim = self.anims.left	end
					if btn(3) then self.curAnim = self.anims.right end

					self.direction = keyword + 1

					if self.check_water(self.tl)
					and self.check_water(self.tr)
					and self.check_water(self.bl)
					and self.check_water(self.br) then
						self.delta = {
							{x = 0, y = -0.5},	-- up
							{x = 0, y = 0.5},		-- down
							{x = -0.5, y = 0},	-- left
							{x = 0.5, y = 0}		-- right
						}

						if self.direction == 1 then	self.curAnim = self.anims.up_water end
						if self.direction == 2 then self.curAnim = self.anims.down_water end
						if self.direction == 3 then self.curAnim = self.anims.left_water end
						if self.direction == 4 then self.curAnim = self.anims.right_water end
					else
						self.delta = {
							{x = 0, y = -1},	-- up
							{x = 0, y = 1},		-- down
							{x = -1, y = 0},	-- left
							{x = 1, y = 0}		-- right
						}
					end

					self.curAnim.update(time)
					self.sprite = self.curAnim.frame

					self.move(self, self.delta[self.direction], self.direction, time)
				end
			end
		end

		self.sword.update(time)
	end

	return self
end

local function draw_objects()
	round_actual.draw()
end

local function draw_menu()
	cls()

	spr(
		448,
		75,
		30,
		0, -- cor de fundo
		1, -- escala
		0, -- espelhar
		0, -- rotacionar
		10, -- quantidade de blocos direita
		10 -- quantidade de blocos esquerda
	)


	if (time()//800) % 2 == 0 then
		print("Pressione [z]", 80, 90)
	end

	print(constants.ABOUT, 5, 128)
end

local function draw_game()
	cls()

	draw_map()
	draw_objects()

	player.draw()
	start_dialog()
	DisplayHUD()
end

local function create_rounds()
	local function create_objects(arr_obj, objs)
		for _, item in pairs(arr_obj) do
			if item.pl_x and item.pl_y then
				table.insert(objs, item.create(item.x, item.y, item.pl_x, item.pl_y))
			elseif item.dialog then
				table.insert(objs, item.create(item.x, item.y, item.dialog))
			else
				table.insert(objs, item.create(item.x, item.y))
			end
		end
	end

	round_1 = Round(0, 0, -109, 936, 0, constants.ROUND_1)

	local dialog_npc = {
		"Bom dia! Eu sou mercador.",
		"O que desejas comprar?".."\n"..
		"				Mascara (10 moedas).".."\n"..
		"				Vida (5 moedas)."
	}

	local	alcools = {
		{x = -111, y = 999, create = Alcool},
		{x = 942, y = 174, create = Alcool},
		{x = 568, y = 277, create = Alcool},
		{x = 373, y = 667, create = Alcool},
		{x = 797, y = 786, create = Alcool},
		{x = 1169, y = 704, create = Alcool},
		{x = 1341, y = 37, create = Alcool}
	}

	local hearts = {
		{x = 1038, y = 101, create = Heart},
		{x = 1097, y = 424, create = Heart},
		{x = 709, y = 633, create = Heart},
		{x = -110, y = 732, create = Heart},
		{x = 1528, y = 538, create = Heart},
		{x = 329, y = 902, create = Heart},
		{x = 1342, y = 580, create = Heart},
		{x = 1527, y = 855, create = Heart},
		{x = 1425, y = 24, create = Heart},
		{x = 778, y = 94, create = Heart}
	}

	local masks = {
		{x = 297, y = 90, create = Mask},
		{x = 92, y = 493, create = Mask},
		{x = 1438, y = 584, create = Mask},
		{x = 1526, y = 270, create = Mask},
		{x = 1107, y = 952, create = Mask},
		{x = 1417, y = 855, create = Mask},
		{x = 1425, y = 0, create = Mask}
	}

	local boxes = {
		{x = -110, y = 899, create = Box},
		{x = 265, y = 88, create = Box},
		{x = 328, y = 88, create = Box},
		{x = 944, y = 87, create = Box},
		{x = 84, y = 765, create = Box},
		{x = 1177, y = 363, create = Box},
		{x = 95, y = 627, create = Box},
		{x = 1525, y = 580, create = Box},
		{x = 1525, y = 500, create = Box},
		{x = 1113, y = 636, create = Box},
		{x = 1162, y = 636, create = Box},
		{x = 1441, y = 793, create = Box},
		{x = 1528, y = -8, create = Box}
	}

	local enemies = {
		{x = 96, y = 896, create = Enemy},
		{x = 96, y = 1000, create = Enemy},
		{x = 336, y = 801, create = Enemy},
		{x = 510, y = 1000, create = Enemy},
		{x = 816, y = 970, create = Enemy},
		{x = 760, y = 1000, create = Enemy},
		{x = 616, y = 809, create = Enemy},
		{x = 576, y = 809, create = Enemy},
		{x = 471, y = 786, create = Enemy},
		{x = 396, y = 672, create = Enemy},
		{x = 371, y = 625, create = Enemy},
		{x = 538, y = 665, create = Enemy},
		{x = 573, y = 728, create = Enemy},
		{x = 635, y = 592, create = Enemy},
		{x = 814, y = 513, create = Enemy},
		{x = 386, y = 488, create = Enemy},
		{x = 329, y = 505, create = Enemy},
		{x = 306, y = 577, create = Enemy},
		{x = 150, y = 577, create = Enemy},
		{x = 189, y = 560, create = Enemy},
		{x = 235, y = 655, create = Enemy},
		{x = 251, y = 1000, create = Enemy},
		{x = 190, y = 735, create = Enemy},
		{x = 36, y = 537, create = Enemy},
		{x = 11, y = 705, create = Enemy},
		{x = -10, y = 592, create = Enemy},
		{x = -81, y = 720, create = Enemy},
		{x = 287, y = 104, create = Enemy},
		{x = 223, y = 764, create = Enemy},
		{x = 979, y = 100, create = Enemy},
		{x = 620, y = 129, create = Enemy},
		{x = 771, y = 167, create = Enemy},
		{x = 944, y = 119, create = Enemy},
		{x = -107, y = 774, create = Enemy},
		{x = 86, y = 789, create = Enemy},
		{x = -9, y = 767, create = Enemy},
		{x = 75, y = 111, create = Enemy},
		{x = -48, y = 172, create = Enemy},
		{x = 1099, y = 368, create = Enemy},
		{x = 322, y = 111, create = Enemy},
		{x = 469, y = 277, create = Enemy},
		{x = 532, y = 292, create = Enemy},
		{x = 1133, y = 445, create = Enemy},
		{x = 628, y = 632, create = Enemy},
		{x = 375, y = 555, create = Enemy},
		{x = -11, y = 527, create = Enemy},
		{x = 85, y = 728, create = Enemy},
		{x = -13, y = 728, create = Enemy},
		{x = 802, y = 829, create = Enemy},
		{x = 1530, y = 515, create = Enemy},
		{x = 1530, y = 564, create = Enemy},
		{x = 1476, y = 232, create = Enemy},
		{x = 1466, y = 302, create = Enemy},
		{x = 1413, y = 270, create = Enemy},
		{x = 1137, y = 635, create = Enemy},
		{x = 1167, y = 659, create = Enemy},
		{x = 1144, y = 912, create = Enemy},
		{x = 1146, y = 984, create = Enemy},
		{x = 1479, y = 813, create = Enemy},
		{x = 1380, y = 813, create = Enemy},
		{x = 1482, y = 855, create = Enemy},
		{x = 1392, y = 16, create = Enemy},
		{x = 1392, y = 16, create = Enemy},
		{x = 1455, y = 21, create = Enemy},
		{x = 1527, y = 37, create = Enemy},
		{x = 1524, y = -38, create = Enemy},
		{x = 1356, y = -35, create = Enemy}
	}

	local doors = {
		{x = 761,	y = 952, pl_x = 705, pl_y = 93, create = Door},
		{x = 705, y = 73, pl_x = 761, pl_y = 970, create = Door},

		{x = 176,	y = 953, pl_x = -8, pl_y = 92, create = Door},
		{x = -8,	y = 73, pl_x = 176, pl_y = 970, create = Door},

		{x = 73,	y = 849, pl_x = 297, pl_y = 175, create = Door},
		{x = 297,	y = 193, pl_x = 73, pl_y = 862, create = Door},

		{x = 169,	y = 849, pl_x = 370, pl_y = 288, create = Door},
		{x = 361,	y = 289, pl_x = 169, pl_y = 862, create = Door},

		{x = 497,	y = 954, pl_x = 1174, pl_y = 400, create = Door},
		{x = 1193,	y = 400, pl_x = 497, pl_y = 990, create = Door},

		{x = 409,	y = 832, pl_x = 1341, pl_y = 536, create = Door},
		{x = 1320,	y = 536, pl_x = 409, pl_y = 848, create = Door},

		{x = 729,	y = 698, pl_x = 1335, pl_y = 264, create = Door},
		{x = 1321,	y = 264, pl_x = 729, pl_y = 710, create = Door},

		{x = 489,	y = 546, pl_x = 1137, pl_y = 720, create = Door},
		{x = 1137,	y = 737, pl_x = 489, pl_y = 560, create = Door},

		{x = 169,	y = 522, pl_x = 1195, pl_y = 944, create = Door},
		{x = 1209,	y = 944, pl_x = 169, pl_y = 540, create = Door},

		{x = 168,	y = 697, pl_x = 1426, pl_y = 770, create = Door},
		{x = 1426,	y = 752, pl_x = 168, pl_y = 715, create = Door},

		{x = -64,	y = 665, pl_x = 1425, pl_y = -48, create = Door},
		{x = 1425,	y = -63, pl_x = -64, pl_y = 680, create = Door}
	}

	local coins = {
		{x = 1, y = 936, create = Coin},
		{x = -110, y = 830, create = Coin},
		{x = 336, y = 864, create = Coin},
		{x = 336, y = 760, create = Coin},
		{x = 570, y = 787, create = Coin},
		{x = 451, y = 816, create = Coin},
		{x = 378, y = 864, create = Coin},
		{x = 451, y = 816, create = Coin},
		{x = 514, y = 632, create = Coin},
		{x = 697, y = 588, create = Coin},
		{x = 679, y = 513, create = Coin},
		{x = 814, y = 558, create = Coin},
		{x = 281, y = 505, create = Coin},
		{x = 209, y = 592, create = Coin},
		{x = 211, y = 696, create = Coin},
		{x = 130, y = 712, create = Coin},
		{x = 1009, y = 169, create = Coin},
		{x = 620, y = 174, create = Coin},
		{x = -99, y = 109, create = Coin},
		{x = 79, y = 174, create = Coin},
		{x = 378, y = 586, create = Coin},
		{x = 49, y = 493, create = Coin},
		{x = 1412, y = 230, create = Coin},
		{x = 1341, y = 855, create = Coin}
	}

	local npcs = {
		{x = 20, y = 936, dialog = dialog_npc, create = NPC}
	}

	create_objects(alcools, round_1.Alcools)
	create_objects(hearts, round_1.Hearts)
	create_objects(masks, round_1.Masks)
	create_objects(boxes, round_1.Boxes)
	create_objects(enemies, round_1.Enemies)
	create_objects(doors, round_1.Doors)
	create_objects(coins, round_1.Coins)
	create_objects(npcs, round_1.Npcs)

	round_2 = Round(-56, 576, -112, -8, 1, constants.ROUND_2)
	alcools = {
		{x = 333, y = 269, create = Alcool},
		{x = -104, y = 403, create = Alcool},
		{x = 1107, y = 140, create = Alcool},
		{x = 860, y = 717, create = Alcool}
	}
	hearts = {
		{x = -50, y = 312, create = Heart},
		{x = 259, y = 451, create = Heart},
		{x = 565, y = 122, create = Heart},
		{x = 1284, y = 127, create = Heart},
		{x = 1099, y = 88, create = Heart},
		{x = 1493, y = 36, create = Heart},
		{x = 1420, y = 632, create = Heart},
		{x = 809, y = 853, create = Heart},
		{x = 73, y = 709, create = Heart}
	}
	masks = {
		{x = 235, y = 46, create = Mask},
		{x = 638, y = 161, create = Mask},
		{x = 1000, y = 992, create = Mask}
	}
	boxes = {
		{x = 326, y = 317, create = Box},
		{x = 1578, y = 424, create = Box},
		{x = 1618, y = 992, create = Box},
		{x = 1249, y = 920, create = Box},
		{x = 1046, y = 720, create = Box},
		{x = 616, y = 840, create = Box},
		{x = 985, y = 944, create = Box},
		{x = 570, y = 720, create = Box}
	}
	enemies = {
		{x = -17, y = -37, create = Enemy},
		{x = -47, y = 34, create = Enemy},
		{x = 261, y = -50, create = Enemy},
		{x = 304, y = -34, create = Enemy},
		{x = 319, y = 28, create = Enemy},
		{x = 75, y = 98, create = Enemy},
		{x = 44, y = 139, create = Enemy},
		{x = 91, y = 177, create = Enemy},
		{x = -95, y = 173, create = Enemy},
		{x = 319, y = 96, create = Enemy},
		{x = 319, y = 149, create = Enemy},
		{x = 217, y = 111, create = Enemy},
		{x = 217, y = 153, create = Enemy},
		{x = 177, y = 140, create = Enemy},
		{x = 330, y = 222, create = Enemy},
		{x = 307, y = 245, create = Enemy},
		{x = 183, y = 218, create = Enemy},
		{x = 186, y = 246, create = Enemy},
		{x = 68, y = 246, create = Enemy},
		{x = -91, y = 231, create = Enemy},
		{x = -106, y = 280, create = Enemy},
		{x = -97, y = 365, create = Enemy},
		{x = -104, y = 452, create = Enemy},
		{x = 83, y = 452, create = Enemy},
		{x = 159, y = 371, create = Enemy},
		{x = 162, y = 451, create = Enemy},
		{x = 320, y = 451, create = Enemy},
		{x = 329, y = 370, create = Enemy},
		{x = 404, y = 451, create = Enemy},
		{x = 413, y = 362, create = Enemy},
		{x = 543, y = 448, create = Enemy},
		{x = 410, y = 311, create = Enemy},
		{x = 569, y = 311, create = Enemy},
		{x = 569, y = 224, create = Enemy},
		{x = 402, y = 237, create = Enemy},
		{x = 648, y = 423, create = Enemy},
		{x = 739, y = 385, create = Enemy},
		{x = 803, y = 434, create = Enemy},
		{x = 803, y = 356, create = Enemy},
		{x = 811, y = 272, create = Enemy},
		{x = 728, y = 310, create = Enemy},
		{x = 619, y = 301, create = Enemy},
		{x = 619, y = 256, create = Enemy},
		{x = 809, y = 93, create = Enemy},
		{x = 809, y = 152, create = Enemy},
		{x = 766, y = 166, create = Enemy},
		{x = 743, y = 97, create = Enemy},
		{x = 701, y = 144, create = Enemy},
		{x = 651, y = 103, create = Enemy},
		{x = 811, y = 19, create = Enemy},
		{x = 775, y = -53, create = Enemy},
		{x = 708, y = -7, create = Enemy},
		{x = 694, y = 36, create = Enemy},
		{x = 672, y = 7, create = Enemy},
		{x = 633, y = -52, create = Enemy},
		{x = 555, y = 37, create = Enemy},
		{x = 500, y = 7, create = Enemy},
		{x = 407, y = -47, create = Enemy},
		{x = 419, y = 99, create = Enemy},
		{x = 569, y = 177, create = Enemy},
		{x = 565, y = 88, create = Enemy},
		{x = 1117, y = 176, create = Enemy},
		{x = 1279, y = 176, create = Enemy},
		{x = 1201, y = 122, create = Enemy},
		{x = 1160, y = 106, create = Enemy},
		{x = 1615, y = 228, create = Enemy},
		{x = 1615, y = 308, create = Enemy},
		{x = 1580, y = 270, create = Enemy},
		{x = 1652, y = 405, create = Enemy},
		{x = 1654, y = 444, create = Enemy},
		{x = 1594, y = 424, create = Enemy},
		{x = 1695, y = 808, create = Enemy},
		{x = 1770, y = 808, create = Enemy},
		{x = 1594, y = 953, create = Enemy},
		{x = 1642, y = 953, create = Enemy},
		{x = 1139, y = 366, create = Enemy},
		{x = 1215, y = 374, create = Enemy},
		{x = 1213, y = 406, create = Enemy},
		{x = 1223, y = 441, create = Enemy},
		{x = 1144, y = 445, create = Enemy},
		{x = 1420, y = 675, create = Enemy},
		{x = 1462, y = 677, create = Enemy},
		{x = 1503, y = 701, create = Enemy},
		{x = 1375, y = 689, create = Enemy},
		{x = 1338, y = 687, create = Enemy},
		{x = 1226, y = 949, create = Enemy},
		{x = 1244, y = 979, create = Enemy},
		{x = 860, y = 656, create = Enemy},
		{x = 881, y = 680, create = Enemy},
		{x = 899, y = 720, create = Enemy},
		{x = 1025, y = 680, create = Enemy},
		{x = 1006, y = 706, create = Enemy},
		{x = 642, y = 816, create = Enemy},
		{x = 771, y = 816, create = Enemy},
		{x = 750, y = 856, create = Enemy},
		{x = 673, y = 852, create = Enemy},
		{x = 962, y = 970, create = Enemy},
		{x = 30, y = 652, create = Enemy},
		{x = 30, y = 716, create = Enemy},
		{x = 185, y = 856, create = Enemy},
		{x = 293, y = 856, create = Enemy},
		{x = 563, y = 678, create = Enemy},
		{x = 522, y = 642, create = Enemy},
		{x = 518, y = 710, create = Enemy}
	}
	doors = {
		{x = 48, y = 9, pl_x = 1193, pl_y = 177, create = Door},
		{x = 1193, y = 192, pl_x = 48, pl_y = 25, create = Door},

		{x = 169, y = 8, pl_x = 1489, pl_y = -16, create = Door},
		{x = 1489, y = -32, pl_x = 169, pl_y = 24, create = Door},

		{x = -38, y = 144, pl_x = 1657, pl_y = 272, create = Door},
		{x = 1673, y = 272, pl_x = -38, pl_y = 160, create = Door},
		{x = 1560, y = 272, pl_x = 1730, pl_y = 424, create = Door},
		{x = 1752, y = 424, pl_x = 1600, pl_y = 272, create = Door},

		{x = -16, y = 416, pl_x = 1729, pl_y = 769, create = Door},
		{x = 1729, y = 753, pl_x = -16, pl_y = 432, create = Door},

		{x = 56, y = 416, pl_x = 1617, pl_y = 907, create = Door},
		{x = 1617, y = 889, pl_x = 56, pl_y = 432, create = Door},

		{x = 257, y = 416, pl_x = 1097, pl_y = 400, create = Door},
		{x = 1081, y = 400, pl_x = 257, pl_y = 432, create = Door},
		{x = 1304, y = 400, pl_x = 1433, pl_y = 720, create = Door},
		{x = 1433, y = 736, pl_x = 1290, pl_y = 400, create = Door},

		{x = 457, y = 440, pl_x = 1289, pl_y = 944, create = Door},
		{x = 1305, y = 944, pl_x = 457, pl_y = 456, create = Door},

		{x = 489, y = 288, pl_x = 945, pl_y = 633, create = Door},
		{x = 945, y = 617, pl_x = 489, pl_y = 304, create = Door},
		{x = 953, y = 736, pl_x = 712, pl_y = 833, create = Door},
		{x = 712, y = 801, pl_x = 953, pl_y = 720, create = Door},

		{x = 728, y = 440, pl_x = 1049, pl_y = 969, create = Door},
		{x = 1065, y = 969, pl_x = 729, pl_y = 456, create = Door},

		{x = 705, y = 281, pl_x = -40, pl_y = 688, create = Door},
		{x = -56, y = 688, pl_x = 705, pl_y = 297, create = Door},
		{x = 104, y = 688, pl_x = 234, pl_y = 816, create = Door},
		{x = 232, y = 801, pl_x = 90, pl_y = 688, create = Door},
		{x = 241, y = 872, pl_x = 466, pl_y = 680, create = Door},
		{x = 450, y = 680, pl_x = 241, pl_y = 856, create = Door}
	}
	coins = {
		{x = 332, y = -51, create = Coin},
		{x = 327, y = 175, create = Coin},
		{x = 144, y = 90, create = Coin},
		{x = 155, y = 172, create = Coin},
		{x = 809, y = 227, create = Coin},
		{x = 655, y = 319, create = Coin},
		{x = 619, y = 221, create = Coin},
		{x = 615, y = 87, create = Coin},
		{x = 755, y = 44, create = Coin},
		{x = 716, y = -53, create = Coin},
		{x = 627, y = 25, create = Coin},
		{x = 519, y = 47, create = Coin},
		{x = 440, y = 7, create = Coin},
		{x = 1736, y = 808, create = Coin},
		{x = 1182, y = 366, create = Coin},
		{x = 1251, y = 374, create = Coin},
		{x = 1258, y = 433, create = Coin},
		{x = 1191, y = 431, create = Coin},
		{x = 1503, y = 632, create = Coin}
	}
	npcs = {}

	create_objects(alcools, round_2.Alcools)
	create_objects(hearts, round_2.Hearts)
	create_objects(masks, round_2.Masks)
	create_objects(boxes, round_2.Boxes)
	create_objects(enemies, round_2.Enemies)
	create_objects(doors, round_2.Doors)
	create_objects(coins, round_2.Coins)
	create_objects(npcs, round_2.Npcs)

	round_3 = Round(489, 160, 794, 454, 2, constants.ROUND_3)
	alcools = {
		{x = 333, y = 269, create = Alcool},
		{x = 1489, y = 934, create = Alcool}
	}
	hearts = {
		{x = 610, y = 456, create = Heart},
		{x = -48, y = 409, create = Heart},
		{x = 569, y = 42, create = Heart},
		{x = 772, y = 48, create = Heart},
		{x = 1191, y = -3, create = Heart},
		{x = 1187, y = 311, create = Heart},
		{x = 1449, y = 584, create = Heart},
		{x = 375, y = 672, create = Heart}
	}
	masks = {
		{x = 380, y = 299, create = Mask},
		{x = -110, y = 221, create = Mask},
		{x = 671, y = 48, create = Mask},
		{x = 1288, y = 310, create = Mask},
		{x = 379, y = 720, create = Mask},
		{x = 1489, y = 895, create = Mask}
	}
	boxes = {
		{x = 614, y = 222, create = Box},
		{x = 129, y = 352, create = Box},
		{x = 68, y = 86, create = Box},
		{x = 98, y = 95, create = Box},
		{x = 137, y = 840, create = Box},
		{x = 1017, y = 499, create = Box},
		{x = 1449, y = 912, create = Box},
		{x = 1217, y = 856, create = Box}
	}
	enemies = {
		{x = 682, y = 433, create = Enemy},
		{x = 691, y = 456, create = Enemy},
		{x = 814, y = 356, create = Enemy},
		{x = 817, y = 393, create = Enemy},
		{x = 780, y = 286, create = Enemy},
		{x = 811, y = 227, create = Enemy},
		{x = 758, y = 220, create = Enemy},
		{x = 663, y = 220, create = Enemy},
		{x = 571, y = 249, create = Enemy},
		{x = 520, y = 228, create = Enemy},
		{x = 505, y = 252, create = Enemy},
		{x = 393, y = 234, create = Enemy},
		{x = 442, y = 381, create = Enemy},
		{x = 407, y = 411, create = Enemy},
		{x = 374, y = 366, create = Enemy},
		{x = 391, y = 455, create = Enemy},
		{x = 536, y = 455, create = Enemy},
		{x = 311, y = 454, create = Enemy},
		{x = 269, y = 368, create = Enemy},
		{x = 206, y = 453, create = Enemy},
		{x = 133, y = 440, create = Enemy},
		{x = 41, y = 456, create = Enemy},
		{x = 27, y = 409, create = Enemy},
		{x = -45, y = 456, create = Enemy},
		{x = -101, y = 412, create = Enemy},
		{x = -86, y = 218, create = Enemy},
		{x = -86, y = 237, create = Enemy},
		{x = 8, y = 260, create = Enemy},
		{x = 38, y = 216, create = Enemy},
		{x = 69, y = 280, create = Enemy},
		{x = 89, y = 311, create = Enemy},
		{x = 140, y = 254, create = Enemy},
		{x = 140, y = 297, create = Enemy},
		{x = 194, y = 320, create = Enemy},
		{x = 274, y = 320, create = Enemy},
		{x = 333, y = 295, create = Enemy},
		{x = 289, y = 231, create = Enemy},
		{x = 327, y = 175, create = Enemy},
		{x = 327, y = 91, create = Enemy},
		{x = 214, y = 83, create = Enemy},
		{x = 137, y = 87, create = Enemy},
		{x = 151, y = 131, create = Enemy},
		{x = 246, y = 141, create = Enemy},
		{x = 196, y = 184, create = Enemy},
		{x = 43, y = 184, create = Enemy},
		{x = -110, y = 173, create = Enemy},
		{x = -110, y = 152, create = Enemy},
		{x = -80, y = 86, create = Enemy},
		{x = -49, y = 86, create = Enemy},
		{x = 28, y = 86, create = Enemy},
		{x = 254, y = 48, create = Enemy},
		{x = 293, y = -4, create = Enemy},
		{x = 246, y = -34, create = Enemy},
		{x = 130, y = 48, create = Enemy},
		{x = -27, y = 37, create = Enemy},
		{x = -27, y = -35, create = Enemy},
		{x = -108, y = -35, create = Enemy},
		{x = -27, y = -35, create = Enemy},
		{x = -110, y = 22, create = Enemy},
		{x = 93, y = -56, create = Enemy},
		{x = 418, y = -37, create = Enemy},
		{x = 407, y = 23, create = Enemy},
		{x = 455, y = 6, create = Enemy},
		{x = 500, y = 18, create = Enemy},
		{x = 464, y = 48, create = Enemy},
		{x = 557, y = 16, create = Enemy},
		{x = 552, y = -32, create = Enemy},
		{x = 637, y = -29, create = Enemy},
		{x = 654, y = 18, create = Enemy},
		{x = 639, y = 46, create = Enemy},
		{x = 710, y = 1, create = Enemy},
		{x = 748, y = -30, create = Enemy},
		{x = 814, y = -38, create = Enemy},
		{x = 814, y = 8, create = Enemy},
		{x = 760, y = 19, create = Enemy},
		{x = 741, y = 43, create = Enemy},
		{x = 765, y = 108, create = Enemy},
		{x = 765, y = 143, create = Enemy},
		{x = 804, y = 99, create = Enemy},
		{x = 814, y = 136, create = Enemy},
		{x = 806, y = 184, create = Enemy},
		{x = 710, y = 184, create = Enemy},
		{x = 678, y = 88, create = Enemy},
		{x = 524, y = 184, create = Enemy},
		{x = 570, y = 127, create = Enemy},
		{x = 545, y = 84, create = Enemy},
		{x = 382, y = 108, create = Enemy},
		{x = 380, y = 163, create = Enemy},
		{x = 409, y = 182, create = Enemy},
		{x = 983, y = 40, create = Enemy},
		{x = 983, y = -48, create = Enemy},
		{x = 1215, y = 27, create = Enemy},
		{x = 1215, y = -30, create = Enemy},
		{x = 1530, y = 299, create = Enemy},
		{x = 1530, y = 239, create = Enemy},
		{x = 1488, y = 312, create = Enemy},
		{x = 1287, y = 249, create = Enemy},
		{x = 1232, y = 229, create = Enemy},
		{x = 985, y = 225, create = Enemy},
		{x = 983, y = 312, create = Enemy},
		{x = 983, y = 270, create = Enemy},
		{x = 1228, y = 583, create = Enemy},
		{x = 1264, y = 583, create = Enemy},
		{x = 1194, y = 584, create = Enemy},
		{x = 1452, y = 552, create = Enemy},
		{x = 1529, y = 552, create = Enemy},
		{x = 857, y = 856, create = Enemy},
		{x = 861, y = 813, create = Enemy},
		{x = 938, y = 813, create = Enemy},
		{x = 1002, y = 813, create = Enemy},
		{x = 1050, y = 813, create = Enemy},
		{x = 595, y = 864, create = Enemy},
		{x = 511, y = 646, create = Enemy},
		{x = 513, y = 718, create = Enemy},
		{x = 498, y = 672, create = Enemy},
		{x = 449, y = 672, create = Enemy},
		{x = 403, y = 672, create = Enemy},
		{x = 257, y = 855, create = Enemy},
		{x = 260, y = 918, create = Enemy},
		{x = 197, y = 913, create = Enemy},
		{x = 137, y = 905, create = Enemy},
		{x = 172, y = 847, create = Enemy},
		{x = -97, y = 673, create = Enemy},
		{x = -30, y = 720, create = Enemy},
		{x = -8, y = 674, create = Enemy},
		{x = 36, y = 632, create = Enemy},
		{x = 906, y = 584, create = Enemy},
		{x = 983, y = 558, create = Enemy},
		{x = 1046, y = 584, create = Enemy},
		{x = 1601, y = 778, create = Enemy},
		{x = 1602, y = 846, create = Enemy},
		{x = 1642, y = 813, create = Enemy},
		{x = 1609, y = 929, create = Enemy},
		{x = 1562, y = 912, create = Enemy},
		{x = 1233, y = 768, create = Enemy},
		{x = 1232, y = 816, create = Enemy},
		{x = 1250, y = 856, create = Enemy}
	}
	doors = {
		{x = 729, y = 304, pl_x = 1049, pl_y = 0, create = Door},
		{x = 1065, y = 0, pl_x = 729, pl_y = 320, create = Door},

		{x = 649, y = 304, pl_x = 1289, pl_y = -7, create = Door},
		{x = 1305, y = -7, pl_x = 649, pl_y = 320, create = Door},

		{x = 217, y = 416, pl_x = 1441, pl_y = 272, create = Door},
		{x = 1425, y = 272, pl_x = 217, pl_y = 432, create = Door},

		{x = 153, y = 416, pl_x = 1186, pl_y = 272, create = Door},
		{x = 1169, y = 272, pl_x = 153, pl_y = 432, create = Door},

		{x = 81, y = 416, pl_x = 1049, pl_y = 272, create = Door},
		{x = 1065, y = 272, pl_x = 81, pl_y = 432, create = Door},

		{x = 249, y = 296, pl_x = 1489, pl_y = 496, create = Door},
		{x = 1489, y = 480, pl_x = 249, pl_y = 312, create = Door},

		{x = 193, y = 296, pl_x = 1257, pl_y = 496, create = Door},
		{x = 1257, y = 480, pl_x = 193, pl_y = 312, create = Door},

		{x = 72, y = 152, pl_x = 857, pl_y = 584, create = Door},
		{x = 841, y = 584, pl_x = 72, pl_y = 168, create = Door},

		{x = 0, y = 152, pl_x = 1449, pl_y = 808, create = Door},
		{x = 1433, y = 808, pl_x = 0, pl_y = 168, create = Door},

		{x = -64, y = 152, pl_x = 1289, pl_y = 816, create = Door},
		{x = 1305, y = 816, pl_x = -64, pl_y = 168, create = Door},

		{x = 185, y = 32, pl_x = 953, pl_y = 856, create = Door},
		{x = 953, y = 872, pl_x = 185, pl_y = 48, create = Door},

		{x = 42, y = 32, pl_x = 593, pl_y = 914, create = Door},
		{x = 593, y = 928, pl_x = 42, pl_y = 48, create = Door},

		{x = 714, y = 152, pl_x = 569, pl_y = 672, create = Door},
		{x = 585, y = 672, pl_x = 714, pl_y = 168, create = Door},

		{x = 649, y = 152, pl_x = 329, pl_y = 880, create = Door},
		{x = 345, y = 880, pl_x = 649, pl_y = 168, create = Door},

		{x = 513, y = 152, pl_x = 89, pl_y = 672, create = Door},
		{x = 105, y = 672, pl_x = 513, pl_y = 168, create = Door}
	}
	coins = {
		{x = 540, y = 217, create = Coin},
		{x = 445, y = 227, create = Coin},
		{x = 423, y = 362, create = Coin},
		{x = 480, y = 413, create = Coin},
		{x = 425, y = 455, create = Coin},
		{x = 316, y = 395, create = Coin},
		{x = 165, y = 456, create = Coin},
		{x = 2, y = 456, create = Coin},
		{x = -103, y = 448, create = Coin},
		{x = -27, y = 260, create = Coin},
		{x = 42, y = 260, create = Coin},
		{x = 95, y = 216, create = Coin},
		{x = 96, y = 280, create = Coin},
		{x = 327, y = 128, create = Coin},
		{x = 265, y = 91, create = Coin},
		{x = 167, y = 83, create = Coin},
		{x = -15, y = 86, create = Coin},
		{x = 391, y = 1, create = Coin},
		{x = 531, y = 32, create = Coin},
		{x = 622, y = 184, create = Coin},
		{x = 399, y = 93, create = Coin},
		{x = 394, y = 163, create = Coin},
		{x = 983, y = -3, create = Coin},
		{x = 1288, y = -48, create = Coin},
		{x = 1288, y = 40, create = Coin},
		{x = 1458, y = 264, create = Coin},
		{x = 1530, y = 264, create = Coin},
		{x = 1194, y = 541, create = Coin},
		{x = 1489, y = 573, create = Coin},
		{x = 1021, y = 783, create = Coin},
		{x = 980, y = 784, create = Coin},
		{x = 941, y = 787, create = Coin},
		{x = 901, y = 787, create = Coin},
		{x = 861, y = 787, create = Coin},
		{x = 535, y = 848, create = Coin},
		{x = 650, y = 848, create = Coin},
		{x = 1482, y = 779, create = Coin},
		{x = 1482, y = 848, create = Coin}
	}
	npcs = {
		{x = 629, y = 456, dialog = dialog_npc, create = NPC},
		{x = -110, y = -4, dialog = dialog_npc, create = NPC}
	}

	create_objects(alcools, round_3.Alcools)
	create_objects(hearts, round_3.Hearts)
	create_objects(masks, round_3.Masks)
	create_objects(boxes, round_3.Boxes)
	create_objects(enemies, round_3.Enemies)
	create_objects(doors, round_3.Doors)
	create_objects(coins, round_3.Coins)
	create_objects(npcs, round_3.Npcs)

	round_4 = Round(449, 152, 814, -41, 3, constants.ROUND_4)
	alcools = {
		{x = -109, y = 160, create = Alcool},
		{x = 781, y = 320, create = Alcool},
		{x = 1544, y = 519, create = Alcool},
		{x = 429, y = 781, create = Alcool},
		{x = 85, y = 720, create = Alcool}
	}
	hearts = {
		{x = 45, y = 184, create = Heart},
		{x = 264, y = 455, create = Heart},
		{x = 1454, y = 246, create = Heart},
		{x = 1498, y = 592, create = Heart},
		{x = 1219, y = 568, create = Heart},
		{x = 1271, y = 843, create = Heart},
		{x = 914, y = 864, create = Heart},
		{x = -67, y = 720, create = Heart}
	}
	masks = {
		{x = 563, y = -51, create = Mask},
		{x = 305, y = 184, create = Mask},
		{x = 1100, y = 573, create = Mask},
		{x = 1497, y = 880, create = Mask}
	}
	boxes = {
		{x = 612, y = 180, create = Box},
		{x = 98, y = 320, create = Box},
		{x = 548, y = 320, create = Box},
		{x = 815, y = 320, create = Box},
		{x = 1113, y = 176, create = Box},
		{x = 1454, y = 288, create = Box},
		{x = 745, y = 912, create = Box},
		{x = 259, y = 848, create = Box},
		{x = -24, y = 944, create = Box}
	}
	enemies = {
		{x = 780, y = 42, create = Enemy},
		{x = 699, y = 13, create = Enemy},
		{x = 725, y = 43, create = Enemy},
		{x = 700, y = 43, create = Enemy},
		{x = 669, y = 39, create = Enemy},
		{x = 613, y = 39, create = Enemy},
		{x = 734, y = 85, create = Enemy},
		{x = 802, y = 91, create = Enemy},
		{x = 810, y = 179, create = Enemy},
		{x = 693, y = 121, create = Enemy},
		{x = 624, y = 89, create = Enemy},
		{x = 658, y = 180, create = Enemy},
		{x = 707, y = 180, create = Enemy},
		{x = 563, y = 95, create = Enemy},
		{x = 494, y = 100, create = Enemy},
		{x = 575, y = 183, create = Enemy},
		{x = 506, y = 168, create = Enemy},
		{x = 459, y = 168, create = Enemy},
		{x = 371, y = 181, create = Enemy},
		{x = 528, y = 28, create = Enemy},
		{x = 462, y = 48, create = Enemy},
		{x = 398, y = 33, create = Enemy},
		{x = 332, y = -52, create = Enemy},
		{x = 332, y = -22, create = Enemy},
		{x = 291, y = -22, create = Enemy},
		{x = 237, y = -22, create = Enemy},
		{x = 219, y = 10, create = Enemy},
		{x = 181, y = 42, create = Enemy},
		{x = 133, y = -7, create = Enemy},
		{x = 73, y = 36, create = Enemy},
		{x = 46, y = 19, create = Enemy},
		{x = 46, y = 48, create = Enemy},
		{x = 57, y = -21, create = Enemy},
		{x = -68, y = 4, create = Enemy},
		{x = -54, y = 41, create = Enemy},
		{x = -111, y = 15, create = Enemy},
		{x = -109, y = 99, create = Enemy},
		{x = -109, y = 184, create = Enemy},
		{x = -51, y = 160, create = Enemy},
		{x = 8, y = 182, create = Enemy},
		{x = 58, y = 166, create = Enemy},
		{x = 95, y = 166, create = Enemy},
		{x = 95, y = 184, create = Enemy},
		{x = 164, y = 177, create = Enemy},
		{x = 234, y = 177, create = Enemy},
		{x = 281, y = 154, create = Enemy},
		{x = 333, y = 169, create = Enemy},
		{x = 324, y = 123, create = Enemy},
		{x = 273, y = 122, create = Enemy},
		{x = 273, y = 84, create = Enemy},
		{x = 327, y = 84, create = Enemy},
		{x = -23, y = 221, create = Enemy},
		{x = 85, y = 232, create = Enemy},
		{x = 88, y = 281, create = Enemy},
		{x = 45, y = 281, create = Enemy},
		{x = -72, y = 290, create = Enemy},
		{x = -108, y = 277, create = Enemy},
		{x = -106, y = 374, create = Enemy},
		{x = -27, y = 361, create = Enemy},
		{x = 16, y = 361, create = Enemy},
		{x = -63, y = 396, create = Enemy},
		{x = -32, y = 451, create = Enemy},
		{x = 23, y = 416, create = Enemy},
		{x = 52, y = 395, create = Enemy},
		{x = 88, y = 451, create = Enemy},
		{x = 178, y = 395, create = Enemy},
		{x = 136, y = 405, create = Enemy},
		{x = 136, y = 451, create = Enemy},
		{x = 219, y = 455, create = Enemy},
		{x = 337, y = 455, create = Enemy},
		{x = 216, y = 320, create = Enemy},
		{x = 371, y = 309, create = Enemy},
		{x = 315, y = 274, create = Enemy},
		{x = 271, y = 280, create = Enemy},
		{x = 305, y = 216, create = Enemy},
		{x = 129, y = 216, create = Enemy},
		{x = 382, y = 423, create = Enemy},
		{x = 420, y = 359, create = Enemy},
		{x = 405, y = 456, create = Enemy},
		{x = 550, y = 440, create = Enemy},
		{x = 562, y = 374, create = Enemy},
		{x = 393, y = 313, create = Enemy},
		{x = 372, y = 291, create = Enemy},
		{x = 404, y = 234, create = Enemy},
		{x = 572, y = 222, create = Enemy},
		{x = 530, y = 263, create = Enemy},
		{x = 526, y = 297, create = Enemy},
		{x = 570, y = 313, create = Enemy},
		{x = 461, y = 281, create = Enemy},
		{x = 699, y = 278, create = Enemy},
		{x = 699, y = 314, create = Enemy},
		{x = 634, y = 312, create = Enemy},
		{x = 616, y = 265, create = Enemy},
		{x = 638, y = 223, create = Enemy},
		{x = 754, y = 234, create = Enemy},
		{x = 781, y = 251, create = Enemy},
		{x = 812, y = 265, create = Enemy},
		{x = 766, y = 295, create = Enemy},
		{x = 612, y = 438, create = Enemy},
		{x = 617, y = 381, create = Enemy},
		{x = 691, y = 456, create = Enemy},
		{x = 771, y = 456, create = Enemy},
		{x = 808, y = 432, create = Enemy},
		{x = 749, y = 398, create = Enemy},
		{x = 782, y = 383, create = Enemy},
		{x = 818, y = 352, create = Enemy},
		{x = 1120, y = 101, create = Enemy},
		{x = 1252, y = 101, create = Enemy},
		{x = 1221, y = 162, create = Enemy},
		{x = 1148, y = 162, create = Enemy},
		{x = 1530, y = 278, create = Enemy},
		{x = 1490, y = 312, create = Enemy},
		{x = 1457, y = 571, create = Enemy},
		{x = 1503, y = 571, create = Enemy},
		{x = 1546, y = 571, create = Enemy},
		{x = 1168, y = 573, create = Enemy},
		{x = 1183, y = 624, create = Enemy},
		{x = 1242, y = 582, create = Enemy},
		{x = 1242, y = 619, create = Enemy},
		{x = 1574, y = 855, create = Enemy},
		{x = 1483, y = 855, create = Enemy},
		{x = 1540, y = 880, create = Enemy},
		{x = 1171, y = 845, create = Enemy},
		{x = 1202, y = 880, create = Enemy},
		{x = 1230, y = 876, create = Enemy},
		{x = 1237, y = 843, create = Enemy},
		{x = 784, y = 870, create = Enemy},
		{x = 868, y = 870, create = Enemy},
		{x = 746, y = 864, create = Enemy},
		{x = 615, y = 696, create = Enemy},
		{x = 730, y = 696, create = Enemy},
		{x = 672, y = 720, create = Enemy},
		{x = 429, y = 816, create = Enemy},
		{x = 258, y = 819, create = Enemy},
		{x = 312, y = 836, create = Enemy},
		{x = 357, y = 847, create = Enemy},
		{x = 94, y = 944, create = Enemy},
		{x = -4, y = 944, create = Enemy},
		{x = -92, y = 678, create = Enemy},
		{x = -6, y = 705, create = Enemy},
		{x = 79, y = 682, create = Enemy}
	}
	doors = {
		{x = 641, y = 0, pl_x = 1185, pl_y = 97, create = Door},
		{x = 1185, y = 81, pl_x = 641, pl_y = 16, create = Door},

		{x = 434, y = 128, pl_x = 1481, pl_y = 233, create = Door},
		{x = 1481, y = 217, pl_x = 434, pl_y = 144, create = Door},

		{x = 417, y = 8, pl_x = 1497, pl_y = 514, create = Door},
		{x = 1497, y = 496, pl_x = 417, pl_y = 16, create = Door},

		{x = 496, y = 8, pl_x = 1097, pl_y = 624, create = Door},
		{x = 1097, y = 640, pl_x = 496, pl_y = 16, create = Door},

		{x = -23, y = 128, pl_x = 1537, pl_y = 801, create = Door},
		{x = 1537, y = 785, pl_x = -23, pl_y = 144, create = Door},

		{x = 57, y = 128, pl_x = 1097, pl_y = 856, create = Door},
		{x = 1081, y = 856, pl_x = 57, pl_y = 144, create = Door},

		{x = -17, y = 306, pl_x = 823, pl_y = 911, create = Door},
		{x = 823, y = 927, pl_x = -17, pl_y = 322, create = Door},

		{x = 306, y = 424, pl_x = 672, pl_y = 647, create = Door},
		{x = 672, y = 631, pl_x = 306, pl_y = 440, create = Door},

		{x = 225, y = 424, pl_x = 353, pl_y = 777, create = Door},
		{x = 353, y = 761, pl_x = 225, pl_y = 440, create = Door},

		{x = 169, y = 288, pl_x = 32, pl_y = 904, create = Door},
		{x = 32, y = 888, pl_x = 169, pl_y = 304, create = Door},

		{x = 233, y = 288, pl_x = 1, pl_y = 633, create = Door},
		{x = 1, y = 617, pl_x = 233, pl_y = 304, create = Door}
	}
	coins = {
		{x = 377, y = 111, create = Coin},
		{x = 263, y = -56, create = Coin},
		{x = 183, y = 10, create = Coin},
		{x = 133, y = 42, create = Coin},
		{x = 158, y = -56, create = Coin},
		{x = 97, y = -7, create = Coin},
		{x = 97, y = 44, create = Coin},
		{x = 9, y = -6, create = Coin},
		{x = 16, y = 37, create = Coin},
		{x = -108, y = -56, create = Coin},
		{x = -60, y = 361, create = Coin},
		{x = 96, y = 352, create = Coin},
		{x = -71, y = 412, create = Coin},
		{x = -110, y = 444, create = Coin},
		{x = 23, y = 449, create = Coin},
		{x = 88, y = 419, create = Coin},
		{x = 168, y = 355, create = Coin},
		{x = 136, y = 423, create = Coin},
		{x = 163, y = 455, create = Coin},
		{x = 299, y = 455, create = Coin},
		{x = 262, y = 320, create = Coin},
		{x = 298, y = 309, create = Coin},
		{x = 289, y = 247, create = Coin},
		{x = 336, y = 247, create = Coin},
		{x = 172, y = 221, create = Coin},
		{x = 388, y = 389, create = Coin},
		{x = 450, y = 391, create = Coin},
		{x = 578, y = 456, create = Coin},
		{x = 562, y = 398, create = Coin},
		{x = 578, y = 352, create = Coin},
		{x = 376, y = 256, create = Coin},
		{x = 376, y = 225, create = Coin},
		{x = 1447, y = 312, create = Coin},
		{x = 693, y = 720, create = Coin},
		{x = 649, y = 708, create = Coin}
	}
	npcs = {
		{x = 716, y = -22, dialog = dialog_npc, create = NPC},
		{x = 490, y = 224, dialog = dialog_npc, create = NPC},
		{x = 1452, y = 523, dialog = dialog_npc, create = NPC}
	}

	create_objects(alcools, round_4.Alcools)
	create_objects(hearts, round_4.Hearts)
	create_objects(masks, round_4.Masks)
	create_objects(boxes, round_4.Boxes)
	create_objects(enemies, round_4.Enemies)
	create_objects(doors, round_4.Doors)
	create_objects(coins, round_4.Coins)
	create_objects(npcs, round_4.Npcs)

	round_5 = Round(673, 440, 815, 449, 4, constants.ROUND_5)

	round_1.next_round = round_2
	round_2.next_round = round_3
	round_3.next_round = round_4
	round_4.next_round = round_5
end

function initialize()
	cam = {
		x = 0,
		y = 0
	}

	local sword_init = Sword(0, 0)

--[[
	end_game = {
		sprite = tiles.END_GAME,
		x =	8,
		y = 60,
		background = 1,
		visible = true,
		make_collisions = {
			ENEMY = function() return false end,
			PLAYER = final_match,
			SWORD = function() return false end
		}
	}
]]--
	create_rounds()
	round_actual = round_4
	round_actual.sync_round()

	player = Player(round_actual.player_x, round_actual.player_y, sword_init)
end

local function update_window_final(time)
	if btn(4) then
		initialize()
		window = Window.MENU
	end
end

local function draw_end_game()
	cls()
	print("Você conseguiu escapar!", 56, 40)
	print("Pressione 'z' para reiniciar o jogo", 40, 85)
end

local function update_transaction_round()
	round_actual.t = round_actual.t + 1
end

local function draw_transaction()
	if round_actual.t < 2 * 15 then
		return
	elseif round_actual.timeout > 0 then
		cls()
		print("Loading..", CAM_W/2-22, CAM_H/2-18)

		round_actual.timeout = round_actual.timeout - 1
	elseif round_actual.timeout == 0 then
		round_actual.reset()
		window = Window.GAME
		round_actual.timeout = 30
		round_actual.t = 0
	end
end

local function update_game_over()
	if btnp(4) or btnp(5) then
		if btn(5) then
			initialize()

			round_actual = round_1
			player.x = round_actual.player_x
			player.y = round_actual.player_y
			round_actual.sync_round()
		else
			create_rounds()
			if round_actual.tag == round_1.tag then round_actual = round_1 end
			if round_actual.tag == round_2.tag then round_actual = round_2 end
			if round_actual.tag == round_3.tag then round_actual = round_3 end
			if round_actual.tag == round_4.tag then round_actual = round_4 end
			if round_actual.tag == round_5.tag then round_actual = round_5 end

			player.health = 3
			player.x = round_actual.player_x
			player.y = round_actual.player_y
		end

		window = Window.GAME
	end
end

local function draw_game_over()
	cls()
	print("Voce morreu!", CENTER_WIDTH, CAM_H/2-18)
	print("Pontos: "..player.score, CENTER_WIDTH+10, CENTER_HEIGHT+10)

	print("Pressione [x] para reiniciar", 20, CENTER_HEIGHT+30)
	print("Pressione [z] para ultimo ponto de controle", 10, CENTER_HEIGHT+40)
end

function TIC()
	window.update(t)
	window.draw()

--[[
	print(cam.x, 0, 30)
	print(cam.y, 0, 40)
	print(15 - (cam.x / CELL + (cam.x % CELL == 0 and 1 or 0)), 0, 60)
	print(8 - (cam.y / CELL + (cam.y % CELL == 0 and 1 or 0)), 0, 70)
	print((cam.x % CELL) - CELL, 0, 90)
	print((cam.y % CELL) - CELL, 0, 100)
]]--

	print(player.x, 0, 120)
	print(player.y, 0, 130)

	t = t + 1
end

Window = {
	MENU = {
	  update = update_window,
		draw = draw_menu
	},

	GAME = {
		update = update_game,
		draw = draw_game
	},

	TRANSACTION_ROUND = {
		update = update_transaction_round,
		draw = draw_transaction
	},

	GAME_OVER = {
		update = update_game_over,
		draw = draw_game_over
	},

	END_GAME = {
		update = update_window_final,
		draw = draw_end_game
	}
}

window = Window.MENU
initialize()