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
	DOOR = 96,
	ENEMY = 292,
	END_GAME = 1,
	HEALTH = 399,
	SHIELD = 415,
	COIN = 416,
	EMPTY_H_S = 414,
--	CHECKPOINT = 423,

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

local Enemies = {}
local Keys = {}
local Doors = {}
local Coins = {}

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
		  return door.make_collision_door_with_player(i, time)
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

local function distancy(e, p)
	return math.sqrt(((e.x - p.x) ^ 2) + ((e.y - p.y) ^ 2))
end

local function lerp(a, b, q)
	return (1 - q) * a + q * b
end

local function DisplayHUD()
	print(constants.SCORE..player.score, 0, 0)

	for j = 1, player.health do
		spr(
			tiles.HEALTH,
			CELL * (j - 1),
			CELL,
			1 -- cor de fundo
		)
	end

	for j = 1, player.shield do
		spr(
			tiles.SHIELD,
			CELL * (j - 1),
			CELL * 2,
			1 -- cor de fundo
		)
	end

	if player.coins > 0 then
		print(constants.COINS_PLAYER..player.coins, CAM_W - (CELL * 5), 0)
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
	local base = {
		tag = nil,
		sprite = nil,
		x = 0,
		y = 0,
		background = 6,
		animation = 0,
		make_collisions = {
			ENEMY = function() return false end,
			PLAYER = function() return false end,
			SWORD = function() return false end
		},
		visible = false,
		timeout = 0
	}

	function base.move(personal, delta, direction_actual, time)
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
			x = personal.x + 7 + delta.x,
			y = personal.y - 8 + delta.y
		}

		local footer_right = {
			x = personal.x + 7 + delta.x,
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

	function base.draw()
		if base.visible then
			spr(
				base.sprite,
				cam.x + base.x,
				cam.y + base.y,
				base.background, -- cor de fundo
				1, -- escala
				0, -- espelhar
				0, -- rotacionar
				2, -- quantidade de blocos direita
				2 -- quantidade de blocos esquerda
			)
		end
	end

	function base.update(time)
		return true
	end

	return base
end

-- Animation class --
local function Anim(span, frames, loop)
	local anim = {
		span = span,
		indx = 0,
		frame = nil,
		frames = frames,
		loop = loop,
		tick = 0,
		ended = false
	}

	function anim.update(time)
		if time >= anim.tick
		and #anim.frames > 0 then
			if anim.loop then
				anim.indx = (anim.indx + 1) % #anim.frames
				anim.frame = anim.frames[anim.indx + 1]
				anim.ended = false
			else
				anim.indx = anim.indx < #anim.frames and anim.indx + 1 or #anim.frames
				anim.frame = anim.frames[anim.indx]

				if anim.indx == #anim.frames then
					anim.ended = true
				end
			end
			anim.tick = time + anim.span
		end
	end

	function anim.random_indx()
		anim.indx = math.random(#anim.frames)
	end

	function anim.reset()
		anim.indx = 0
		anim.ended = false
	end

	return anim
end

-- Door class --
local function Door(x, y, player_x, player_y, house_door)
	local door = Base()
	door.sprite = tiles.DOOR
	door.x = x
	door.y = y
	door.player_x = player_x
	door.player_y = player_y
	door.anim = Anim(10, {96, 98}, false)
	door.visible = true
	door.house_door = house_door or nil

	function door.make_collision_door_with_player(index, time)
		door.anim.update(time)
		door.sprite = door.anim.frame

		window = Window.TRANSACTION_ROUND

		door.home()

		return true
	end

	function door.home()
		player.x = door.player_x
		player.y = door.player_y
	end

	return door
end

-- Key class --
local function Key(x, y)
	local key = Base()
	key.tag = constants.KEY
	key.sprite = tiles.KEY
	key.x = x
	key.y =	y
	key.visible = true

	function key.make_collision_key_with_player(index)
		player.keys = player.keys + 1
		table.remove(round_actual.Keys, index)

		return false
	end

	return key
end

local function Coin(x, y)
	local c = Base()
	c.tag = constants.COIN
	c.sprite = tiles.COIN
	c.x = x
	c.y =	y
	c.anim = Anim(15, {416, 418}, true)
	c.background = 1
	c.visible = true

	function c.update(time)
		c.anim.update(time)
		c.sprite = c.anim.frame

		return true
	end

	function c.make_collision_coin_with_player(index)
		player.coins = player.coins + 1
		table.remove(round_actual.Coins, index)

		return false
	end

	return c
end

-- Enemy class --
local function Enemy(x, y)
	local enemy = Base()
	enemy.tag = constants.ENEMY
	enemy.sprite = tiles.ENEMY
	enemy.state = states_enemy.STOP
	enemy.background = 1
	enemy.x = x
	enemy.y =	y
	enemy.animation = 1
	enemy.anims = {
		Anim(15, {288, 290}, false),
		Anim(15, {292, 294}, false),
		Anim(15, {296, 298}, false),
		Anim(15, {300, 302}, false)
	}
	enemy.curAnim = nil
	enemy.visible = true

	function enemy.update(time)
		if distancy(enemy, player) < constants.VIEW_ENEMY then
			enemy.state = states_enemy.PURSUIT
		else
			enemy.state = states_enemy.STOP
		end

		if enemy.state == states_enemy.PURSUIT then
			local delta = {
				x = 0,
				y = 0
			}

			if player.y > enemy.y then
				delta.y = 0.5
				enemy.direction = const_direction.DOWN
			elseif player.y < enemy.y then
				delta.y = - 0.5
				enemy.direction = const_direction.UP
			end

			enemy.move(enemy, delta, enemy.direction, time)

			delta.x = 0
			delta.y = 0

			if player.x > enemy.x then
				delta.x = 0.5
				enemy.direction = const_direction.RIGHT
			elseif player.x < enemy.x then
				delta.x = - 0.5
				enemy.direction = const_direction.LEFT
			end

			enemy.move(enemy, delta, enemy.direction, time)

			enemy.curAnim = enemy.anims[enemy.direction]
			enemy.curAnim.update(time)
			enemy.sprite = enemy.curAnim.frame
		end
	end

	function enemy.make_collision_enemy_with_sword(index)
		table.remove(round_actual.Enemies, index)
		player.score = player.score + 1
		return false
	end

	function enemy.make_collision_enemy_with_player(index)
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

	return enemy
end

-- Sword class --
local function Sword(x, y)
	local sword = Base()
	sword.tag = constants.SWORD
	sword.x = x
	sword.y = y
	sword.background = 0
	sword.animation = 1
	sword.anims = {
		Anim(10, {484, 486}, false),	-- UP
		Anim(10, {490, 492}, false),	-- DOWN
		Anim(10, {480, 482}, false),	-- LEFT
		Anim(10, {486, 488}, false)		-- RIGHT
	}
	sword.curAnim = nil
	sword.visible = false
	sword.timeout = 0

	function sword.update(time)
		local delta = {
			{x = 0, y = - 10},	--UP
			{x = 0, y = 10},		--DOWN
			{x = -10, y = 0},		--LEFT
			{x = 10, y = 0}			--RIGHT
		}

		if player.direction then
			sword.x = player.x + delta[player.direction].x
			sword.y = player.y + delta[player.direction].y

			sword.curAnim = sword.anims[player.direction]
			sword.curAnim.update(time)
			sword.sprite = sword.curAnim.frame

			if btn(4) then
				sword.visible = true
				sword.timeout = 15
			end
		end

		if sword.visible then
			check_collision_objects(sword, sword, time)

			if sword.curAnim and sword.curAnim.ended then
				sword.curAnim.reset()
			end

			sword.timeout = sword.timeout - 1
			if sword.timeout <= 0 then
				sword.visible = false
			end
		end
	end

	return sword
end

local function Round(x,	y,	player_x,	player_y,	map)
	local round = Base()
	round.srite = tiles.DOOR
	round.x =	x
	round.y = y
	round.player_x = player_x
	round.player_y = player_y
	round.background = 1
	round.visible = true
	round.map = map
	round.timeout = 60
	round.Coins = {}
	round.Keys = {}
	round.Enemies = {}
	round.Doors = {}
	round.next_round = nil


	function round.update_round()
		window = Window.TRANSACTION_ROUND

		round_actual = round.next_round
		player.x = round_actual.player_x
		player.y = round_actual.player_y
		sync(4, round_actual.map)
	end

	function round.draw()
		for i, enemy in pairs(round.Enemies) do	enemy.draw() end
		for i, key in pairs(round.Keys) do key.draw()	end
		for i, door in pairs(round.Doors) do door.draw() end
		for i, coin in pairs(round.Coins) do coin.draw() end
	end

	function round.update(time)
		for i, enemy in pairs(round.Enemies) do enemy.update(time) end
		for i, key in pairs(round.Keys) do key.update(time) end
		for i, door in pairs(round.Doors) do door.update(time) end
		for i, coin in pairs(round.Coins) do coin.update(time) end
	end

	return round
end

-- Player class --
local function Player(x, y, sword)
	local p = Base()
	p.tag = constants.PLAYER
	p.sprite = tiles.PLAYER
	p.x = x
	p.y = y
	p.background = 1
	p.animation = 1
	p.keys = 0
	p.sword = sword
	p.health = 3
	p.maxHealth = 5
	p.shield = 3
	p.maxShield = 3
	p.coins = 0
	p.score = 0
	p.anims = {
		Anim(10, {256, 258}, false),
		Anim(10, {260, 262}, false),
		Anim(10, {264, 266}, false),
		Anim(10, {268, 270}, false)
	}
	p.curAnim = nil

	function p.draw()
		player.sword.draw()

		local block_x, block_y = (cam.x + p.x), (cam.y + p.y)

		spr(
			p.sprite,
			block_x,
			block_y,
			p.background, -- cor de fundo
			1, -- escala
			0, -- espelhar
			0, -- rotacionar
			2, -- quantidade de blocos direita
			2 -- quantidade de blocos esquerda
		)
	end

	function p.update(time)
	  local delta = {
			{x = 0, y = -1},	-- up
			{x = 0, y = 1},		-- down
			{x = -1, y = 0},	-- left
			{x = 1, y = 0}		-- right
		}

		for keyword = 0, 3 do
			if btn(keyword) then
				p.direction = keyword + 1

				p.curAnim = p.anims[p.direction]
				p.curAnim.update(time)
				p.sprite = p.curAnim.frame

				p.move(p, delta[p.direction], p.direction, time)
			end
		end

		p.sword.update(time)
	end

	return p
end

local function draw_objects()
	DisplayHUD()
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
			{x = -16,	y = 983, pl_x = 197, pl_y = 4, create = Door},
			{x = 180, y = 5, pl_x = -16, pl_y = 1000, create = Door}
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
	if round_actual.timeout > 0 then
		cls()
		print("Loading..", CAM_W/2-22, CAM_H/2-18)

		round_actual.timeout = round_actual.timeout - 1
	elseif round_actual.timeout == 0 then
		window = Window.GAME
		round_actual.timeout = 30
	end
end

function TIC()
	window.update(t)
	window.draw()

	print(player.x, 0, 20)
	print(player.y, 0, 30)

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