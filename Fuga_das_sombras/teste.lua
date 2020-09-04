-- title:  Fuga das sombras
-- author: Douglas Eduardo Bauler
-- desc: RPG acao 2s
-- script: lua

player = {
		sprite = 260,
		x = 120,
		y = 68,
		background = 6,
		animation = 1,
		keys = 0
}

Constants = {
		WIDTH_WINDOW = 240,
		HEIGHT_WINDOW = 138,
		SPEED_ANIMATION = 0.1,
		SPRITE_KEY = 364,
		SPRITE_DOOR = 366,
		ID_SFX_KEY = 0,
		ID_SFX_DOOR = 1
}

Objects = {

}

function isCollision(point)
		return mget(point.x/8,point.y/8) >= 128
end

function testMoveFor(delta)
		local newPosition = {
				x = player.x + delta.deltaX,
				y = player.y + delta.deltaY
		}
		
		if checkCollisionObjects(newPosition) then
				return false
		end
		
		head_left = {
				x = player.x - 7 + delta.deltaX,
				y = player.y - 8 + delta.deltaY 
		}			
		head_right = {
				x = player.x + 7 + delta.deltaX,
				y = player.y - 8 + delta.deltaY
		}
		footer_right = {
				x = player.x + 7 + delta.deltaX,
				y = player.y + 7 + delta.deltaY
		}			

		footer_left = {
				x = player.x - 7 + delta.deltaX,
				y = player.y + 7 + delta.deltaY
		}
		
		if not (isCollision(head_left)
		or isCollision(head_right)
		or isCollision(footer_right)
		or isCollision(footer_left)) then
				player.animation =	player.animation + Constants.SPEED_ANIMATION
			 if player.animation >= 3 then
						player.animation = 1
				end	
				
				player.x = player.x + delta.deltaX
				player.y = player.y + delta.deltaY
		end
end

function move_update()
	AnimationPlayer = {
			{256, 258},
			{260, 262},
			{264, 266},
			{268, 270}
	}
	
	Direction = {
			{deltaX = 0, deltaY = -1},
			{deltaX = 0, deltaY = 1},
			{deltaX = -1, deltaY = 0},
			{deltaX = 1, deltaY = 0}
	}
	
	for keyword = 0, 3 do
			if btn(keyword) then
					squad = AnimationPlayer[keyword + 1]
					player.sprite = squad[math.floor(player.animation)]
					
				 testMoveFor(Direction[keyword+1])
			end
	end
end

function draw_map()
	-- desenho do mapa
	map(0,	-- posicao x no mapa
					0,	-- posicao u no mapa
					Constants.WIDTH_WINDOW,	-- quanto desenhar x
					Constants.HEIGHT_WINDOW,	-- quanto desenhar y
					0,	-- em qual ponto colocar o x
					0)	-- em qual ponto colocar o y
end

function draw_player()
	-- desenho jogador
	spr(player.sprite, 
					player.x - 8, 
					player.y - 8, 
					player.background, -- cor de fundo
					1, -- escala
					0, -- espelhar
					0, -- rotacionar
					2, -- quantidade de blocos direita
					2) -- quantidade de blocos esquerda
end

function draw_objects()
		for i, obj in pairs(Objects) do
				spr(obj.sprite, 
								obj.x - 8, 
								obj.y - 8, 
								obj.background, -- cor de fundo
								1, -- escala
								0, -- espelhar
								0, -- rotacionar
								2, -- quantidade de blocos direita
								2) -- quantidade de blocos esquerda
		end
end

function draw_game()
	cls()

	draw_map()
	draw_player()
	draw_objects()
end

function	makeCollisionPlayerWidthObjects(index)
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

function isCollisionObjects(objectA, objectB)
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

function makeCollisionPlayerWithDoor(index)
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

function checkCollisionObjects(newPosition)
		for i, obj in pairs(Objects) do
				if isCollisionObjects(newPosition, obj) then
						if obj.sprite == Constants.SPRITE_KEY then
								return makeCollisionPlayerWidthObjects(i)
						elseif obj.sprite == Constants.SPRITE_DOOR then
								return makeCollisionPlayerWithDoor(i)						
						end
				end
		end
		
		return false
end

function TIC()
	move_update()
	draw_game()
end

function createDoor(pCol, pLine)
		local door_create = {
				sprite = Constants.SPRITE_DOOR,
				x = pCol * 8 + 8,
				y =	pLine * 8 + 8,
				background = 6
		}
		
		return door_create
end

function createKey(pCol, pLine)
		local key_create = {
				sprite = Constants.SPRITE_KEY,
				x = pCol * 8 + 50,
				y =	pLine * 8 + 8,
				background = 6
		}
		
		return key_create
end

function initialize()
		local key_init = createKey(3, 3)
		table.insert(Objects, key_init)

		local door_init = createDoor(17, 7)
		table.insert(Objects, door_init)
end

initialize()