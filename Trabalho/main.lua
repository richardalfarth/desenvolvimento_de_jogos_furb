-- title:  Fuga das sombras
-- author: Douglas Eduardo Bauler
-- desc: RPG acao 2s
-- script: lua

local States = {
	STOP = "STOP",
	PURSUIT = "PURSUIT"
}

local Constants = {
	VIEW_ENEMY = 58,
	TIMEOUT_NEXT_WINDOW = 45,

	WIDTH_WINDOW = 240,
	HEIGHT_WINDOW = 138,
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
	return mget(point.x / 8, point.y / 8) >= 128
end

local function make_collision_player_with_objects(index)
	local obj = Objects[index]
	player.keys = player.keys + 1

	table.remove(Objects, index)
	sfx(
		Constants.ID_SFX_CHAVE,
		60,
		32,
		0,
		8,
		1
	)

  return false
end

local function is_collision_objects(objectA, objectB)
	local leftForA = objectA.x + 8
	local rightForA = objectA.x - 8
	local underForA = objectA.y + 8
	local upForA = objectA.y - 8

	local leftForB = objectB.x - 8
	local rightForB = objectB.x + 8
	local underForB = objectB.y + 8
	local upForB = objectB.y - 8

  return not (leftForB > rightForA
					or rightForB < leftForA
					or underForA < upForB
					or upForA > underForB)
end

local function make_collision_player_with_door(index)
	if player.keys > 0 then
	  player.keys = player.keys - 1
    table.remove(Objects, index)

		sfx(
	    Constants.ID_SFX_DOOR,
			60,
			32,
			0,
			8,
			1
		)

		return false
	end

  return true
end

local function check_collision_objects(personal, newPosition)
	for i, obj in pairs(Objects) do
	  if is_collision_objects(newPosition, obj) then
		  return obj.make_collisions[personal.type](i)
		end
	end

	return false
end

local function test_move_for(personal, delta, direction_actual)
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

local function distancy(enemy, player)
	local dist_x = enemy.x - player.x
	local dist_y = enemy.y - player.y
	local dist = (dist_x * dist_x) + (dist_y * dist_y)

	return math.sqrt(dist)
end

local function update_game()
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

      test_move_for(player, direction_player[direction], direction)
		end
	end

	player.sword.update()

	check_collision_objects(player, player)

	for i, obj in pairs(Objects) do
		if obj.type == Constants.ENEMY then
      obj.update(obj)
		end
	end

	cam.x = (player.x // Constants.WIDTH_WINDOW) * Constants.WIDTH_WINDOW
	cam.y = (player.y // Constants.HEIGHT_WINDOW) * Constants.HEIGHT_WINDOW
end

local function update_window()
	if btn(4) then
	  sfx(
			Constants.ID_SFX_INIT,
			72,
			32,
			0,
			8,
			0
		)

    change_window(Window.GAME)
	end
end

function TIC()
	if nextWindow then
		if timeout_change_window > 0 then
			timeout_change_window  = timeout_change_window - 1
		end
		if timeout_change_window == 0 then
			window = nextWindow
			nextWindow = nil
		end
	else
		window.update()
	end

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
	table.remove(Objects, index)
	return false
end

local function final_match()
	sfx(
		Constants.ID_SFX_END_GAME,
		36,
		32,
		0,
		8,
		0
	)

	change_window(Window.END_GAME)
end

local function leave(index)
	return false
end

local function draw_player()
	local	block_x = cam.x
	local	block_y = cam.y

	spr(
    player.sprite,
		player.x - 8 - block_x,
		player.y - 8 - block_y,
		player.background, -- cor de fundo
		1, -- escala
		0, -- espelhar
		0, -- rotacionar
		2, -- quantidade de blocos direita
    2 -- quantidade de blocos esquerda
	)
end

-- Base class
local function Base()
	local base = {
		type = nil,
		sprite = nil,
		x = 0,
		y = 0,
		background = 0,
		animation = 0,
		make_collisions = nil,
		visible = false,
		timeout = 0
	}

	return base
end

local function Door(p_x, p_y)
	local door = Base()
	door.sprite = Constants.SPRITE_DOOR
	door.x = p_x * 8 + 8
	door.y =	p_y * 8 + 8
	door.background = 6
	door.make_collisions = {
	  ENEMY = make_collision_enemy_with_door,
		PLAYER = make_collision_player_with_door,
		SWORD = leave
	}
	door.visible = true

	return door
end

local function Key(p_x, p_y)
	local key = Base()
	key.type = Constants.KEY
	key.sprite = Constants.SPRITE_KEY
	key.x = p_x * 8
	key.y =	p_y * 8
	key.background = 6
	key.make_collisions = {
		ENEMY = leave,
		PLAYER = make_collision_player_with_objects,
		SWORD = leave
	}
	key.visible = true

	return key
end

-- Enemy class --
local function Enemy(p_x, p_y)
	local enemy = Base()
	enemy.type = Constants.ENEMY
	enemy.sprite = Constants.SPRITE_ENEMY
	enemy.state = States.STOP
	enemy.x = p_x * 8 + 8
	enemy.y =	p_y * 8 + 8
	enemy.background = 14
	enemy.animation = 1
	enemy.make_collisions = {
		ENEMY = leave,
		PLAYER = restart_game,
		SWORD = make_collision_enemy_with_sword
	}
	enemy.visible = true

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

			test_move_for(enemy, delta, enemy.direction)

			delta.deltaX = 0
			delta.deltaY = 0

			if player.x > enemy.x then
				delta.deltaX = 0.5
				enemy.direction = Constants.Direction.RIGHT
			elseif player.x < enemy.x then
				delta.deltaX = - 0.5
				enemy.direction = Constants.Direction.LEFT
			end

			test_move_for(enemy, delta, enemy.direction)

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
local function Sword(p_x, p_y)
	local sword = Base()
	sword.type = Constants.SWORD
	sword.x = p_x + 8
	sword.y = p_y + 8
	sword.background = 0
	sword.animation = 1
	sword.make_collisions = {
	  ENEMY = leave,
		PLAYER = leave,
		SWORD = leave
	}
	sword.visible = false
	sword.timeout = 0

	function sword.update()
		local data_sword = {
			{ x = 0, y = - 10, sprite = {324, 326} },	--UP
			{ x = 0, y = 10, sprite = {332, 334} },		--DOWN
			{ x = -10, y = 0, sprite = {320, 322} },	--LEFT
			{ x = 10, y = 0, sprite = {328, 330} }		--RIGHT
		}

		local direction = data_sword[player.direction]

		if player.direction then
			player.sword.x = player.x + direction.x
			player.sword.y = player.y + direction.y
			player.sword.sprite = direction.sprite[math.floor(player.sword.animation)]
		end

		if btn(4) and player.direction then
			player.sword.sprite = direction.sprite[math.floor(player.sword.animation)]
			player.sword.visible = true
			player.sword.timeout = 15
			sfx(
				Constants.ID_SFX_SWORD,
				86,
				15,
				0,
				8,
				2
			)
		end

		if player.sword.visible then
			check_collision_objects(player.sword, player.sword)

			player.sword.animation = player.sword.animation + Constants.SPEED_ANIMATION
			if player.sword.animation >= 3 then
				player.sword.animation = 1
			end

			player.sword.timeout = player.sword.timeout - 1
			if player.sword.timeout <= 0 then
				player.sword.visible = false
			end
		end
	end

	return sword
end

local function draw_map()
	local block_x = cam.x / 8
	local block_y = cam.y / 8

	map(
		block_x,									-- posicao x no mapa
    block_y,									-- posicao y no mapa
		Constants.WIDTH_WINDOW,		-- quanto desenhar x
		Constants.HEIGHT_WINDOW,	-- quanto desenhar y
		0,												-- em qual ponto colocar o x
    0 												-- em qual ponto colocar o y
  )
end

local function draw_objects()
	for i, obj in pairs(Objects) do
		if obj.visible then
			spr(
				obj.sprite,
				obj.x - 8 - cam.x,
				obj.y - 8 - cam.y,
				obj.background, -- cor de fundo
				1, -- escala
				0, -- espelhar
				0, -- rotacionar
				2, -- quantidade de blocos direita
				2 -- quantidade de blocos esquerda
			)
		end
	end
end

local function draw_menu()
	cls()

	spr(
		Constants.SPRITE_TITLE,
		80,
		10,
		0,
		1,
		0,
		0,
		Constants.SPRITE_TITLE_LENGTH,
		Constants.SPRITE_TITLE_HEIGHT
	)

	print(Constants.ABOUT, 60, 128)
end

local function draw_game()
	cls()

	draw_map()
	draw_objects()
	draw_player()
end

function initialize()
	Objects = {}

	cam = {
		x = 0,
		y = 0
	}

	local objects = {
		{x = 26, y = 15, create = Enemy},
		{x = 45, y = 13, create = Enemy},
		{x = 5, y = 2, create = Enemy},
		{x = 4, y = 13, create = Enemy},
		{x = 26, y = 2, create = Enemy},
		{x = 3, y = 3, create = Key},
		{x = 25, y = 23, create = Key},
		{x = 17, y = 7, create = Door},
		{x = 48, y = 13, create = Door}
	}

	for i, obj in pairs(objects) do
		table.insert(Objects, obj.create(obj.x, obj.y))
	end

	local sword_init = Sword(0, 0)
	table.insert(Objects, sword_init)

	player = {
	 	type = Constants.PLAYER,
		sprite = Constants.SPRITE_PLAYER,
		x = 110,
		y = 38,
		background = 6,
		animation = 1,
		keys = 0,
		sword = sword_init
	}

	end_game = {
		sprite = Constants.SPRITE_END_GAME,
		x = 448,
		y = 60,
		background = 1,
		visible = true,
		make_collisions = {
			ENEMY = leave,
			PLAYER = final_match,
			SWORD = leave
		}

	}
	table.insert(Objects, end_game)
end

local function change_window(new_window)
	timeout_change_window = Constants.TIMEOUT_NEXT_WINDOW
	nextWindow = new_window
end

local function update_window_final()
	if btn(4) then
		initialize()
		change_window(Window.MENU)
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

last_chekpoint = nil
window = Window.MENU
initialize()