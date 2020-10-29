-- title:  Coronga;
-- author: Douglas, Richard e Otavio;
-- desc: RPG acao 2d;
-- script: lua.

local CAM_W = 240
local CAM_H = 136
local CELL = 8
local DRAW_X = 120
local DRAW_Y = 64
local t = 0

local states_enemy = {
	STOP = "STOP",
	PURSUIT = "PURSUIT"
}

local tiles = {
	PLAYER = 260,
	KEY = 364,
	BOX = 164,
	DOOR = 96,
	ENEMY = 292,
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
	KEY = 0,
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
	VIEW_ENEMY = 58,
	SPEED_ANIMATION = 0.1,

	ABOUT = "Desenvolvido por Taxarau",

	SCORE = "Score: ",
	COINS_PLAYER = "Coins: ",

	ENEMY = "ENEMY",
	PLAYER = "PLAYER",
	SWORD = "SWORD",
	KEY = "KEY",
	COIN = "COIN",
	CHECKPOINT = "CHECKPOINT"
}

local player = {}
local window = {}
local end_game = {}
local round_actual = {}
local round_1 = {}
local round_2 = {}
local round_3 = {}
local round_4 = {}
local round_5 = {}

local function is_collision(point)
	return mget(
		(point.x / CELL) + (CELL * 2),
		(point.y / CELL) + (CELL + 1)
	) >= 128
end

local function is_collision_objects(objectA, objectB)
	local leftForA = objectA.x + CELL
	local rightForA = objectA.x - CELL
	local underForA = objectA.y + CELL
	local upForA = objectA.y - CELL

	local leftForB = objectB.x - CELL
	local rightForB = objectB.x + CELL
	local underForB = objectB.y + CELL
	local upForB = objectB.y - CELL

  return not (leftForB > rightForA
					or rightForB < leftForA
					or underForA < upForB
					or upForA > underForB)
end

local function check_collision_objects(personal, newPosition, time)
	for i, box in pairs(round_actual.Boxes) do
	  if is_collision_objects(newPosition, box) then
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

	for i, key in pairs(round_actual.Keys) do
	  if is_collision_objects(newPosition, key) then
		  return key.make_collision_key_with_player(i)
		end
	end

	for i, door in pairs(round_actual.Doors) do
	  if is_collision_objects(newPosition, door) then
		  return door.make_collision_door_with_player(time)
		end
	end

	for i, coin in pairs(round_actual.Coins) do
		if is_collision_objects(newPosition, coin) then
			return coin.make_collision_coin_with_player(i)
		end
	end

	if round_actual.next_round
	and is_collision_objects(newPosition, round_actual.next_round) then
		return round_actual.update_round()
	end

	return false
end

local function distancy(e, self)
	return math.sqrt(((e.x - self.x) ^ 2) + ((e.y - self.y) ^ 2))
end

local function lerp(a, b, q)
	return (1 - q) * a + q * b
end

local function DisplayHUD()
	local h_s = 0

	print(constants.SCORE..player.score, 0, 0)

	for i = 1, player.health do
		h_s = h_s + 1

		spr(
			tiles.HEALTH,
			CELL * (h_s - 1),
			CELL,
			1 -- cor de fundo
		)
	end

	for j = 1, player.maxHealth - player.health do
		h_s = h_s + 1

		spr(
			tiles.EMPTY_H_S,
			CELL * (h_s - 1),
			CELL,
			1 -- cor de fundo
		)
	end

	h_s = 0

	for i = 1, player.shield do
		h_s = h_s + 1

		spr(
			tiles.SHIELD,
			CELL * (i - 1),
			CELL * 2,
			1 -- cor de fundo
		)
	end

	for j = 1, player.maxShield - player.shield do
		h_s = h_s + 1

		spr(
			tiles.EMPTY_H_S,
			CELL * (h_s - 1),
			CELL * 2,
			1 -- cor de fundo
		)
	end

	if player.coins > 0 then
		print(constants.COINS_PLAYER..player.coins, CAM_W - (CELL * 5.5), 0)
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
		make_collisions = {
			ENEMY = function() return false end,
			PLAYER = function() return false end,
			SWORD = function() return false end
		},
		visible = false,
		timeout = 0
	}

	function self.move(personal, delta, direction_actual, time)
		local newPosition = {
			x = personal.x + delta.x,
			y = personal.y + delta.y
		}

		if check_collision_objects(personal, newPosition, time) then
			return false
		end

		local top_left = {
			x = personal.x - 7 + delta.x,
			y = personal.y - 8 + delta.y
		}

		local top_right = {
			x = personal.x + 5 + delta.x,
			y = personal.y - 8 + delta.y
		}

		local footer_right = {
			x = personal.x + 5 + delta.x,
			y = personal.y + 7 + delta.y
		}

		local footer_left = {
			x = personal.x - 7 + delta.x,
			y = personal.y + 7 + delta.y
		}

		if not (is_collision(top_left)
		or is_collision(top_right)
		or is_collision(footer_right)
		or is_collision(footer_left)) then
			personal.animation = personal.animation + constants.SPEED_ANIMATION

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
			spr(
				self.sprite,
				cam.x + self.x,
				cam.y + self.y,
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
	self.x = x
	self.y = y
	self.anim = Anim(10, {164, 166}, false)
	self.coins = 10
	self.visible = true

	function self.make_collision_box_with_player(time)
		self.anim.update(time)
		self.sprite = self.anim.frame

		player.coins = player.coins + self.coins
		self.coins = 0

		return true
	end

	return self
end


-- Door class --
local function Door(x, y, player_x, player_y, house_door)
	local self = Base()
	self.sprite = tiles.DOOR
	self.x = x
	self.y = y
	self.player_x = player_x
	self.player_y = player_y
	self.anim = Anim(10, {160, 162}, false)
	self.visible = true
	self.house_door = house_door or nil

	function self.make_collision_door_with_player(time)
		self.anim.update(time)
		self.sprite = self.anim.frame

		window = Window.TRANSACTION_ROUND

		self.home()

		return true
	end

	function self.home()
		player.x = self.player_x
		player.y = self.player_y
	end

	return self
end

-- Key class --
local function Key(x, y)
	local self = Base()
	self.tag = constants.KEY
	self.sprite = tiles.KEY
	self.x = x
	self.y =	y
	self.visible = true

	function self.make_collision_key_with_player(index)
		player.keys = player.keys + 1
		table.remove(round_actual.Keys, index)

		return false
	end

	return self
end

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

-- Enemy class --
local function Enemy(x, y)
	local self = Base()
	self.tag = constants.ENEMY
	self.sprite = tiles.ENEMY
	self.state = states_enemy.STOP
	self.background = 1
	self.x = x
	self.y =	y
	self.animation = 1
	self.anims = {
		Anim(15, {288, 290}, false),
		Anim(15, {292, 294}, false),
		Anim(15, {296, 298}, false),
		Anim(15, {300, 302}, false)
	}
	self.curAnim = nil
	self.visible = true

	function self.update(time)
		if distancy(self, player) < constants.VIEW_ENEMY then
			self.state = states_enemy.PURSUIT
		else
			self.state = states_enemy.STOP
		end

		if self.state == states_enemy.PURSUIT then
			local delta = {
				x = 0,
				y = 0
			}

			if player.y > self.y then
				delta.y = 0.5
				self.direction = const_direction.DOWN
			elseif player.y < self.y then
				delta.y = - 0.5
				self.direction = const_direction.UP
			end

			self.move(self, delta, self.direction, time)

			delta.x = 0
			delta.y = 0

			if player.x > self.x then
				delta.x = 0.5
				self.direction = const_direction.RIGHT
			elseif player.x < self.x then
				delta.x = - 0.5
				self.direction = const_direction.LEFT
			end

			self.move(self, delta, self.direction, time)

			self.curAnim = self.anims[self.direction]
			self.curAnim.update(time)
			self.sprite = self.curAnim.frame
		end
	end

	function self.make_collision_enemy_with_sword(index)
		table.remove(round_actual.Enemies, index)
		player.score = player.score + 1
		return false
	end

	function self.make_collision_enemy_with_player(index)
		if player.shield > 0 then
			player.shield = player.shield - 1
		elseif player.health > 0 then
			player.health = player.health - 1
		end

		if player.shield == 0 and player.health == 0 then
			initialize()
			window = Window.MENU

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
	self.animation = 1
	self.anims = {
		Anim(10, {324, 326}, false),	-- UP
		Anim(10, {332, 330}, false),	-- DOWN
		Anim(10, {334, 320}, false),	-- LEFT
		Anim(10, {326, 328}, false)		-- RIGHT
	}
	self.curAnim = nil
	self.visible = false
	self.timeout = 0

	function self.update(time)
		local delta = {
			{x = 0, y = - 10},	--UP
			{x = 0, y = 10},		--DOWN
			{x = -10, y = 0},		--LEFT
			{x = 10, y = 0}			--RIGHT
		}

		if player.direction then
			self.x = player.x + delta[player.direction].x
			self.y = player.y + delta[player.direction].y

			self.curAnim = self.anims[player.direction]
			self.curAnim.update(time)
			self.sprite = self.curAnim.frame

			if btn(4) then
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

local function Round(x,	y,	player_x,	player_y,	map)
	local self = Base()
	self.srite = tiles.DOOR
	self.x =	x
	self.y = y
	self.player_x = player_x
	self.player_y = player_y
	self.background = 1
	self.visible = true
	self.map = map
	self.timeout = 60
	self.t = 0
	self.Coins = {}
	self.Keys = {}
	self.Enemies = {}
	self.Doors = {}
	self.Boxes = {}
	self.next_round = nil


	function self.update_round()
		window = Window.TRANSACTION_ROUND

		round_actual = self.next_round
		player.x = round_actual.player_x
		player.y = round_actual.player_y
		sync(4, round_actual.map)
	end

	function self.draw()
		for i, box in pairs(self.Boxes) do box.draw() end
		for i, enemy in pairs(self.Enemies) do enemy.draw() end
		for i, key in pairs(self.Keys) do key.draw() end
		for i, door in pairs(self.Doors) do door.draw() end
		for i, coin in pairs(self.Coins) do coin.draw() end
	end

	function self.update(time)
		for i, box in pairs(self.Boxes) do box.update(time) end
		for i, enemy in pairs(self.Enemies) do enemy.update(time) end
		for i, key in pairs(self.Keys) do key.update(time) end
		for i, door in pairs(self.Doors) do door.update(time) end
		for i, coin in pairs(self.Coins) do coin.update(time) end
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
	self.background = 1
	self.animation = 1
	self.keys = 0
	self.sword = sword
	self.health = 3
	self.maxHealth = 5
	self.shield = 0
	self.maxShield = 3
	self.coins = 0
	self.score = 0
	self.anims = {
		Anim(10, {256, 258}, false),
		Anim(10, {260, 262}, false),
		Anim(10, {264, 266}, false),
		Anim(10, {268, 270}, false)
	}
	self.curAnim = nil

	function self.draw()
		player.sword.draw()

		local block_x, block_y = (cam.x + self.x), (cam.y + self.y)

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
	  local delta = {
			{x = 0, y = -1},	-- up
			{x = 0, y = 1},		-- down
			{x = -1, y = 0},	-- left
			{x = 1, y = 0}		-- right
		}

		for keyword = 0, 3 do
			if btn(keyword) then
				self.direction = keyword + 1

				self.curAnim = self.anims[self.direction]
				self.curAnim.update(time)
				self.sprite = self.curAnim.frame

				self.move(self, delta[self.direction], self.direction, time)
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

	print(constants.ABOUT, 60, 128)
end

local function draw_game()
	cls()

	draw_map()
	draw_objects()

	player.draw()
	DisplayHUD()
end

local function create_rounds()
	local function create_objects(arr_obj, objs)
		for i, item in pairs(arr_obj) do
			if item.pl_x and item.pl_y then
				table.insert(objs, item.create(item.x, item.y, item.pl_x, item.pl_y))
			else
				table.insert(objs, item.create(item.x, item.y))
			end
		end
	end

	local objects = {}

	round_1 = Round(0, 0, 1, 125, 0)

	objects = {
		boxes = {
			{x = -110, y = 899, create = Box},
		},

		enemies = {
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
			{x = 386, y = 468, create = Enemy},
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
			{x = -81, y = 720, create = Enemy}
		},

		keys = {
		},

		doors = {
			{x = -16,	y = 983, pl_x = 705, pl_y = 93, create = Door},
			{x = 705, y = 73, pl_x = -16, pl_y = 1000, create = Door}
		},

		coins = {
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
			{x = 130, y = 712, create = Coin}
		}
	}

	create_objects(objects.boxes, round_1.Boxes)
	create_objects(objects.enemies, round_1.Enemies)
	create_objects(objects.keys, round_1.Keys)
	create_objects(objects.doors, round_1.Doors)
	create_objects(objects.coins, round_1.Coins)

	round_2 = Round(20, 900, -112, -8, 1)
	round_1.next_round = round_2
end

function initialize()
	Enemies = {}
	Keys = {}
	Doors = {}
	Coins = {}

	cam = {
		x = 0,
		y = 0
	}

	local sword_init = Sword(0, 0)

	player = Player(-109, 936, sword_init)

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

	create_rounds()
	round_actual = round_1
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
end

local function draw_transaction()
	round_actual.t = round_actual.t + 1

	if round_actual.t < 2 * 15 then
		return
	elseif round_actual.timeout > 0 then
		cls()
		print("Loading..", CAM_W/2-22, CAM_H/2-18)

		round_actual.timeout = round_actual.timeout - 1
	elseif round_actual.timeout == 0 then
		window = Window.GAME
		round_actual.timeout = 30
		round_actual.t = 0
	end
end

function TIC()
	window.update(t)
	window.draw()

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

	END_GAME = {
		update = update_window_final,
		draw = draw_end_game
	}
}

window = Window.MENU
initialize()