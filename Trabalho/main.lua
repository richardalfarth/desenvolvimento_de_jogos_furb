-- title:  Fuga das sombras
-- author: Douglas Eduardo Bauler
-- desc: RPG acao 2s
-- script: lua

States = {
	STOP = "STOP",
	PURSUIT = "PURSUIT"
}

Constants = {
	VIEW_ENEMY = 58,
	TIMEOUT_NEXT_WINDOW = 45,

	WIDTH_WINDOW = 240,
	HEIGHT_WINDOW = 138,
	SPEED_ANIMATION = 0.1,

	SPRITE_KEY = 364,
	SPRITE_DOOR = 366,
	SPRITE_ENEMY = 292,
	SPRITE_END_GAME = 1,

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

	Direction = {
		UP = 1,
		DOWN = 2,
		LEFT = 3,
		RIGHT = 4
    }
}

Objects = {}

function is_collision(point)
	return mget(point.x/8, point.y/8) >= 128
end

function test_move_for(personal, delta, direction_actual)
	local newPosition = {
		x = personal.x + delta.deltaX,
		y = personal.y + delta.deltaY
	}

	if check_collision_objects(personal, newPosition) then
		return false
	end

	local head_left = {
		x = personal.x - 7 + delta.deltaX,
		y = personal.y - 8 + delta.deltaY
    }
    local head_right = {
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

	if not (is_collision(head_left)
    or is_collision(head_right)
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

function distancy(enemy, player)
	local dist_x = enemy.x - player.x
	local dist_y = enemy.y - player.y
	local dist = (dist_x * dist_x) + (dist_y * dist_y)

	return math.sqrt(dist)
end

function update_enemy(enemy)
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

		local delta = {
			deltaX = 0,
			deltaY = 0
		}

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

function update_sword()
	local DataSword = {
		{ x = 0, y = - 16, sprite = 324 },
		{ x = 0, y = 16, sprite = 332 },
		{ x = -16, y = 0, sprite = 320 },
		{ x = 16, y = 0, sprite = 328 }
	}

	if player.direction then
		local direction = DataSword[player.direction]
		player.sword.x = player.x + direction.x
		player.sword.y = player.y + direction.y
		player.sword.sprite = direction.sprite
	end

	if btn(4) and player.direction then
		local direction = DataSword[player.direction]
		player.sword.sprite = direction.sprite
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
		player.sword.timeout = player.sword.timeout - 1

		if player.sword.timeout <= 0 then
			player.sword.visible = false
		end
	end
end

function update_game()
	local AnimationPlayer = {
		{256, 258},
		{260, 262},
		{264, 266},
		{268, 270}
	}

    local DirectionPlayer = {
		{deltaX = 0, deltaY = -1},
		{deltaX = 0, deltaY = 1},
		{deltaX = -1, deltaY = 0},
		{deltaX = 1, deltaY = 0}
	}

    for keyword = 0, 3 do
		if btn(keyword) then
			local direction = keyword + 1
			local squad = AnimationPlayer[direction]
            player.sprite = squad[math.floor(player.animation)]

            test_move_for(player, DirectionPlayer[direction], direction)
		end
	end

	update_sword()

	check_collision_objects(player, {x = player.x, y = player.y})

	for i, obj in pairs(Objects) do
		if obj.type == Constants.ENEMY then
            update_enemy(obj)
		end
	end

	cam.x = (player.x // 240) * 240
	cam.y = (player.y // 136) * 136
end

function draw_map()
    local block_x = cam.x / 8
    local block_y = cam.y / 8

	map(block_x,	-- posicao x no mapa
        block_y,	-- posicao u no mapa
		Constants.WIDTH_WINDOW,	-- quanto desenhar x
		Constants.HEIGHT_WINDOW,	-- quanto desenhar y
		0,	-- em qual ponto colocar o x
        0 -- em qual ponto colocar o y
    )
end

function draw_player()
	spr(
        player.sprite,
		player.x - 8 - cam.x,
		player.y - 8 - cam.y,
		player.background, -- cor de fundo
		1, -- escala
		0, -- espelhar
		0, -- rotacionar
		2, -- quantidade de blocos direita
        2 -- quantidade de blocos esquerda
    )
end

function draw_objects()
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

function make_collision_player_width_objects(index)
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

function is_collision_objects(objectA, objectB)
	local leftForA = objectA.x + 7
	local rightForA = objectA.x - 8
	local underForA = objectA.y + 7
	local upForA = objectA.y - 8

	local leftForB = objectB.x - 8
	local rightForB = objectB.x + 7
	local underForB = objectB.y + 7
	local upForB = objectB.y - 8

    return not (leftForB > rightForA
	        or rightForB < leftForA
			or underForA < upForB
			or upForA > underForB)
end

function make_collision_player_with_door(index)
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

function check_collision_objects(personal, newPosition)
	for i, obj in pairs(Objects) do
	    if is_collision_objects(newPosition, obj) then
		    return obj.make_collisions[personal.type](i)
		end
	end

	return false
end

function draw_menu()
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

function update_window()
	if btn(4) then
	    sfx(
			Constants.ID_SFX_INIT,
			72,
			32,
			0,
			8,
			0
		)

        changeWindow(Window.GAME)
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

function draw_game()
	cls()

	draw_map()
	draw_objects()
	draw_player()
end

function restartGame(index)
	initialize()
	window = Window.MENU
    return true
end

function make_collision_enemy_with_door(index)
	return true
end

function make_collision_enemy_with_sword(index)
	table.remove(Objects, index)
	return false
end

function final_match()
	sfx(
		Constants.ID_SFX_END_GAME,
		36,
		32,
		0,
		8,
		0
	)

	changeWindow(Window.END_GAME)
end

function leave(index)
	return false
end

function create_enemy(pCol, pLine)
	local enemy = {
	    type = Constants.ENEMY,
		sprite = Constants.SPRITE_ENEMY,
		state = States.STOP,
		x = pCol * 8 + 8,
		y =	pLine * 8 + 8,
		background = 14,
		animation = 1,
		make_collisions = {
			ENEMY = leave,
			PLAYER = restartGame,					
			SWORD = make_collision_enemy_with_sword
		},
		visible = true
    }

    return enemy
end

function create_door(pCol, pLine)
	local door_create = {
		sprite = Constants.SPRITE_DOOR,
		x = pCol * 8 + 8,
		y =	pLine * 8 + 8,
		background = 6,
		make_collisions ={
	    	ENEMY = make_collision_enemy_with_door,
			PLAYER = make_collision_player_with_door,
			SWORD = leave
		},
		visible = true
	}
		
	return door_create
end

function create_key(pCol, pLine)
	local key_create = {
		sprite = Constants.SPRITE_KEY,
		x = pCol * 8,
		y =	pLine * 8,
		background = 6,
		make_collisions = {
		    ENEMY = leave,
			PLAYER = make_collision_player_width_objects,
			SWORD = leave
		},
		visible = true
	}
		
	return key_create
end

function create_sword(pCol, pLine)
	local sword = {
		type = Constants.SWORD,
		x = pCol + 8,
		y = pLine + 8,
		background = 0,
		make_collisions = {
		    ENEMY = leave,
			PLAYER = leave,
			SWORD = leave
		},
		visible = false,
		timeout = 0
	}

	return sword
end

function initialize()
	Objects = {}

	cam = {
		x = 0,
		y = 0
	}

	local enemies = {
		{x = 26, y = 15},
		{x = 45, y = 13},
		{x = 5, y = 2},
		{x = 4, y = 13},
		{x = 26, y = 2}
	}

	for i, obj in pairs(enemies) do
		table.insert(Objects, create_enemy(obj.x, obj.y))
	end
		
	local key_init = create_key(3, 3)
	table.insert(Objects, key_init)

	local key_init2 = create_key(25, 23)
	table.insert(Objects, key_init2)

	local door_init = create_door(17, 7)
	table.insert(Objects, door_init)

	local door_init2 = create_door(48, 13)
	table.insert(Objects, door_init2)

	local sword_init = create_sword(0, 0)
	table.insert(Objects, sword_init)
		
	player = {
	 	type = Constants.PLAYER,
		sprite = 260,
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

function changeWindow(newWindow)
	timeout_change_window = Constants.TIMEOUT_NEXT_WINDOW
	nextWindow = newWindow
end

function update_window_final()
	if btn(4) then
		initialize()
		changeWindow(Window.MENU)
	end
end

function draw_end_game()
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
		draw =	draw_game
	},

	END_GAME = {
		update = update_window_final,
		draw =	draw_end_game
	}
}

window = Window.MENU
initialize()