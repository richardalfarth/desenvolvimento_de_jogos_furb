-- title:  Coronga;
-- author: Douglas, Richard e Otavio;
-- desc: RPG acao 2d;
-- script: lua.

local CELL = 8
local DRAW_X = 120
local DRAW_Y = 64

local States = {
	STOP = "STOP",
	PURSUIT = "PURSUIT"
}

local Constants = {
	VIEW_ENEMY = 58,

	SPEED_ANIMATION = 0.1,

	SPRITE_PLAYER = 260,
	SPRITE_KEY = 364,
	SPRITE_DOOR = 366,
	SPRITE_ENEMY = 292,
	SPRITE_END_GAME = 1,
	SPRITE_CHECKPOINT = 423,

	ID_SFX_KEY = 0,
	ID_SFX_DOOR = 1,
	ID_SFX_INIT = 3,
	ID_SFX_SWORD = 4,
	ID_SFX_END_GAME = 5,

  SPRITE_TITLE = 352,
	SPRITE_TITLE_LENGTH = 12,
	SPRITE_TITLE_HEIGHT = 4,

	ABOUT = "Desenvolvido por Taxarau",

	ENEMY = "ENEMY",
	PLAYER = "PLAYER",
	SWORD = "SWORD",
	KEY = "KEY",
	CHECKPOINT = "CHECKPOINT",

	Direction = {
		UP = 1,
		DOWN = 2,
		LEFT = 3,
		RIGHT = 4
  }
}

local function is_collision(point)
	return mget(
		(point.x / CELL) + (CELL * 2),
		(point.y / CELL) + (CELL + 1)
	) >= 128
end

local function make_collision_player_with_objects(index)
	player.keys = player.keys + 1
	table.remove(Keys, index)

  return false
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

local function make_collision_player_with_door(index)
	if player.keys > 0 then
	  player.keys = player.keys - 1
    table.remove(Keys, index)

		return false
	end

  return true
end

local function check_collision_objects(personal, newPosition)
	for i, enemy in pairs(Enemies) do
	  if is_collision_objects(newPosition, enemy) then
		  return enemy.make_collisions[personal.type](i)
		end
	end

	for i, key in pairs(Keys) do
	  if is_collision_objects(newPosition, key) then
		  return key.make_collisions[personal.type](i)
		end
	end

	for i, door in pairs(Doors) do
	  if is_collision_objects(newPosition, door) then
		  return door.make_collisions[personal.type](i)
		end
	end

	return false
end

local function distancy(enemy, player)
	return math.sqrt(((enemy.x - player.x) ^ 2) + ((enemy.y - player.y) ^ 2))
end

local function lerp(a, b, t)
	return (1 - t) * a + t * b
end

local function update_game()
	player.update()

	check_collision_objects(player, player)

	for i, enemy in pairs(Enemies) do
    enemy.update()
	end

	for i, key in pairs(Keys) do
    key.update()
	end

	for i, door in pairs(Doors) do
    door.update()
	end

	cam.x = math.min(DRAW_X, lerp(cam.x, DRAW_X - player.x, 0.05))
  cam.y = math.min(DRAW_Y, lerp(cam.y, DRAW_Y - player.y, 0.05))
end

local function update_window()
	if btn(4) then
    window = Window.GAME
	end
end

function TIC()
	window.update()
	window.draw()
end

local function restart_game(index)
	initialize()
	window = Window.MENU

  return true
end

local function make_collision_enemy_with_door(index)
	return true
end

local function make_collision_enemy_with_sword(index)
	table.remove(Enemies, index)
	return false
end

local function final_match()
	window = Window.END_GAME
end

-- Base class --
local function Base()
	local base = {
		type = nil,
		sprite = nil,
		x = 0,
		y = 0,
		background = 6,
		animation = 0,
		make_collisions = nil,
		visible = false,
		timeout = 0
	}

	function base.move(personal, delta, direction_actual)
		local newPosition = {
			x = personal.x + delta.deltaX,
			y = personal.y + delta.deltaY
		}

		if check_collision_objects(personal, newPosition) then
			return false
		end

		local top_left = {
			x = personal.x - 7 + delta.deltaX,
			y = personal.y - 8 + delta.deltaY
		}

		local top_right = {
			x = personal.x + 7 + delta.deltaX,
			y = personal.y - 8 + delta.deltaY
		}

		local footer_right = {
			x = personal.x + 7 + delta.deltaX,
			y = personal.y + 7 + delta.deltaY
		}

		local footer_left = {
			x = personal.x - 7 + delta.deltaX,
			y = personal.y + 7 + delta.deltaY
		}

		if not (is_collision(top_left)
		or is_collision(top_right)
		or is_collision(footer_right)
		or is_collision(footer_left)) then
			personal.animation = personal.animation + Constants.SPEED_ANIMATION

			if personal.animation >= 3 then
				personal.animation = 1
			end

			personal.x = personal.x + delta.deltaX
			personal.y = personal.y + delta.deltaY
			personal.direction = direction_actual
		end
	end

	return base
end

-- Door class --
local function Door(x, y)
	local door = Base()
	door.sprite = Constants.SPRITE_DOOR
	door.x = x
	door.y =	y
	door.make_collisions = {
	  ENEMY = make_collision_enemy_with_door,
		PLAYER = make_collision_player_with_door,
		SWORD = function() return false end
	}
	door.visible = true

	function door.draw()
		if door.visible then
			spr(
				door.sprite,
				cam.x + door.x,
				cam.y + door.y,
				door.background, -- cor de fundo
				1, -- escala
				0, -- espelhar
				0, -- rotacionar
				2, -- quantidade de blocos direita
				2 -- quantidade de blocos esquerda
			)
		end
	end

	function door.update()
		return true
	end

	return door
end

-- Key class --
local function Key(x, y)
	local key = Base()
	key.type = Constants.KEY
	key.sprite = Constants.SPRITE_KEY
	key.x = x
	key.y =	y
	key.make_collisions = {
		ENEMY = function() return false end,
		PLAYER = make_collision_player_with_objects,
		SWORD = function() return false end
	}
	key.visible = true

	function key.draw()
		if key.visible then
			spr(
				key.sprite,
				cam.x + key.x,
				cam.y + key.y,
				key.background, -- cor de fundo
				1, -- escala
				0, -- espelhar
				0, -- rotacionar
				2, -- quantidade de blocos direita
				2 -- quantidade de blocos esquerda
			)
		end
	end

	function key.update()
		return true
	end

	return key
end

-- Enemy class --
local function Enemy(x, y)
	local enemy = Base()
	enemy.type = Constants.ENEMY
	enemy.sprite = Constants.SPRITE_ENEMY
	enemy.state = States.STOP
	enemy.x = x
	enemy.y =	y
	enemy.background = 14
	enemy.animation = 1
	enemy.make_collisions = {
		ENEMY = function() return false end,
		PLAYER = restart_game,
		SWORD = make_collision_enemy_with_sword
	}
	enemy.visible = true

	function enemy.draw()
		if enemy.visible then
			spr(
				enemy.sprite,
				cam.x + enemy.x,
				cam.y + enemy.y,
				enemy.background, -- cor de fundo
				1, -- escala
				0, -- espelhar
				0, -- rotacionar
				2, -- quantidade de blocos direita
				2 -- quantidade de blocos esquerda
			)
		end
	end

	function enemy.update()
		if distancy(enemy, player) < Constants.VIEW_ENEMY then
			enemy.state = States.PURSUIT
		else
			enemy.state = States.STOP
		end

		if enemy.state == States.PURSUIT then
			local delta = {
				deltaX = 0,
				deltaY = 0
			}

			if player.y > enemy.y then
				delta.deltaY = 0.5
				enemy.direction = Constants.Direction.DOWN
			elseif player.y < enemy.y then
				delta.deltaY = - 0.5
				enemy.direction = Constants.Direction.UP
			end

			enemy.move(enemy, delta, enemy.direction)

			delta.deltaX = 0
			delta.deltaY = 0

			if player.x > enemy.x then
				delta.deltaX = 0.5
				enemy.direction = Constants.Direction.RIGHT
			elseif player.x < enemy.x then
				delta.deltaX = - 0.5
				enemy.direction = Constants.Direction.LEFT
			end

			enemy.move(enemy, delta, enemy.direction)

			local AnimationEnemy = {
				{288, 290},
				{292, 294},
				{296, 298},
				{300, 302}
			}

			local squad = AnimationEnemy[enemy.direction]
			enemy.sprite = squad[math.floor(enemy.animation)]
		end
	end

	return enemy
end

-- Sword class --
local function Sword(x, y)
	local sword = Base()
	sword.type = Constants.SWORD
	sword.x = x
	sword.y = y
	sword.background = 0
	sword.animation = 1
	sword.make_collisions = {
	  ENEMY = function() return false end,
		PLAYER = function() return false end,
		SWORD = function() return false end
	}
	sword.visible = false
	sword.timeout = 0

	function sword.draw()
		if sword.visible then
			spr(
				sword.sprite,
				cam.x + sword.x,
				cam.y + sword.y,
				sword.background, -- cor de fundo
				1, -- escala
				0, -- espelhar
				0, -- rotacionar
				2, -- quantidade de blocos direita
				2 -- quantidade de blocos esquerda
			)
		end
	end

	function sword.update()
		local data_sword = {
			{ x = 0, y = - 10, sprite = {324, 326} },	--UP
			{ x = 0, y = 10, sprite = {332, 334} },		--DOWN
			{ x = -10, y = 0, sprite = {320, 322} },	--LEFT
			{ x = 10, y = 0, sprite = {328, 330} }		--RIGHT
		}

		local direction = data_sword[player.direction]

		if player.direction then
			sword.x = player.x + direction.x
			sword.y = player.y + direction.y
			sword.sprite = direction.sprite[math.floor(sword.animation)]
		end

		if btn(4) and player.direction then
			sword.sprite = direction.sprite[math.floor(sword.animation)]
			sword.visible = true
			sword.timeout = 15
		end

		if sword.visible then
			check_collision_objects(sword, sword)

			sword.animation = sword.animation + Constants.SPEED_ANIMATION
			if sword.animation >= 3 then
				sword.animation = 1
			end

			sword.timeout = sword.timeout - 1
			if sword.timeout <= 0 then
				sword.visible = false
			end
		end
	end

	return sword
end

-- Player class --
local function Player(x, y, sword)
	local player = Base()
	player.type = Constants.PLAYER
	player.sprite = Constants.SPRITE_PLAYER
	player.x = x
	player.y = y
	player.animation = 1
	player.keys = 0
	player.sword = sword

	function player.draw()
		local block_x, block_y = (cam.x + player.x), (cam.y + player.y)

		spr(
			player.sprite,
			block_x,
			block_y,
			player.background, -- cor de fundo
			1, -- escala
			0, -- espelhar
			0, -- rotacionar
			2, -- quantidade de blocos direita
			2 -- quantidade de blocos esquerda
		)
	end

	function player.update()
		local animation_player = {
			{256, 258},
			{260, 262},
			{264, 266},
			{268, 270}
		}

	  local direction_player = {
			{deltaX = 0, deltaY = -1},
			{deltaX = 0, deltaY = 1},
			{deltaX = -1, deltaY = 0},
			{deltaX = 1, deltaY = 0}
		}

		for keyword = 0, 3 do
			if btn(keyword) then
				local direction = keyword + 1
				local squad = animation_player[direction]
				player.sprite = squad[math.floor(player.animation)]

				player.move(player, direction_player[direction], direction)
			end
		end

		player.sword.update()
	end

	return player
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

local function draw_objects()
	player.sword.draw()

	for i, enemy in pairs(Enemies) do
		enemy.draw()
	end

	for i, key in pairs(Keys) do
		key.draw()
	end

	for i, door in pairs(Doors) do
		door.draw()
	end
end

local function draw_menu()
	cls()

--	spr(
--		Constants.SPRITE_TITLE,
--		80,
--		10,
--		0,
--		1,
--		0,
--		0,
--		Constants.SPRITE_TITLE_LENGTH,
--		Constants.SPRITE_TITLE_HEIGHT
--	)

	print(Constants.ABOUT, 60, 128)
end

local function draw_game()
	cls()

	draw_map()
	draw_objects()
	player.draw()
end

function initialize()
	Enemies = {}
	Keys = {}
	Doors = {}

	cam = {
		x = 0,
		y = 0
	}

	local enemies = {
		{x = 26, y = 15, create = Enemy},
		{x = 45, y = 13, create = Enemy},
		{x = 5, y = 2, create = Enemy},
		{x = 4, y = 13, create = Enemy},
		{x = 26, y = 2, create = Enemy},
		{x = 580, y = 800, create = Enemy}
	}

	local keys = {
		{x = 3, y = 3, create = Key},
		{x = 25, y = 23, create = Key}
	}

	local doors = {
		{x = 17, y = 7, create = Door},
		{x = 48, y = 13, create = Door}
	}

	for i, enemy in pairs(enemies) do
		table.insert(Enemies, enemy.create(enemy.x, enemy.y))
	end

	for i, key in pairs(keys) do
		table.insert(Keys, key.create(key.x, key.y))
	end

	for i, door in pairs(doors) do
		table.insert(Doors, door.create(door.x, door.y))
	end

	local sword_init = Sword(0, 0)

	player = Player(500, 800, sword_init)

	end_game = {
		sprite = Constants.SPRITE_END_GAME,
		x = 448,
		y = 60,
		background = 1,
		visible = true,
		make_collisions = {
			ENEMY = function() return false end,
			PLAYER = final_match,
			SWORD = function() return false end
		}
	}
end

local function update_window_final()
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

Window = {
	MENU = {
	  update = update_window,
		draw = draw_menu
	},

	GAME = {
		update = update_game,
		draw = draw_game
	},

	END_GAME = {
		update = update_window_final,
		draw = draw_end_game
	}
}

window = Window.MENU
initialize()