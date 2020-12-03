-- title:  Coronga;
-- author: Douglas, Richard e Otavio;
-- desc: RPG acao 2d;
-- script: lua.

local CAM_W, CAM_H, CELL, DRAW_X, DRAW_Y = 240, 136, 8, 120, 64
local CENTER_WIDTH, CENTER_HEIGHT, t = (CAM_W/2-30), (CAM_H/2-18), 0
local states_enemy = {
	STOP = "STOP",
	PURSUIT = "PURSUIT",
	NONE = "NONE"
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
local sound_effects = {DOOR = 1, INIT = 3, SWORD = 4, END_GAME = 5}
local const_direction = {UP = 1, DOWN = 2, LEFT = 3, RIGHT = 4}
local const_status_door = {CLOSED = 96,	OPENED = 98}
local constants = {
	VIEW_ENEMY = 50, SPEED_ENEMY = 0.5,

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
	BOX = "BOX",
	DOOR = "DOOR",

	STEP_1 = "STEP_1", STEP_2 = "STEP_2", STEP_3 = "STEP_3", STEP_4 = "STEP_4", STEP_5 = "STEP_5"
}
local player, window, end_game, dialog, dialog_pos, text_pos, menu = {}, {}, {}, nil, 1, 1, {item = 0}
local step_actual, step_1, step_2, step_3, step_4, step_5 = {}, {}, {}, {}, {}, {}
local end_game = nil

local round = math.floor

local function is_collision_objects(object_a, object_b)
	return math.abs(math.floor(object_a.x-object_b.x)) < CELL	and math.abs(math.floor(object_a.y-object_b.y)) < CELL
end

local function start_dialog()
	if dialog ~= nil and dialog[dialog_pos] ~= nil then
		local str = dialog[dialog_pos]
		local len = string.len(str)

		if btnp(5) and text_pos >= 2 then
			if text_pos < len then
				text_pos = len
		  else
			  text_pos = 1
			  dialog_pos = dialog_pos+1
			end
		end

	  if dialog_pos <= #dialog then
		  rect(5, 105, 230, 30, 5)
			rectb(5, 105, 230, 30, 15)
		  print(string.sub(str, 1, text_pos), 10, 110, 15, false, 1, true)

			if text_pos < len and t%4 == 0 then text_pos = text_pos+1 end
		else
		  dialog_pos = 1
			dialog = nil
		end

		if dialog	and dialog_pos == #dialog then
			if btnp(0) then	menu.item = 0
			elseif btnp(1) then	menu.item = 1 end

			spr(364, 7, 115+menu.item*5, 14)

			if btnp(4) then
				if menu.item == 0 then
					if player.coins - 10 >= 0 and player.shield + 1 <= player.max_shield then
						if player.shield + 2 <= player.max_shield then
							player.shield = player.shield + 2
						else
							player.shield = player.shield + 1
						end
						player.coins = player.coins - 10
					end

					player.buy_mask = true
				elseif menu.item == 1 then
					if player.coins - 5 >= 0 and player.health + 1 <= player.max_health then
						player.health = player.health + 1
						player.coins = player.coins - 5
					end

					player.buy_life = true
				end
			end
		end
	end
end

local function check_collision_objects(personal, newPosition, time)
	if personal.tag == constants.PLAYER then
		for _, box in pairs(step_actual.Boxes) do
			if is_collision_objects(newPosition, box) then return box.make_collision_box_with_player(time) end
		end
		for _, door in pairs(step_actual.Doors) do
			if is_collision_objects(newPosition, door) then return door.make_collision_door_with_player(time) end
		end
		for i, coin in pairs(step_actual.Coins) do
			if is_collision_objects(newPosition, coin) then return coin.make_collision_coin_with_player(i) end
		end
		for i, alcool in pairs(step_actual.Alcools) do
			if is_collision_objects(newPosition, alcool) then return alcool.make_collision_alcool_with_player(i) end
		end
		for i, heart in pairs(step_actual.Hearts) do
			if is_collision_objects(newPosition, heart) then return heart.make_collision_heart_with_player(i) end
		end
		for i, mask in pairs(step_actual.Masks) do
			if is_collision_objects(newPosition, mask) then return mask.make_collision_mask_with_player(i) end
		end
	end

	for _, npc in pairs(step_actual.Npcs) do
		if is_collision_objects(newPosition, npc) then
			if personal.tag == constants.PLAYER then return npc.make_collision_npc_with_player() 
			elseif personal.tag == constants.SWORD then return npc.make_collision_npc_with_sword() end
		end
	end

	for i, enemy in pairs(step_actual.Enemies) do
		if is_collision_objects(newPosition, enemy) then
			if personal.tag == constants.PLAYER then return enemy.make_collision_enemy_with_player(i) 
			elseif personal.tag == constants.SWORD then return enemy.make_collision_enemy_with_sword(i) end
		end
	end

	if step_actual.next_round and is_collision_objects(newPosition, step_actual.next_round) then
		return step_actual.update_step()
	end

	if step_actual.tag == constants.STEP_5 and end_game ~= nil and is_collision_objects(newPosition, end_game) then
		return end_game.make_collision()
	end

	return false
end

local function distancy(e, p)
	return math.max(math.abs(e.x-p.x), math.abs(e.y-p.y))
end

local function lerp(a, b, q)
	return (1 - q) * a + q * b
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
		tl = {x=0, y=0},
		tr = {x=0, y=0},
		bl = {x=0, y=0},
		br = {x=0, y=0},
		new_position = {}
	}

	function self.is_collision(point)
		return mget((point.x/CELL)+(CELL*2), (point.y/CELL)+(CELL+1)) >= 128
	end

	function self.check_water(point)
		local px, py = (point.x/CELL)+(CELL*2), (point.y/CELL)+(CELL+1)

		return mget(px, py) == 34 or mget(px, py) == 35 or mget(px, py) == 50 or mget(px, py) == 51
	end

	function self.move(personal, delta, direction_actual, time)
		self.new_position.x = personal.x+delta.x
		self.new_position.y = personal.y+delta.y

		if check_collision_objects(personal, self.new_position, time) then
			return false
		end

		self.tl.x = personal.x-7+delta.x
		self.tl.y = personal.y-8+delta.y
		self.tr.x = personal.x+5+delta.x
		self.tr.y = personal.y-8+delta.y
		self.br.x = personal.x+5+delta.x
		self.br.y = personal.y+7+delta.y
		self.bl.x = personal.x-7+delta.x
		self.bl.y = personal.y+7+delta.y

		if not self.is_collision(self.tl)
		and not self.is_collision(self.tr)
		and not self.is_collision(self.br)
		and not self.is_collision(self.bl) then
			if personal.curAnim
			and personal.curAnim.ended then
				personal.curAnim.reset()
			end

			personal.x = personal.x+delta.x
			personal.y = personal.y+delta.y
			personal.direction = direction_actual
		end
	end

	function self.draw()
		if self.visible then
			local block_x, block_y = round(cam.x+self.x), round(cam.y+self.y)

			spr(self.sprite, block_x, block_y, self.background, 1, 0, 0, 2, 2)
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
		if time >= self.tick and #self.frames > 0 then
			if self.loop then
				self.indx = (self.indx+1)%#self.frames
				self.frame = self.frames[self.indx+1]
				self.ended = false
			else
				self.indx = self.indx < #self.frames and self.indx+1 or #self.frames
				self.frame = self.frames[self.indx]

				if self.indx == #self.frames then self.ended = true end
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
		player.coins = player.coins+self.coins
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
	self.visible = true

	function self.update(time)
		if self.collided then
			window = Window.TRANSACTION_ROUND
			self.home()
		end

		return true
	end

	function self.draw()
		if self.collided then return end
	end

	function self.make_collision_door_with_player()
		local pos_x, pos_y = (self.x/CELL)+(CELL*2), (self.y/CELL)+(CELL+1)
		self.collided = true

		mset(pos_x-1, pos_y-1, 102)
		mset(pos_x, pos_y-1, 103)
		mset(pos_x-1, pos_y, 118)
		mset(pos_x, pos_y, 119)

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
		player.coins = player.coins+1
		table.remove(step_actual.Coins, index)

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
		if player.shield + 1 <= player.max_shield then
			player.shield = player.shield+1
			table.remove(step_actual.Alcools, index)

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
		if player.health + 1 <= player.max_health then
			player.health = player.health + 1
			table.remove(step_actual.Hearts, index)

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
		if player.shield + 1 <= player.max_shield then
			if player.shield + 2 <= player.max_shield then player.shield = player.shield + 2
			else player.shield = player.shield + 1 end
			table.remove(step_actual.Masks, index)

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
	self.state = states_enemy.NONE
	self.visible = true

	function self.update(time)
		if distancy(self, player) < constants.VIEW_ENEMY
		and not self.check_water(player.bl) and not self.check_water(player.br) then
			self.state = states_enemy.PURSUIT
			static = false
		else
			self.state = states_enemy.STOP
		end

		if self.state == states_enemy.PURSUIT then
			self.dx, self.dy = 0, 0

			if round(player.y) > round(self.y) then
				self.dy = constants.SPEED_ENEMY

				if round(player.x) == round(self.x) then
					self.direction = const_direction.DOWN
				end
			elseif round(player.y) < round(self.y) then
				self.dy = -constants.SPEED_ENEMY

				if round(player.x) == round(self.x) then
					self.direction = const_direction.UP
				end
			end

			self.move(self, {x = self.dx, y = self.dy}, self.direction, time)

			self.dx, self.dy = 0, 0

			if round(player.x) > round(self.x) then
				self.dx = constants.SPEED_ENEMY
				self.direction = const_direction.RIGHT
			elseif round(player.x) < round(self.x) then
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
		table.remove(step_actual.Enemies, index)
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
			table.remove(step_actual.Enemies, index)
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
		Anim(10, {322, 324}, false), Anim(10, {334, 328}, false),
		Anim(10, {322, 320}, false), Anim(10, {330, 332}, false)
	}
	self.delta = {{x=0, y=-10}, {x=0, y=10}, {x=-10, y=0}, {x=10, y=0}}
	self.curAnim = nil
	self.visible = false
	self.timeout = 0

	function self.draw()
		if player.damaged
		and (time()//250) % 2 ~= 0 then
			return
		end

		if self.visible then
			local block_x, block_y = round(cam.x + self.x), round(cam.y + self.y)
			spr(self.sprite, block_x,	block_y, self.background, 1, 0, 0, 2, 2)
		end
	end

	function self.update(time)
		if player.direction then
			self.x = player.x+self.delta[player.direction].x
			self.y = player.y+self.delta[player.direction].y
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

local function Step(x,	y,	player_x,	player_y,	map, tag)
	local self = Base()
	self.tag, self.srite = tag, tiles.DOOR
	self.x, self.y = x, y
	self.player_x, self.player_y = player_x, player_y
	self.background = 0
	self.visible = true
	self.map = map
	self.timeout, self.t = 30, 0
	self.Coins, self.Enemies, self.Doors, self.Boxes = {}, {}, {}, {}
	self.Alcools, self.Hearts, self.Masks, self.Npcs = {}, {}, {}, {}
	self.next_round = nil

	function self.update_step()
		window = Window.TRANSACTION_ROUND
		step_actual = self.next_round

		if step_actual.tag == constants.STEP_5 then
			end_game = {
				sprite = tiles.END_GAME,
				x =	233,
				y = 304,
				background = 1,
				visible = true,
				make_collision = final_match
			}
		end

		player.x, player.y = step_actual.player_x, step_actual.player_y
		constants.SPEED_ENEMY = constants.SPEED_ENEMY+0.1
		self.sync_step()
	end

	function self.sync_step()
		sync(4, step_actual.map)
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
	self.tag, self.sprite = constants.NPC, tiles.NPC
	self.x, self.y = x,	y
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

	function self.make_collision_npc_with_sword()
		window = Window.NPC_DIED

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
	self.max_health = 8
	self.shield = 0
	self.max_shield = 5
	self.coins = 0
	self.score = 0
	self.anims = {
		up = Anim(9, {256, 258}, false), down = Anim(9, {260, 262}, false),
		left = Anim(9, {264, 266}, false), right = Anim(9, {268, 270}, false),
		up_water = Anim(9, {396, 398}, false), down_water = Anim(9, {428, 430}, false),
		left_water = Anim(9, {460, 462}, false), right_water = Anim(9, {492, 494}, false)
	}
	self.delta = {{x = 0, y = -1}, {x = 0, y = 1}, {x = -1, y = 0}, {x = 1, y = 0}}
	self.curAnim = nil
	self.damaged = false
	self.buy_life = false
	self.buy_mask = false
	self.timeout = 30
	self.buy_life_t = 30
	self.buy_mask_t = 30

	function self.draw()
		player.sword.draw()

		local block_x, block_y = (cam.x + self.x), (cam.y + self.y)

		if self.damaged and (time()//250) % 2 ~= 0 and self.timeout > 0 then
			self.timeout = self.timeout - 1
			return
		elseif self.timeout == 0 then
			self.damaged = false
			self.timeout = 30
		end

		spr(self.sprite, block_x,	block_y, self.background, 1, 0, 0, 2, 2)
	end

	function self.update(time)
		if dialog == nil then
			for keyword = 0, 3 do
				if btn(keyword) then
					if btn(0) then self.curAnim = self.anims.up	end
					if btn(1) then self.curAnim = self.anims.down	end
					if btn(2) then self.curAnim = self.anims.left	end
					if btn(3) then self.curAnim = self.anims.right end

					self.direction = keyword+1
					if self.check_water(self.tl) and self.check_water(self.tr)
					and self.check_water(self.bl) and self.check_water(self.br) then
						self.delta = {{x = 0, y = -0.5}, {x = 0, y = 0.5}, {x = -0.5, y = 0}, {x = 0.5, y = 0}}

						if self.direction == 1 then	self.curAnim = self.anims.up_water end
						if self.direction == 2 then self.curAnim = self.anims.down_water end
						if self.direction == 3 then self.curAnim = self.anims.left_water end
						if self.direction == 4 then self.curAnim = self.anims.right_water end
					else
						self.delta = {{x = 0, y = -1}, {x = 0, y = 1}, {x = -1, y = 0}, {x = 1, y = 0}}
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

local function draw_life(h_s_p)
	if player.buy_life and (time()//250) % 2 ~= 0 and player.buy_life_t > 0 then
		player.buy_life_t = player.buy_life_t - 1
		return
	elseif player.buy_life_t == 0 then
		player.buy_life = false
		player.buy_life_t = 30
	end

	for _ = 1, player.health do
		h_s_p = h_s_p+1
		spr(tiles.HEALTH,	CELL*(h_s_p - 1), CELL, 14)
	end

	for _ = 1, player.max_health - player.health do
		h_s_p = h_s_p+1
		spr(tiles.EMPTY_H_S, CELL*(h_s_p - 1), CELL, 14)
	end
end

local function draw_shield(h_s_p)
	if player.buy_mask and (time()//250) % 2 ~= 0 and player.buy_mask_t > 0 then
		player.buy_mask_t = player.buy_mask_t - 1
		return
	elseif player.buy_mask_t == 0 then
		player.buy_mask = false
		player.buy_mask_t = 30
	end

	for i = 1, player.shield do
		h_s_p = h_s_p+1
		spr(tiles.SHIELD,	CELL*(i - 1),	CELL*2, 14)
	end
	for _ = 1, player.max_shield - player.shield do
		h_s_p = h_s_p+1
		spr(tiles.EMPTY_H_S, CELL*(h_s_p - 1), CELL*2, 14)
	end
end

local function DisplayHUD()
	local h_s, step = 0

	print(constants.SCORE..player.score, 0, 0)

	if step_actual.tag == constants.STEP_1 then step = 1
	elseif step_actual.tag == constants.STEP_2 then step = 2
	elseif step_actual.tag == constants.STEP_3 then step = 3
	elseif step_actual.tag == constants.STEP_4 then step = 4
	elseif step_actual.tag == constants.STEP_5 then step = 5 end

	print("Fase: "..step, (CAM_W/2)-CELL, 0)

	draw_life(h_s)
	h_s = 0
	draw_shield(h_s)

	if player.coins > 0 then
		print(constants.COINS_PLAYER..player.coins, CAM_W - (CELL * 7), 0)
	end
end

local function draw_map()
	local ccx = cam.x/CELL+(cam.x%CELL == 0 and 1 or 0)
	local ccy = cam.y/CELL+(cam.y%CELL == 0 and 1 or 0)

  map(15-ccx, 8-ccy, 31, 18, (cam.x % CELL)-CELL, (cam.y % CELL)-CELL)
end

local function update_cam()
	cam.x = math.min(DRAW_X, lerp(cam.x, DRAW_X-player.x, 0.05))
  cam.y = math.min(DRAW_Y, lerp(cam.y, DRAW_Y-player.y, 0.05))
end

local function update_game(time)
	player.update(time)
	check_collision_objects(player, player, time)
	step_actual.update(time)
	update_cam()
end

local function update_window(time)
	if btn(4) then window = Window.GAME end
end

local function final_match()
	window = Window.END_GAME
end

local function draw_objects()
	step_actual.draw()
end

local function draw_menu()
	cls()

	spr(448, 75, 30, 0,	1, 0, 0, 10, 10)

	if (time()//800) % 2 == 0 then print("Press [z]", 90, 90)	end

	print(constants.ABOUT, 5, 128)
end

local function draw_help()
	if btn(6) then
		print("Z - Atacar", 80, 90)
		print("X - Interagir", 80, 100)
	end
end

local function draw_game()
	cls()

	draw_map()
	draw_objects()

	player.draw()
	start_dialog()
	DisplayHUD()
	draw_help()
end

function initialize()
	cam = {x = 0, y = 0}

	create_rounds()
	step_actual = step_1
	step_actual.sync_step()

	player = Player(step_actual.player_x, step_actual.player_y, Sword(0, 0))
end

local function update_window_end_game(time)
	if btn(4) then
		initialize()
		window = Window.MENU
	end
end

local function draw_end_game()
	cls()
	print("Voce conseguiu escapar!", 56, 40)
	print("Pontos ganhos: "..player.score, 40, 65)
	print("Press [z] para reiniciar o jogo", 20, 805)
end

local function update_transaction_round()
	step_actual.t = step_actual.t + 1
end

local function draw_transaction()
	if step_actual.t < 2 * 15 then
		return
	elseif step_actual.timeout > 0 then
		cls()
		print("Carregando..", CAM_W/2-22, CAM_H/2-18)

		step_actual.timeout = step_actual.timeout - 1
	elseif step_actual.timeout == 0 then
		step_actual.reset()
		window = Window.GAME
		step_actual.timeout = 30
		step_actual.t = 0
	end
end

local function update_game_over()
	if btnp(4) or btnp(5) then
		if btn(5) then
			initialize()

			step_actual = step_1
			player.x = step_actual.player_x
			player.y = step_actual.player_y
			step_actual.sync_step()
		else
			create_rounds()
			if step_actual.tag == step_1.tag then step_actual = step_1 end
			if step_actual.tag == step_2.tag then step_actual = step_2 end
			if step_actual.tag == step_3.tag then step_actual = step_3 end
			if step_actual.tag == step_4.tag then step_actual = step_4 end
			if step_actual.tag == step_5.tag then step_actual = step_5 end

			player.health = 3
			player.x = step_actual.player_x
			player.y = step_actual.player_y
		end

		window = Window.GAME
	end
end

local function draw_game_over()
	cls()
	print("Voce morreu!", CENTER_WIDTH, CAM_H/2-18)
	print("Pontos: "..player.score, CENTER_WIDTH+5, CENTER_HEIGHT+10)

	print("Press [x] reiniciar", 70, CENTER_HEIGHT+30)
	print("Press [z] ultimo ponto de controle", 25, CENTER_HEIGHT+40)
end

local function draw_npc_died()
	cls()
	print("Voce matou um aliado!", CENTER_WIDTH-30, CAM_H/2-18)
	print("Pontos: "..player.score, CENTER_WIDTH+10, CENTER_HEIGHT+10)

	print("Press [z] reiniciar", 80, CENTER_HEIGHT+30)
end

local function update_npc_died()
	if btnp(4) then
		initialize()

		step_actual = step_1
		player.x = step_actual.player_x
		player.y = step_actual.player_y
		step_actual.sync_step()

		window = Window.GAME
	end
end

function TIC()
	window.update(t)
	window.draw()

--	print(player.x, 0, 120)
--	print(player.y, 0, 130)

	t = t + 1
end

function create_rounds()
	local dialog_npc = {
		"Bom dia! Eu sou mercador.",
		"O que desejas comprar?".."\n"..
		"				Mascara (10 moedas).".."\n"..
		"				Vida (5 moedas)."
	}

	step_1 = Step(0, 0, -109, 936, 0, constants.STEP_1)
	step_1.Alcools = {
		Alcool(376, 669),
		Alcool(-97, 174),
		Alcool(979, 173),
		Alcool(-111, 999),
		Alcool(1527, 39)
	}
	step_1.Hearts = {
		Heart(329, 902),
		Heart(568, 286),
		Heart(1426, -1),
		Heart(1529, 855)
	}
	step_1.Masks = {
		Mask(297, 90),
		Mask(1174, 637),
		Mask(91, 491)
	}
	step_1.Boxes = {
		Box(94, 764),
		Box(267, 90),
		Box(330, 90),
		Box(1041, 99),
		Box(610, 627),
		Box(1530, 270),
		Box(1105, 953),
		Box(1530, 584),
		Box(1530, 498),
		Box(1098, 835)
	}
	step_1.Enemies = {
		Enemy(96, 896), 
		Enemy(96, 1000), 
		Enemy(336, 801),
		Enemy(510, 1000), 
		Enemy(816, 970), 
		Enemy(760, 1000),
		Enemy(616, 809), 
		Enemy(576, 809), 
		Enemy(471, 786),
		Enemy(396, 672), 
		Enemy(371, 625), 
		Enemy(538, 665),
		Enemy(573, 728), 
		Enemy(635, 592), 
		Enemy(814, 513),
		Enemy(386, 488), 
		Enemy(329, 505), 
		Enemy(306, 577),
		Enemy(150, 577),	
		Enemy(189, 560),	
		Enemy(235, 655),
		Enemy(251, 1000), 
		Enemy(190, 735), 
		Enemy(36, 537),
		Enemy(11, 705), 
		Enemy(-10, 592), 
		Enemy(-81, 720),
		Enemy(287, 104), 
		Enemy(223, 764), 
		Enemy(979, 100),
		Enemy(620, 129), 
		Enemy(771, 167), 
		Enemy(944, 119),
		Enemy(-107, 774), 
		Enemy(86, 789), 
		Enemy(-9, 767),
		Enemy(75, 111), 
		Enemy(-48, 172), 
		Enemy(1099, 368),
		Enemy(322, 111), 
		Enemy(469, 277), 
		Enemy(532, 292),
		Enemy(1133, 445), 
		Enemy(628, 632), 
		Enemy(375, 555),
		Enemy(-11, 527), 
		Enemy(85, 728), 
		Enemy(-13, 728),
		Enemy(802, 829), 
		Enemy(1530, 515), 
		Enemy(1530, 564),
		Enemy(1476, 232), 
		Enemy(1466, 302), 
		Enemy(1413, 270),
		Enemy(1137, 635), 
		Enemy(1167, 659), 
		Enemy(1144, 912),
		Enemy(1146, 984), 
		Enemy(1479, 813),	
		Enemy(1380, 813),
		Enemy(1482, 855), 
		Enemy(1392, 16), 
		Enemy(1392, 16),
		Enemy(1455, 21), 
		Enemy(1527, 37),	
		Enemy(1524, -38),
		Enemy(1356, -35),
		Enemy(620, 131)
	}
	step_1.Doors = {
		Door(761,	952, 705, 93),	
		Door(705, 73, 761, 970),
		Door(176,	953, -8, 92), 
		Door(-8, 73, 176, 970),
		Door(73,	849, 297, 175), 
		Door(297,	193, 73, 862),
		Door(169,	849, 370, 288), 
		Door(361,	289, 169, 862),
		Door(497,	954, 1174, 400), 
		Door(1193,	400, 497, 990),
		Door(409,	832, 1341, 536), 
		Door(1320, 536, 409, 848),
		Door(729,	698, 1335, 264), 
		Door(1321, 264, 729, 710),
		Door(489,	546, 1137, 720), 
		Door(1137, 737, 489, 560),
		Door(169,	522, 1195, 944),	
		Door(1209, 944, 169, 540),
		Door(168,	697, 1426, 770),	
		Door(1426, 752, 168, 715),
		Door(-64,	665, 1425, -48),	
		Door(1425, -63, -64, 680)
	}
	step_1.Coins = {
		Coin(1, 936), 
		Coin(-110, 830), 
		Coin(336, 864),
		Coin(336, 760), 
		Coin(570, 787), 
		Coin(451, 816),
		Coin(378, 864), 
		Coin(451, 816), 
		Coin(514, 632),
		Coin(697, 588), 
		Coin(679, 513), 
		Coin(814, 558),
		Coin(281, 505), 
		Coin(209, 592), 
		Coin(211, 696),
		Coin(130, 712), 
		Coin(1009, 169), 
		Coin(620, 174),
		Coin(-99, 109), 
		Coin(79, 174), 
		Coin(378, 586),
		Coin(49, 493), 
		Coin(1412, 230), 
		Coin(1341, 855),
		Coin(1097, 445),
		Coin(621, 174),
		Coin(1527, -35)
	}
	step_1.Npcs = {
		NPC(20, 936, dialog_npc)
	}

	step_2 = Step(-56, 576, -112, -8, 1, constants.STEP_2)
	step_2.Alcools = {
		Alcool(333, 269), 
		Alcool(-104, 403),
		Alcool(1107, 140),	
		Alcool(860, 717)
	}
	step_2.Hearts = {
		Heart(-50, 312),
		Heart(259, 451), 
		Heart(565, 122),	
		Heart(1284, 127), 
		Heart(1099, 88), 
		Heart(1493, 36),
		Heart(1420, 632), 
		Heart(809, 853), 
		Heart(73, 709)
	}
	step_2.Masks = {
		Mask(235, 46),	
		Mask(638, 161), 
		Mask(1000, 992)
	}
	step_2.Boxes = {
		Box(326, 317), 
		Box(1578, 424), 
		Box(1618, 992),
		Box(1249, 920), 
		Box(1046, 720), 
		Box(616, 840),
		Box(985, 944),	
		Box(570, 720)
	}
	step_2.Enemies = {
		Enemy(-17, -37),
		Enemy(-47, 34),
		Enemy(261, -50),  
		Enemy(304, -34),
		Enemy(319, 28),
		Enemy(75, 98),  
		Enemy(44, 139),
		Enemy(91, 177),
		Enemy(-95, 173), 
		Enemy(319, 96),
		Enemy(319, 149),
		Enemy(217, 111),  
		Enemy(217, 153),
		Enemy(177, 140),
		Enemy(330, 222),  
		Enemy(307, 245),
		Enemy(183, 218),
		Enemy(186, 246),  
		Enemy(68, 246),
		Enemy(-91, 231),
		Enemy(-106, 280),  
		Enemy(-97, 365),
		Enemy(-104, 452),
		Enemy(83, 452),  
		Enemy(159, 371),
		Enemy(162, 451),
		Enemy(320, 451),  
		Enemy(329, 370),
		Enemy(404, 451),
		Enemy(413, 362),  
		Enemy(543, 448),
		Enemy(410, 311),
		Enemy(569, 311),  
		Enemy(569, 224),
		Enemy(402, 237),
		Enemy(648, 423),
		Enemy(739, 385),
		Enemy(803, 434),
		Enemy(803, 356),  
		Enemy(811, 272),
		Enemy(728, 310),
		Enemy(619, 301),  
		Enemy(619, 256),
		Enemy(809, 93),
		Enemy(809, 152),  
		Enemy(766, 166),
		Enemy(743, 97),
		Enemy(701, 144),  
		Enemy(651, 103),
		Enemy(811, 19),
		Enemy(775, -53),  
		Enemy(708, -7),
		Enemy(694, 36),
		Enemy(672, 7),  
		Enemy(633, -52),
		Enemy(555, 37),
		Enemy(500, 7),  
		Enemy(407, -47),
		Enemy(419, 99),
		Enemy(569, 177),  
		Enemy(565, 88),
		Enemy(1117, 176),
		Enemy(1279, 176),  
		Enemy(1201, 122),
		Enemy(1160, 106),
		Enemy(1615, 228),  
		Enemy(1615, 308),
		Enemy(1580, 270),
		Enemy(1652, 405),  
		Enemy(1654, 444),
		Enemy(1594, 424),
		Enemy(1695, 808),  
		Enemy(1770, 808),
		Enemy(1594, 953),
		Enemy(1642, 953),
		Enemy(1139, 366),
		Enemy(1215, 374),
		Enemy(1213, 406),  
		Enemy(1223, 441),
		Enemy(1144, 445),
		Enemy(1420, 675),  
		Enemy(1462, 677),
		Enemy(1503, 701),
		Enemy(1375, 689),  
		Enemy(1338, 687),
		Enemy(1226, 949),
		Enemy(1244, 979),  
		Enemy(860, 656),
		Enemy(881, 680),
		Enemy(899, 720),  
		Enemy(1025, 680),
		Enemy(1006, 706),
		Enemy(642, 816), 
		Enemy(771, 816),
		Enemy(750, 856),
		Enemy(673, 852),  
		Enemy(962, 970),
		Enemy(30, 652),
		Enemy(30, 716),  
		Enemy(185, 856),
		Enemy(293, 856),
		Enemy(563, 678),  
		Enemy(522, 642),
		Enemy(518, 710)
	}
	step_2.Doors = {
		Door(48, 9, 1193, 177), 
		Door(1193, 192, 48, 25),
		Door(169, 8, 1489, -16), 
		Door(1489, -32, 169, 24),
		Door(-38, 144, 1657, 272),	
		Door(1673, 272, -38, 160), 
		Door(1560, 272, 1730, 424), 
		Door(1752, 424, 1600, 272),
		Door(-16, 416, 1729, 769),	
		Door(1729, 753, -16, 432),
		Door(56, 416, 1617, 907), 
		Door(1617, 889, 56, 432),
		Door(257, 416, 1097, 400),	
		Door(1081, 400, 257, 432),	
		Door(1304, 400, 1433, 720), 
		Door(1433, 736, 1290, 400),
		Door(457, 440, 1289, 944),	
		Door(1305, 944, 457, 456),
		Door(489, 288, 945, 633), 
		Door(945, 617, 489, 304), 
		Door(953, 736, 712, 833), 
		Door(712, 801, 953, 720),
		Door(728, 440, 1049, 969),	
		Door(1065, 969, 729, 456),
		Door(705, 281, -40, 688), 
		Door(-56, 688, 705, 297),	
		Door(104, 688, 234, 816), 
		Door(232, 801, 90, 688), 
		Door(241, 872, 466, 680),	
		Door(450, 680, 241, 856)
	}
	step_2.Coins = {
		Coin(332, -51), 
		Coin(327, 175), 
		Coin(144, 90),
		Coin(155, 172), 
		Coin(809, 227), 
		Coin(655, 319),
		Coin(619, 221), 
		Coin(615, 87), 
		Coin(755, 44),
		Coin(716, -53), 
		Coin(627, 25), 
		Coin(519, 47),
		Coin(440, 7), 
		Coin(1736, 808), 
		Coin(1182, 366),
		Coin(1251, 374), 
		Coin(1258, 433), 
		Coin(1191, 431),
		Coin(1503, 632)
	}

	step_3 = Step(489, 160, 794, 454, 2, constants.STEP_3)
	step_3.Alcools = {
		Alcool(333, 269), 
		Alcool(1489, 934)
	}
	step_3.Hearts = {
		Heart(610, 456), 
		Heart(-48, 409), 
		Heart(569, 42),
		Heart(772, 48), 
		Heart(1191, -3), 
		Heart(1187, 311),
		Heart(1449, 584), 
		Heart(375, 672)
	}
	step_3.Masks = {
		Mask(380, 299), 
		Mask(-110, 221), 
		Mask(671, 48),
		Mask(1288, 310), 
		Mask(379, 720), 
		Mask(1489, 895)
	}
	step_3.Boxes = {
		Box(614, 222), 
		Box(129, 352), 
		Box(68, 86),
		Box(98, 95), 
		Box(137, 840), 
		Box(1017, 499),
		Box(1449, 912), 
		Box(1217, 856)
	}
	step_3.Enemies = {
		Enemy(682, 433),
		Enemy(691, 456),
		Enemy(814, 356),  
		Enemy(817, 393),
		Enemy(780, 286),
		Enemy(811, 227),  
		Enemy(758, 220),
		Enemy(663, 220),
		Enemy(571, 249),  
		Enemy(520, 228),
		Enemy(505, 252),
		Enemy(393, 234),  
		Enemy(442, 381),
		Enemy(407, 411),
		Enemy(374, 366),  
		Enemy(391, 455),
		Enemy(536, 455),
		Enemy(311, 454),  
		Enemy(269, 368),
		Enemy(206, 453),
		Enemy(133, 440),  
		Enemy(41, 456),
		Enemy(27, 409),
		Enemy(-45, 456),  
		Enemy(-101, 412),
		Enemy(-86, 218),
		Enemy(-86, 237),  
		Enemy(8, 260),
		Enemy(38, 216),
		Enemy(69, 280),  
		Enemy(89, 311),
		Enemy(140, 254),
		Enemy(140, 297),  
		Enemy(194, 320),
		Enemy(274, 320),
		Enemy(333, 295),  
		Enemy(289, 231),
		Enemy(327, 175),
		Enemy(327, 91),  
		Enemy(214, 83),
		Enemy(137, 87),
		Enemy(151, 131),  
		Enemy(246, 141),
		Enemy(196, 184),
		Enemy(43, 184),  
		Enemy(-110, 173),
		Enemy(-110, 152),
		Enemy(-80, 86),  
		Enemy(-49, 86),
		Enemy(28, 86),
		Enemy(254, 48),  
		Enemy(293, -4),
		Enemy(246, -34),
		Enemy(130, 48),  
		Enemy(-27, 37),
		Enemy(-27, -35),
		Enemy(-108, -35),  
		Enemy(-27, -35),
		Enemy(-110, 22),
		Enemy(93, -56),  
		Enemy(418, -37),
		Enemy(407, 23),
		Enemy(455, 6),  
		Enemy(500, 18),
		Enemy(464, 48),
		Enemy(557, 16),  
		Enemy(552, -32),
		Enemy(637, -29),
		Enemy(654, 18),  
		Enemy(639, 46),
		Enemy(710, 1),
		Enemy(748, -30),  
		Enemy(814, -38),
		Enemy(814, 8),
		Enemy(760, 19),  
		Enemy(741, 43),
		Enemy(765, 108),
		Enemy(765, 143),  
		Enemy(804, 99),
		Enemy(814, 136),
		Enemy(806, 184),  
		Enemy(710, 184),
		Enemy(678, 88),
		Enemy(524, 184),  
		Enemy(570, 127),
		Enemy(545, 84),
		Enemy(382, 108),  
		Enemy(380, 163),
		Enemy(409, 182),
		Enemy(983, 40),  
		Enemy(983, -48),
		Enemy(1215, 27),
		Enemy(1215, -30), 
		Enemy(1530, 299),
		Enemy(1530, 239),
		Enemy(1488, 312),  
		Enemy(1287, 249),
		Enemy(1232, 229),
		Enemy(985, 225),  
		Enemy(983, 312),
		Enemy(983, 270),
		Enemy(1228, 583),  
		Enemy(1264, 583),
		Enemy(1194, 584),
		Enemy(1452, 552),  
		Enemy(1529, 552),
		Enemy(857, 856),
		Enemy(861, 813),  
		Enemy(938, 813),
		Enemy(1002, 813),
		Enemy(1050, 813),  
		Enemy(595, 864),
		Enemy(511, 646),
		Enemy(513, 718),  
		Enemy(498, 672),
		Enemy(449, 672),
		Enemy(403, 672),  
		Enemy(257, 855),
		Enemy(260, 918),
		Enemy(197, 913),  
		Enemy(137, 905),
		Enemy(172, 847),
		Enemy(-97, 673),  
		Enemy(-30, 720),
		Enemy(-8, 674),
		Enemy(36, 632),  
		Enemy(906, 584),
		Enemy(983, 558),
		Enemy(1046, 584),  
		Enemy(1601, 778),
		Enemy(1602, 846),
		Enemy(1642, 813),  
		Enemy(1609, 929),
		Enemy(1562, 912),
		Enemy(1233, 768),  
		Enemy(1232, 816),
		Enemy(1250, 856)
	}		
	step_3.Doors = {
		Door(729, 304, 1049, 0),	
		Door(1065, 0, 729, 320),
		Door(649, 304, 1289, -7), 
		Door(1305, -7, 649, 320),
		Door(217, 416, 1441, 272),	
		Door(1425, 272, 217, 432),
		Door(153, 416, 1186, 272), 
		Door(1169, 272, 153, 432),
		Door(81, 416, 1049, 272), 
		Door(1065, 272, 81, 432),
		Door(249, 296, 1489, 496),	
		Door(1489, 480, 249, 312),
		Door(193, 296, 1257, 496),	
		Door(1257, 480, 193, 312),
		Door(72, 152, 857, 584),	
		Door(841, 584, 72, 168),
		Door(0, 152, 1449, 808),	
		Door(1433, 808, 0, 168),
		Door(-64, 152, 1289, 816),	
		Door(1305, 816, -64, 168),
		Door(185, 32, 953, 856),	
		Door(953, 872, 185, 48),
		Door(42, 32, 593, 914), 
		Door(593, 928, 42, 48),
		Door(714, 152, 569, 672), 
		Door(585, 672, 714, 168),
		Door(649, 152, 329, 880), 
		Door(345, 880, 649, 168),
		Door(513, 152, 89, 672), 
		Door(105, 672, 513, 168)
	}
	step_3.Coins = {
		Coin(540, 217), 
		Coin(445, 227), 
		Coin(423, 362),
		Coin(480, 413), 
		Coin(425, 455),	
		Coin(316, 395),
		Coin(165, 456), 
		Coin(2, 456),	
		Coin(-103, 448),
		Coin(-27, 260), 
		Coin(42, 260), 
		Coin(95, 216),
		Coin(96, 280),	
		Coin(327, 128), 
		Coin(265, 91),
		Coin(167, 83), 
		Coin(-15, 86),	
		Coin(391, 1),
		Coin(531, 32), 
		Coin(622, 184), 
		Coin(399, 93),
		Coin(394, 163), 
		Coin(983, -3), 
		Coin(1288, -48),
		Coin(1288, 40), 
		Coin(1458, 264), 
		Coin(1530, 264),
		Coin(1194, 541),	
		Coin(1489, 573), 
		Coin(1021, 783),
		Coin(980, 784), 
		Coin(941, 787),	
		Coin(901, 787),
		Coin(861, 787), 
		Coin(535, 848), 
		Coin(650, 848),
		Coin(1482, 779),	
		Coin(1482, 848)
	}
	step_3.Npcs = {
		NPC(629, 456, dialog_npc), 
		NPC(-110, -4, dialog_npc)
	}

	step_4 = Step(449, 152, 814, -41, 3, constants.STEP_4)
	step_4.Alcools = {
		Alcool(-109, 160),	
		Alcool(781, 320), 
		Alcool(1544, 519),
		Alcool(429, 781), 
		Alcool(85, 720)
	}
	step_4.Hearts = {
		Heart(45, 184), 
		Heart(264, 455), 
		Heart(1454, 246),
		Heart(1498, 592), 
		Heart(1219, 568), 
		Heart(1271, 843),
		Heart(914, 864),	
		Heart(-67, 720)
	}
	step_4.Masks = {
		Mask(563, -51), 
		Mask(305, 184), 
		Mask(1100, 573),
		Mask(1497, 880)
	}
	step_4.Boxes = {
		Box(612, 180), 
		Box(92, 320), 
		Box(548, 320),
		Box(815, 320), 
		Box(1113, 176), 
		Box(1454, 288),
		Box(745, 912), 
		Box(259, 848), 
		Box(-24, 944)
	}
	step_4.Enemies = {
		Enemy(780, 42), 
		Enemy(699, 13), 
		Enemy(725, 43),
		Enemy(700, 43), 
		Enemy(669, 39), 
		Enemy(613, 39),
		Enemy(734, 85), 
		Enemy(802, 91), 
		Enemy(810, 179),
		Enemy(693, 121),	
		Enemy(624, 89), 
		Enemy(658, 180),
		Enemy(707, 180), 
		Enemy(563, 95), 
		Enemy(494, 100),
		Enemy(575, 183),	
		Enemy(506, 168), 
		Enemy(459, 168),
		Enemy(371, 181),	
		Enemy(528, 28), 
		Enemy(462, 48),
		Enemy(398, 33), 
		Enemy(332, -52), 
		Enemy(332, -22),
		Enemy(291, -22),	
		Enemy(237, -22),	
		Enemy(219, 10),
		Enemy(181, 42), 
		Enemy(133, -7), 
		Enemy(73, 36),
		Enemy(46, 19), 
		Enemy(46, 48),	
		Enemy(57, -21),
		Enemy(-68, 4), 
		Enemy(-54, 41), 
		Enemy(-111, 15),
		Enemy(-109, 99), 
		Enemy(-109, 184), 
		Enemy(-51, 160),
		Enemy(8, 182),	
		Enemy(58, 166), 
		Enemy(95, 166),
		Enemy(95, 184), 
		Enemy(164, 177), 
		Enemy(234, 177),
		Enemy(281, 154), 
		Enemy(333, 169), 
		Enemy(324, 123),
		Enemy(273, 122), 
		Enemy(273, 84), 
		Enemy(327, 84),
		Enemy(-23, 221), 
		Enemy(85, 232), 
		Enemy(88, 281),
		Enemy(45, 281), 
		Enemy(-72, 290), 
		Enemy(-108, 277),
		Enemy(-106, 374), 
		Enemy(-27, 361), 
		Enemy(16, 361),
		Enemy(-63, 396), 
		Enemy(-32, 451), 
		Enemy(23, 416),
		Enemy(52, 395), 
		Enemy(88, 451), 
		Enemy(178, 395),
		Enemy(136, 405), 
		Enemy(136, 451), 
		Enemy(219, 455),
		Enemy(337, 455), 
		Enemy(216, 320),	
		Enemy(371, 309),
		Enemy(315, 274),	
		Enemy(271, 280),	
		Enemy(305, 216),
		Enemy(129, 216),	
		Enemy(382, 423),	
		Enemy(420, 359),
		Enemy(405, 456), 
		Enemy(550, 440),	
		Enemy(562, 374),
		Enemy(393, 313),	
		Enemy(372, 291),	
		Enemy(404, 234),
		Enemy(572, 222),	
		Enemy(530, 263),
		Enemy(526, 297),
		Enemy(570, 313),	
		Enemy(461, 281),	
		Enemy(699, 278),
		Enemy(699, 314),	
		Enemy(634, 312),	
		Enemy(616, 265),
		Enemy(638, 223),	
		Enemy(754, 234),	
		Enemy(781, 251),
		Enemy(812, 265),	
		Enemy(766, 295),	
		Enemy(612, 438),
		Enemy(617, 381),	
		Enemy(691, 456),	
		Enemy(771, 456),
		Enemy(808, 432),	
		Enemy(749, 398),	
		Enemy(782, 383),
		Enemy(818, 352),
		Enemy(1120, 101), 
		Enemy(1252, 101),
		Enemy(1221, 162), 
		Enemy(1148, 162),	
		Enemy(1530, 278),
		Enemy(1490, 312), 
		Enemy(1457, 571),	
		Enemy(1503, 571),
		Enemy(1546, 571), 
		Enemy(1168, 573),	
		Enemy(1183, 624),
		Enemy(1242, 582), 
		Enemy(1242, 619),	
		Enemy(1574, 855),
		Enemy(1483, 855), 
		Enemy(1540, 880),	
		Enemy(1171, 845),
		Enemy(1202, 880), 
		Enemy(1230, 876),	
		Enemy(1237, 843),
		Enemy(784, 870),	
		Enemy(868, 870),	
		Enemy(746, 864),
		Enemy(615, 696),	
		Enemy(730, 696),	
		Enemy(672, 720),
		Enemy(429, 816),	
		Enemy(258, 819),	
		Enemy(312, 836),
		Enemy(357, 847),	
		Enemy(94, 944), 
		Enemy(-4, 944),
		Enemy(-92, 678),	
		Enemy(-6, 705), 
		Enemy(79, 682)
	}
	step_4.Doors = {
		Door(641, 0, 1185, 97), 
		Door(1185, 81, 641, 16),
		Door(434, 128, 1481, 233), 
		Door(1481, 217, 434, 144),
		Door(417, 0, 1497, 514),	
		Door(1497, 496, 417, 16),
		Door(497, 0, 1097, 624),	
		Door(1097, 640, 497, 16),
		Door(-22, 128, 1537, 801), 
		Door(1537, 785, -22, 144),
		Door(57, 128, 1097, 856), 
		Door(1081, 856, 57, 144),
		Door(-15, 304, 824, 913), 
		Door(824, 929, -15, 320),
		Door(305, 424, 673, 648), 
		Door(673, 632, 305, 440),
		Door(225, 424, 353, 777), 
		Door(353, 761, 225, 440),
		Door(169, 288, 32, 904), 
		Door(32, 888, 169, 304),
		Door(233, 288, 1, 633), 
		Door(1, 617, 233, 304)
	}
	step_4.Coins = {
		Coin(377, 111), 
		Coin(263, -56),	
		Coin(183, 10),
		Coin(133, 42), 
		Coin(158, -56), 
		Coin(97, -7),
		Coin(97, 44), 
		Coin(9, -6), 
		Coin(16, 37),
		Coin(-108, -56), 
		Coin(-60, 361), 
		Coin(96, 352),
		Coin(-71, 412), 
		Coin(-110, 444), 
		Coin(23, 449),
		Coin(88, 419), 
		Coin(168, 355), 
		Coin(136, 423),
		Coin(163, 455), 
		Coin(299, 455), 
		Coin(262, 320),
		Coin(298, 309), 
		Coin(289, 247), 
		Coin(336, 247),
		Coin(172, 221), 
		Coin(388, 389), 
		Coin(450, 391),
		Coin(578, 456), 
		Coin(562, 398), 
		Coin(578, 352),
		Coin(376, 256), 
		Coin(376, 225),	
		Coin(1447, 312),
		Coin(693, 720), 
		Coin(649, 708)
	}
	step_4.Npcs = {
		NPC(716, -22, dialog_npc), 
		NPC(490, 224, dialog_npc), 
		NPC(1452, 523, dialog_npc)
	}
	
	step_5 = Step(673, 440, 810, 430, 4, constants.STEP_5)
	step_5.Alcools = {
		Alcool(577, 446),
		Alcool(335, 220),
		Alcool(1370, 88),
		Alcool(1049, 285),
		Alcool(1248, 799)
	}
	step_5.Hearts = {
		Heart(367, 262),
		Heart(1402, 297),
		Heart(1001, 577),
		Heart(1562, 912),
		Heart(1447, 912),
		Heart(441, 848),
		Heart(432, 648),
		Heart(191, 837)
	}
	step_5.Masks = {
		Mask(612, 221),
		Mask(130, 364),
		Mask(129, 218),
		Mask(793, 853),
		Mask(507, 851)
	}
	step_5.Boxes = {
		Box(370, 355),
		Box(1562, 176),
		Box(1674, 400),
		Box(1099, 794),
		Box(282, 636),
		Box(194, 911),
		Box(-101, 681)
	}
	step_5.Enemies = {
		Enemy(610, 356),  
		Enemy(709, 444),  
		Enemy(693, 395),  
		Enemy(610, 446),  
		Enemy(541, 446),  
		Enemy(569, 368),  
		Enemy(467, 448),  
		Enemy(411, 439),  
		Enemy(371, 408),  
		Enemy(388, 383),  
		Enemy(370, 308),  
		Enemy(454, 320),  
		Enemy(501, 304),  
		Enemy(379, 228),  
		Enemy(543, 320),  
		Enemy(578, 303),  
		Enemy(574, 246),  
		Enemy(546, 230),  
		Enemy(612, 243),  
		Enemy(619, 311),  
		Enemy(691, 317),  
		Enemy(756, 318),  
		Enemy(803, 225),  
		Enemy(803, 151),  
		Enemy(689, 181),  
		Enemy(620, 170),  
		Enemy(620, 105),  
		Enemy(764, 115),  
		Enemy(809, 85),  
		Enemy(624, 26),  
		Enemy(648, -22),  
		Enemy(752, -1),  
		Enemy(806, 25),  
		Enemy(799, -10),  
		Enemy(810, -47),  
		Enemy(564, 14),  
		Enemy(513, -12),  
		Enemy(449, -1),  
		Enemy(451, 39),  
		Enemy(381, 17),  
		Enemy(381, -24),  
		Enemy(394, 94),  
		Enemy(440, 110),  
		Enemy(440, 145),  
		Enemy(386, 177),  
		Enemy(464, 184),  
		Enemy(570, 184),  
		Enemy(556, 137),  
		Enemy(547, 92),  
		Enemy(316, 90),  
		Enemy(334, 122),  
		Enemy(327, 184),  
		Enemy(228, 184),  
		Enemy(138, 184),  
		Enemy(133, 129),  
		Enemy(143, 85),  
		Enemy(324, -34),  
		Enemy(324, 3),  
		Enemy(338, 47),  
		Enemy(253, 11),  
		Enemy(263, 48),  
		Enemy(194, 20),  
		Enemy(141, -12),  
		Enemy(135, 44),  
		Enemy(-75, -32),  
		Enemy(-94, 20),  
		Enemy(-22, -4),  
		Enemy(4, 48),  
		Enemy(39, 17),  
		Enemy(74, 3),  
		Enemy(-31, 101),  
		Enemy(-85, 113),  
		Enemy(-83, 153),  
		Enemy(-99, 178),  
		Enemy(37, 184),  
		Enemy(95, 184),  
		Enemy(79, 123),  
		Enemy(92, 88),  
		Enemy(-95, 250),  
		Enemy(-65, 285),  
		Enemy(-22, 262),  
		Enemy(0, 235),  
		Enemy(-7, 298),  
		Enemy(48, 307),  
		Enemy(98, 320),  
		Enemy(81, 255),  
		Enemy(28, 238),  
		Enemy(-87, 372),  
		Enemy(-30, 409),  
		Enemy(-79, 416),  
		Enemy(130, 408), 
		Enemy(332, 389), 
		Enemy(291, 357),
		Enemy(332, 315), 
		Enemy(304, 270),  
		Enemy(329, 248),  
		Enemy(137, 295),  
		Enemy(137, 264),  
		Enemy(165, 225),  
		Enemy(1271, 32),  
		Enemy(1310, 56),  
		Enemy(1361, 33),  
		Enemy(1658, 176),  
		Enemy(1559, 162),  
		Enemy(1665, 341), 
		Enemy(1650, 341),  
		Enemy(1631, 400), 
		Enemy(1289, 301),  
		Enemy(1277, 353),  
		Enemy(1328, 360),  
		Enemy(1034, 312),  
		Enemy(1034, 256),  
		Enemy(1607, 624),  
		Enemy(1559, 624),  
		Enemy(1527, 606),  
		Enemy(1640, 606),  
		Enemy(1317, 599),  
		Enemy(1284, 599),  
		Enemy(1023, 550),  
		Enemy(1562, 864),  
		Enemy(1449, 864),  
		Enemy(1479, 912),  
		Enemy(1536, 912),  
		Enemy(1239, 844),  
		Enemy(1187, 856),  
		Enemy(1154, 856),  
		Enemy(1099, 842), 
		Enemy(868, 855),  
		Enemy(810, 672),  
		Enemy(473, 909),  
		Enemy(496, 928),  
		Enemy(531, 903),  
		Enemy(531, 870),  
		Enemy(565, 859),  
		Enemy(405, 922),  
		Enemy(386, 898),  
		Enemy(414, 875),  
		Enemy(376, 857),  
		Enemy(303, 672),  
		Enemy(402, 672),  
		Enemy(446, 720),  
		Enemy(331, 640),  
		Enemy(377, 650),  
		Enemy(259, 693),  
		Enemy(57, 904),  
		Enemy(112, 845),  
		Enemy(114, 898),  
		Enemy(161, 872),  
		Enemy(18, 637),  
		Enemy(24, 720),  
		Enemy(-58, 716),  
		Enemy(-66, 637)
	}
	step_5.Doors = {
		Door(649, 408, 1009, 9),
		Door(1009, 25, 649, 424),
	
		Door(520, 408, 1225, 88),
		Door(1209, 89, 520, 424),
	
		Door(457, 408, 473, 849),
		Door(473, 833, 457, 424),
	
		Door(425, 272, 1577, 369),
		Door(1561, 369, 425, 288),
	
		Door(505, 272, 1217, 329),
		Door(1201, 329, 505, 287),
	
		Door(657, 272, 977, 281),
		Door(961, 281, 657, 287),
	
		Door(737, 272, 1585, 568),
		Door(1585, 552, 737, 288),
	
		Door(697, 144, 1289, 545),
		Door(1289, 529, 697, 160),
	
		Door(705, 32, 1505, 849),
		Door(1505, 833, 705, 48),
	
		Door(489, 152, 1169, 793),
		Door(1169, 777, 489, 168),
	
		Door(217, 152, 825, 912),
		Door(825, 928, 217, 168),
	
		Door(17, 152, 777, 721),
		Door(777, 737, 17, 168),
	
		Door(9, 424, 1065, 577),
		Door(1081, 577, 9, 440),
	
		Door(73, 424, 353, 721),
		Door(353, 737, 73, 440),
	
		Door(169, 424, 1, 873),
		Door(-15, 873, 169, 440),
	
		Door(233, 424, 89, 680),
		Door(105, 680, 233, 440)
	}
	step_5.Coins = {
		Coin(779, 373),
		Coin(693, 364),
		Coin(642, 443),
		Coin(647, 317),
		Coin(721, 305),
		Coin(803, 269),
		Coin(318, 442),
		Coin(326, 362),
		Coin(1317, 31),
		Coin(1344, 73),
		Coin(1596, 153),
		Coin(1624, 165),
		Coin(1327, 354),
		Coin(1402, 358),
		Coin(997, 258),
		Coin(997, 311),
		Coin(1258, 599),
		Coin(858, 898),
		Coin(827, 873),
		Coin(790, 894),
		Coin(810, 720),
		Coin(806, 645),
		Coin(755, 645),
		Coin(57, 850),
		Coin(172, 841),
		Coin(157, 839),
		Coin(164, 911),
		Coin(36, 680),
		Coin(-13, 657),
		Coin(-8, 707),
		Coin(-47, 672)
	}
	step_5.Npcs = {
		NPC(296, 412, dialog_npc),
		NPC(569, 928, dialog_npc)
	}

	step_1.next_round = step_2
	step_2.next_round = step_3
	step_3.next_round = step_4
	step_4.next_round = step_5
end

Window = {
	MENU = {update = update_window, draw = draw_menu},
	GAME = {update = update_game, draw = draw_game},
	TRANSACTION_ROUND = {update = update_transaction_round,	draw = draw_transaction},
	GAME_OVER = {update = update_game_over, draw = draw_game_over},
	NPC_DIED = {update = update_npc_died, draw = draw_npc_died},
	END_GAME = {update = update_window_end_game, draw = draw_end_game}
}

window = Window.MENU
initialize()