pico-8 cartridge // http://www.pico-8.com
version 10
__lua__

--
-- #globals and system needs
--
ver="v1.0"

gt=0
ef=function() end
cart=function(u,d) cart_update,cart_draw=u,d gt=0 end
cart(ef,ef)

--
-- #player
function p_init()
	p_dead=false
	p_x,p_y,p_spd=0,0,1
	p_cx,p_cy=p_x+8,p_y+8
	p_hbox={y=4,x=4,w=7,h=7}
	p_sflip=false
	p_freeze=0
	p_st=1 -- state: 1=unarmed, 2=gun, 3=bait
	p_spr=32
	p_transport_t=0
	
end

function p_update()
	p_cx=p_x+8
	p_cy=p_y+8
	p_tx,p_ty=px_to_tile(p_cx,p_cy)
	p_dx,p_dy=0,0
	p_xdir,p_ydir=0,0

	local tile=get_tile(p_tx,p_ty)

	if not map_mode then
		minimap_battery=max(minimap_battery-1,0)
		p_freeze=max(p_freeze-1,0)
		
		if p_freeze<=0 then
			if btnl	then p_xdir=-1 p_sflip=true end
			if btnr	then p_xdir=1 p_sflip=false end
			if btnu	then p_ydir=-1 end
			if btnd	then p_ydir=1 end
		end

		p_dx=p_spd*p_xdir
		p_dy=p_spd*p_ydir

		if not move_is_blocked(p_x,p_y, p_dx,p_dy, p_hbox) then
			p_x+=p_dx
			p_y+=p_dy	
		end


		-- when player gets to a body, switch modes
		if tile.occupant=="body" then
			if rnd()<.5 then
				p_st=2
				p_spr=64
				add_ticker_text("pulse rifle equipped",true)
			else
				p_st=3
				p_spr=96
				add_ticker_text("alien bait equipped",true)
			end

			set_tile_occupant(p_tx,p_ty,"empty")
		end
		
		-- when player gets to a body, switch modes
		if tile.occupant=="egg" then
			eggs_collected=min(eggs_collected+1,20)
			current_level.eggs=max(current_level.eggs-1,0)

			set_tile_occupant(p_tx,p_ty,"empty")
			
			add_ticker_text("alien egg collected",true)
			
			
			if eggs_collected>=20 then
				add_ticker_text("mission accomplished;return to transport beacon",true)
			end
		end
		
		-- #bombarm
		-- player must hover to arm bomb
		-- bomb_st: 0=unarmed;1=onhover;2=armed
		if tile.occupant=="bomb" and tile.bomb_st<2 then
			if bomb_t==0 then add_ticker_text("arming bomb, stand by",true) end
			bomb_t+=1
			
			tile.bomb_st=1
			
			if bomb_t==sec(4) then 
				tile.bomb_st=2 
				current_level.bombs=max(0,current_level.bombs-1)
				--@sound bomb armed success
			end
		else
			if tile.bomb_st==2 then 
				add_ticker_text("bomb armed successfully",true) 
				if current_level.bombs>0 then
					add_ticker_text(current_level.bombs.." unarmed bombs remain") 
				else
					add_ticker_text("all bombs armed;find detonator to start countdown") 
				end
			end
			bomb_t=0
			tile.bomb_st=0
		end
		
		
		-- #dentonaor
		-- player must hover to trigger
		-- detonator_st: 0=unarmed;1=onhover;2=armed
		if tile.occupant=="detonator" and tile.detonator_st<2 then
			if detonator_t==0 then add_ticker_text("entering detonation code, stand by",true) end
			detonator_t+=1
			
			tile.detonator_st=1
			
			if detonator_t==sec(4) then 
				tile.detonator_st=2 
				add_ticker_text("countdown initiated;you have 30 seconds to reach transport beacon",true)
				countdown=30
				--@sound bomb armed success
			end
		else
			if tile.bomb_st==2 then  end
			bomb_t=0
			tile.bomb_st=0
		end
		
		
		-- #transport
		-- player hits transport beacon
		if tile.occupant=="transport" and current_level.eggs>0 and p_transport_t<1 then
			-- @sound buzzer
			add_ticker_text("dropship unavailable;alien eggs remain",true)
			p_transport_t=1
		end
		
		if tile.occupant=="transport" and current_level.eggs<=0 and not p_transport then
			-- @sound dropship call
			add_ticker_text("dropship landing, stay at beacon;leaving "..current_level.name,true)
			p_transport=true
			p_transport_t=2
		end
		
		if tile.occupant!="transport" and p_transport_t>0 then p_transport_t=0 end

		if tile.occupant!="transport" and p_transport then
			add_ticker_text("dropship cancelled",true)
			p_transport=false
			p_transport_t=0
		end
		
		if tile.occupant=="transport" and p_transport then
			p_transport_t+=1

			if p_transport_t==sec(9) then
				if eggs_collected>=20 then
					finale_init()
				else
					nextlevel_init()	
				end
				
			end
		end


	
		-- turn on minimap 
		if btnzp then
			if minimap_battery<=0 then
				generate_minimap()
				map_mode=true
			else
				-- @sound buzzer
				add_ticker_text("scanner battery recharging",true)
			end
		end
		
		-- use item
		if btnxp then
			-- beacon
			if p_st==3 then
				-- @sound bait noise
				add_bait(p_tx,p_ty)
				p_st=1
				p_spr=32
				
			end


			-- fire gun
			if p_st==2 then
				-- @sound bullet shot
				
				-- create player bullet object
				local targets={}
				local obj={x=p_cx,y=p_y+5,c=10}
				local heading=0

				for a in all(actors) do
					if a.id==2 or a.id==1 then -- only target huggers and aliens, not snipers
						if in_range(a.cx,a.cy, p_cx,p_cy, 60) then
							add(targets,a)
						end
					end
				end

				if p_sflip then heading=.5 end

				if #targets>0 then
					local target = find_nearest(p_cx,p_cy, targets)
					heading      = atan2(target.cx-p_cx, target.cy-p_cy) 
				end

				obj.dx,obj.dy = dir_calc(heading, 3)
				obj.update=function(self)
					for a in all(get_aliens()) do
							if in_range(self.x,self.y, a.cx,a.cy, 10) then
								chg_st(a,99)
								del(bullets,self)
							end
						
					end
				end
				
				add(bullets,obj)
				
				p_st=1
				p_spr=32
			end

		end
		
	else
		if btnzp then
			minimap_battery=sec(8)
			map_mode=false
		end
	end -- /map_mode
end

function p_draw()
	spr(p_spr, p_x,p_y, 2,2, p_sflip)
end




-- #bullets
-- common actions for all bullets. creation object is within actor update
function bullet_update()
	for b in all(bullets) do
		b.x+=b.dx
		b.y+=b.dy

		if px_inbounds(b.x,b.y) then 
			local t=get_px_tile(b.x,b.y)
			local px,py,cx,cy=tile_to_px(t.tx,t.ty)
			if t.occupant=="wall" then
				if in_range(b.x,b.y, cx,cy, 12) then
					del(bullets,b)
				end
			end

			b.update(b)
		else
			del(bullets,b) 
		end
	end
end


function bullet_draw()
	for b in all(bullets) do circfill(b.x,b.y, 2, b.c) end
end







--
-- #actors
-- npcs and ai


-- #bait - attracts aliens for limited time
-- adds bait actor to map
function add_bait(tx,ty)
	x,y=tile_to_px(tx,ty)
	local obj={
		id=3,
		x=x,y=y,
		cx=x+8,cy=y+8,
		t=0,
		update=function(self)
			for a in all(actors) do
				if a.id==2 then
					if in_range(a.cx,a.cy, self.cx,self.cy, 50) then
						if self.t>sec(5) then -- release alien after 5 seconds
							chg_st(a,0)
							a.beacon=false
						else
							if a.id!=10 then
								chg_st(a,10)
								a.beacon=self
							end
						end
						
					end
				end
			end
		
			
			if self.t>sec(5) then
				del(actors,self)
			end
			
			self.t+=1
		end,
		draw=function(self)
			spr(11, self.x+4,self.y, 1,2)
		end
	}	

	
	add(actors,obj)
end


-- #hugger
-- creates facehugger actor at tile coordinate
-- add_hugger(int_tilex,int_tiley)
function add_hugger(tx,ty)
	local obj={
		id=1,
		tx=tx,ty=ty,dx=0,dy=0,
		flip=false,
		detect=40,
		wander_spd=.7,
		chase_spd=1.3,
		hbox={x=4,y=6,w=8,h=5}, -- used for movement collision
		st=0,t=1, --1=sleep,2=finding path,3=moving,4=at goal,5=chase,6=trapped/die
		chase=false,
		navpath={},
		update=function(self)
			update_walker(self)

			if self.tile.occupant=="body" then
				set_tile_occupant(self.tx,self.ty,"empty")
				add_ticker_text("new alien detected;avoid close proximity")
				add_alien(self.tx,self.ty)
				del(actors,self)
			end
			
			if self.st==99 and self.t>sec(3) then
				del(actors,self)
			end
			
			self.t+=1
		end,
		draw=function(self)
			if self.st!=99 then
				if self.chase then pal(15,8) end -- switch to red hugger

				spr(160,self.x,self.y,2,2,self.flip)
			else
				spr(44,self.x,self.y,2,2)
			end
		end
	}
	
	obj.x,obj.y=tile_to_px(tx,ty)
	obj.cx=obj.x+8
	obj.cy=obj.y+8

	add(actors, obj)
end


-- #alien
function add_alien(tx,ty)
	local obj={
		id=2,
		tx=tx,ty=ty,dx=0,dy=0,
		flip=false,
		hbox={x=4,y=4,w=8,h=8},
		st=0,t=1, --1=sleep,2=finding path,3=moving,4=at goal,5=chase,6=trapped/die
		detect=50,
		wander_spd=.5,
		chase_spd=1.1,
		chase=false,
		navpath={},
		beacon=false,
		update=function(self)
			-- alien is always looking for player. this will skip the delay-find state of huggers
			if self.st<10 then
				if in_range(p_cx,p_cy, self.cx,self.cy, 50) then
					if not self.chase then
						chg_st(self,4)
					end
				else
					self.chase=false
				end
			end
		
			update_walker(self)
			
			-- within a beacon, go there and sleep
			if self.st==10 then
				self.chase=false
				local heading   = atan2(self.beacon.cx-self.x, self.beacon.cy-self.y) 
				self.dx,self.dy = dir_calc(heading, 1) -- wander speed
				self.flip=sprite_flip(heading)
				self.chase=false
				
				chg_st(self,11)
			end
			
			if self.st==11 then
				if not in_range(self.beacon.cx,self.beacon.cy, self.cx,self.cy, 10) then
					if not move_is_blocked(self.x,self.y, self.dx,self.dy, self.hbox) then
						self.x+=self.dx
						self.y+=self.dy
					end
				end
			end
			
			if self.st==99 and self.t>sec(3) then
				del(actors,self)
			end
			
			self.t+=1
		end,
		draw=function(self)
			if self.st!=99 then
				if self.chase then pal(13,8) end -- switch to red when in chase

				spr(128,self.x,self.y,2,2,self.flip)
			else
				-- dead bones
				spr(44,self.x,self.y,2,2)
			end
			
			
		end
	}
	
	obj.x,obj.y=tile_to_px(tx,ty)
	obj.cx=obj.x+8
	obj.cy=obj.y+8

	add(actors, obj)
end


-- #sniper
function add_sniper(tx,ty,flip)
	local obj={
		id=4,
		tx=tx,ty=ty,
		flip=flip,
		st=1,t=1,
		update=function(self)
			if flip then
				ox=self.x-32
				oy=self.y+4
			else
				ox=self.x+16
				oy=self.y+4
			end
			
			if self.st==1 then

				if in_hitbox(p_cx,p_cy, ox,oy, 32,8) then
					-- sniper bullet object
					-- @sound sniper shot
					local obj={
						dx=4,x=self.x+16,
						c=13,dy=0,
						y=self.y+8,
						update=function(b)
							if b.x>=p_cx-8 and b.x<=p_cx+8 then
								del(bullets,b)
								p_freeze=200
							end
						end
					}
				
					if self.flip then 
						obj.dx=-3 
						obj.x=self.x
					end
					
					
					
					add(bullets,obj)
					
					chg_st(self,2)
				end
			end
			
			-- shot spent, turn into a bush
			if self.st==2 then
				if self.t>sec(1) then
					local t=set_tile_occupant(self.tx,self.ty, "wall")
					t.spr=rnd_table(bush_sprites)
					del(actors,self)
				end
			end
			
			self.t+=1
		end,
		draw=ef
	}
	
	
	
	obj.x,obj.y=tile_to_px(tx,ty)

	add(actors, obj)
end



-- #walker - common logic for actors that move around the map
function update_walker(self)
	-- self is actor object - id: 1=hugger, 2=alien
	local id=self.id
	local dest={}
	
	self.cx=self.x+8
	self.cy=self.y+8
	self.tx,self.ty=px_to_tile(self.cx,self.cy)
	self.tile=get_tile(self.tx,self.ty)

	-- caught the player; end state and game over
	-- #dead
	if self.st<99 then
		if in_range(self.cx,self.cy, p_cx,p_cy, 10) then
			chg_st(self,98)
			p_dead=true
			level_list={}
			make_blood()
			p_spr=46
			
			-- @sound death blow, only once
			
			gt=0
			add_ticker_text("you are dead;press \142 to continue;you collected "..eggs_collected.." eggs;press \142 to continue",true)
		end
	end


	-- initial pathfinding
	if self.st==0 then
		self.chase=false
		self.speed=self.wander_spd
		
		if self.t<2 then
			local near=false

			--hugger
			if id==1 then
				printh("huggered")
				near=find_nearest(self.x,self.y, filter_tiles("body"))
				self.wpcount=5
			end
			
			-- alien
			if id==2 then
				self.wpcount=3
			end
			

			-- use random empty for body-free map and aliens
			if not near then 
				near={tx=self.tx,ty=self.ty}
				while near.tx==self.tx and near.ty==self.ty do
					near=get_random_tile("empty") 
				end
			end

			self.navpath,self.endpoint,self.waypoint=pathfind(self.tx,self.ty, near.tx,near.ty)
		end
		
		-- "thinking" delay, only start moving after 2 seconds
		if self.t>sec(2) then
			chg_st(self,1)
		end
	end
	
	
	-- get heading towards next waypoint
	if self.st==1 then
		self.dest=level_list[self.navpath[self.waypoint]]
		
		if not self.dest then
			chg_st(self,0)
		else
			self.dest.x,self.dest.y=tile_to_px(self.dest.tx,self.dest.ty)	

			local heading   = atan2(self.dest.x-self.x, self.dest.y-self.y) 
			self.dx,self.dy = dir_calc(heading, self.speed) -- wander speed
			self.flip=sprite_flip(heading)

			chg_st(self,2)
		end
	end
	
	
	-- movement towards waypoint
	if self.st==2 then
		self.x+=self.dx
		self.y+=self.dy
		
		-- if actor is chasing player but player escapes, keep going along path like normal but wander speed
		if self.chase and not in_range(p_cx,p_cy, self.cx,self.cy, self.detect+15) then
			self.chase=false
			self.speed=self.wander_spd
			self.wpcount=rand(3)+2
			--self.waypoint=#self.navpath
			--chg_st(self,0)
		end
		
		
		-- if actor's midpoint is within mid-tile, go to next waypoint
		if in_range(self.cx,self.cy, self.dest.x+8,self.dest.y+8, 5) then
			self.waypoint+=1
			self.wpcount-=1

			-- when at end of path, find a new path
			-- or if they've moved the limit number of spots, delay and do more
			if self.waypoint>#self.navpath then
				chg_st(self,0)
			else
				if self.wpcount==0 then
					chg_st(self,3) -- moved segment limit, switch to wait before continuing
				else
					chg_st(self,1) -- move again to next waypoint
				end
			end
		end
		
	end
	
	
	
	-- artificial delay before more movement
	if self.st==3 then
		-- see if player in range and switch to chase mode; range extended during rest
		
		if in_range(p_cx,p_cy, self.cx,self.cy, self.detect) then
			chg_st(self,4)
		else
			if self.t>sec(2.5) then
				--hugger
				if id==1 then
					-- if body tile is gone, repath to find next body or start wandering
					local tile=get_tile(self.endpoint.tx,self.endpoint.ty)
					if tile.occupant=="body" then
						self.wpcount=rand(6)+2
						chg_st(self,1)
					else
						chg_st(self,0)
					end
				end

				-- alien
				if id==2 then
					self.wpcount=rand(3)+2 --fewer segements, stopping a lot
					chg_st(self,1)	
				end
			end
		end
	end
	
	
	-- enter chase state; pathfind to player and speed up
	if self.st==4 then
		self.navpath,self.endpoint,self.waypoint=pathfind(self.tx,self.ty, p_tx,p_ty)	
		self.speed=self.chase_spd --chase speed
		self.wpcount=99 --so there are no stops along the way
		self.chase=true
		chg_st(self,1)
	end

end


-- update logic for ai that finds targets and wanders: huggers and aliens
-- 

function pathfind(startx,starty,goaltx,goalty)
	local navpath=find_path({x=startx,y=starty}, {x=goaltx,y=goalty})
	local endpoint=level_list[navpath[#navpath]]
	
	return navpath,endpoint,1
end


function sprite_flip(d)
	if d>.25 and d<.75 then return true end
	return false
end




function add_bodies(q)
	local c,try=0,0
	
	--printh("adding bodies: "..q)
	while c<q and try<50 do
		local t=get_random_tile("empty")
		local list=filter_tiles("body")
		
		if #list>0 then
			--printh("checking existinb bodies")
		
			for n in all(list) do
				if not in_range(n.tx,n.ty, t.tx,t.ty, 3) then
					if not in_range(t.tx,t.ty, p_tx,p_ty, 4) then
						set_tile_occupant(t.tx,t.ty, "body")
						--printh("added at "..t.tx..","..t.ty)
						c+=1
					end
				end
			end
		else
			--printh("no existinb bodies")
		
			if not in_range(t.tx,t.ty, p_tx,p_ty, 4) then
				--printh("added at "..t.tx..","..t.ty)
				set_tile_occupant(t.tx,t.ty, "body")
				c+=1
			end
		end
		
		try+=1
	end
end


function add_eggs(q)
	local c,try=0,0

	-- eggs
	while c<q and try<50 do
		local t=get_random_tile("spawn")
		local list=filter_tiles("egg")
		
		if #list>0 then
			for n in all(list) do
				if not in_range(n.tx,n.ty, t.tx,t.ty, 6) then
					if not in_range(t.tx,t.ty, p_tx,p_ty, 6) then
						set_tile_occupant(t.tx,t.ty, "egg")
						c+=1
					end
				end
			end
		else
			if not in_range(t.tx,t.ty, p_tx,p_ty, 6) then
				set_tile_occupant(t.tx,t.ty, "egg")
				c+=1
			end
		end
		
		try+=1
	end
	
	-- bombs for last level only
	if finale then
		local c,try=0,0
		while c<current_level.bombs and try<50 do
			local t=get_random_tile("spawn")
			local list=filter_tiles("bomb")
			
			if #list>0 then
				for n in all(list) do
					if not in_range(n.tx,n.ty, t.tx,t.ty, 6) then
						if not in_range(t.tx,t.ty, p_tx,p_ty, 6) then
							set_tile_occupant(t.tx,t.ty, "bomb")
							set_tile_attr(t.tx,t.ty, "bomb_st", 0)
							c+=1
						end
					end
				end
			else
				if not in_range(t.tx,t.ty, p_tx,p_ty, 6) then
					set_tile_occupant(t.tx,t.ty, "bomb")
					set_tile_attr(t.tx,t.ty, "bomb_st", 0)
					c+=1
				end
			end
			
			try+=1
		end
	end
end






-- returns true if an object is withing square range of another
-- #in_range(int_needlex,int_needley, int_haystackx,int_haystacky, int_distance)
function in_range(ax,ay, bx,by, rng)
	if ax>=bx-rng and ax<=bx+rng and ay>=by-rng and ay<=by+rng then
		return true
	end
	
	return false
end

function in_hitbox(x,y, ox,oy,ow,oh)
	if x>=ox and x<=ox+ow and y>=oy and y<=oy+oh then
		return true
	end
	
	return false
end




--
-- #tile
-- tile lookup and utilities


-- sets tile occupant type. returns tile objects
-- set_tile_occupant(int_tilex,int_tiley, str_nameofoccupant)
function set_tile_occupant(tx,ty, style)
	level_grid[tx][ty].occupant=style
	return level_grid[tx][ty]
end


function set_tile_attr(tx,ty, key, value)
	level_grid[tx][ty][key]=value
	return level_grid[tx][ty]
end

-- returns random tile object of specified occupant type
-- get_random_tile(str_occupantname)
function get_random_tile(occupant)
	local list=filter_tiles(occupant)
	
	if #list>0 then
		local n=rand(#list)+1
		local t=list[n]
		t.x,t.y,t.cx,t.cy=tile_to_px(t.tx,t.ty)
		return t
	end
	
	return false
end

-- returns tile object based on tile coordinate
-- get_tile(int_tilex,int_tiley)
function get_tile(tx,ty)
	if tx<=map_tilew and tx>0 and ty<=map_tileh and ty>0 then
		local t=level_grid[tx][ty]
		t.x,t.y,t.cx,t.cy=tile_to_px(tx,ty)
		
		return t
	end
end

-- returns tile object found at provided pixel coordinates
-- get_px_tile(int_pixelx,int_pixely)
function get_px_tile(pxx,pxy)
	tx,ty=px_to_tile(pxx,pxy)
	return get_tile(tx,ty)
end


-- returns tilex/tiley pair based on provided pixel coordinates
-- px_to_tile(int_pixelx,int_pixely)
function px_to_tile(pxx,pxy)
	local tx=flr(pxx/16)+1
	local ty=flr(pxy/16)+1
	return tx,ty
end

-- returns pixelx/pixely pair based on provided tile coordinates
-- #tile_to_px(int_tilex,int_tiley)
function tile_to_px(tx,ty)
	local px=(tx*16)-16
	local py=(ty*16)-16
	local cx=px+8
	local cy=py+8
	return px,py,cx,cy
end


-- returns true of the object's hitbox will collide with surrounding tiles
-- #move_is_blocked(int_objpixelx,int_objpixely, int_objpixeldx,int_objpixeldy, tbl_objhitbox)
function move_is_blocked(px,py, dx,dy, hbox)
	local check={}
	
	
	if  px+hbox.x+dx>0 and
		py+hbox.y+dy>0 and
		px+hbox.x+dx+hbox.w<map_wpx and
		py+hbox.y+dy+hbox.h<map_hpx
	then
	
		local xl = px+hbox.x
		local xr = xl+hbox.w
		local yt = py+hbox.y
		local yb = yt+hbox.h
		
		local t1x,t1y=px_to_tile(xl+dx,yt+dy)
		local t2x,t2y=px_to_tile(xr+dx,yt+dy)
		local t3x,t3y=px_to_tile(xl+dx,yb+dy)
		local t4x,t4y=px_to_tile(xr+dx,yb+dy)
	
		add(check, get_tile(t1x,t1y))
		add(check, get_tile(t2x,t2y) )
		add(check, get_tile(t3x,t3y) )
		add(check, get_tile(t4x,t4y) )			
	
		for c in all(check) do
			if c.occupant=="wall" or c.occupant=="sniper" then
					return {t1x,t1y, t2x,t2y, t3x,t3y, t4x,t4y}
			end
		end
	
		return false
	else
		return true
	end
end


-- returns list of tiles of specified occupant + pixel coordinates
-- filter_tiles(str_occupant)
function filter_tiles(occupant)
	local list={}
	
	for tx=1,map_tilew do
		for ty=1,map_tileh do
			local t=level_grid[tx][ty]
			t.x,t.y,t.cx,t.cy=tile_to_px(tx,ty)
			
			if t.occupant==occupant then
				add(list,t)
			end
		end
	end

	return list
end

-- returns array of actors that are either huggers or aliens
function get_aliens()
	local t={}
	for a in all(actors) do
		if a.id==1 or a.id==2 then add(t,a) end
	end
	
	return t
end


-- finds nearest object based on x/y pixel coordinates
-- list objects must have x/y values!!
-- find_nearest(int_pixelx,int_pixely, tbl_items)
function find_nearest(x,y,list)
	local d=9999
	local n=false
	printh("find_nearest")
	printh(#list)
	
	for t in all(list) do
		local far=distance(t.x,t.y, x,y)

		if far<d then
			d=far
			n=t
		end
	end

	return n,d
end





--
-- #map
-- map generation and supports


-- generates level map. populates level_grid.
-- generate_map(int_screenwidth, int_screenheight)
function generate_map(w,h)
	
	-- map settings
	map_w,map_h=w,h
	map_wpx,map_hpx=map_w*128,map_h*128
	map_tilew,map_tileh=map_w*8,map_h*8
	
	-- seed grid with all empty
	-- coordinates are for 16x16px blocks; 8 per screen
	level_grid={} -- x/y indexes; this has tile attributes
	level_list={} -- node indexes for pathfinding
	local snipers={}

	for x=1,map_tilew do
		level_grid[x]={}
		
		for y=1,map_tileh do
			level_grid[x][y]={
				tx=x,ty=y, --tile x/y
				n=0,f=0,g=0,h=0,p=0,status=0, --pathfinding vars
				occupant="empty",
				w=true --is space walkable? true=open,false=blocked
			}
		end
	end
	
	
	
	-- create map from sprites for each screen
	for mx=1,map_w do
		for my=1,map_h do
			create_screen(mx,my, read_spritelayout(flr(rnd(14))+1,0))
		end
	end

	-- add start screen, replace a random screen
	if finale then
		queen_x=map_w
		queen_y=rand(map_h)+1
		
		create_screen(1,rand(map_h)+1, read_spritelayout(0,0)) --player start in first column, random row
		create_screen(queen_x,queen_y, read_spritelayout(0,0)) --queen in last column, random row
	else
		create_screen(rand(map_w)+1,rand(map_h)+1, read_spritelayout(0,0))	
	end
	
	
	-- make a node list for pathfinding
	-- this needs to come after map population unless you populate within initial creation above
	
	--
	local n=1
	
	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=level_grid[x][y]
			
			level_list[n]=plot
			plot.n=n
			n+=1
			
			-- add sniper aliens in places where there is dark green
			if plot.occupant=="sniper" then
				add(snipers,plot)
			end
		end
	end
	
	
	-- add random aliens, not too close to player
	local aliens_added=0
	while aliens_added<current_level.aliens do
		local t=get_random_tile("empty")
		
		if not in_range(t.tx,t.ty, p_tx,p_ty, 8) then
			add_alien(t.tx,t.ty)
			aliens_added+=1
		end
	end

	-- add snipers to level
	if #snipers>0 then
		for n=0,current_level.snipers do
			local t=rnd_table(snipers)
			del(snipers,t)

			if t.tx+1>map_tilew then
				east={occupant="wall"}
			else
				east=level_grid[t.tx+1][t.ty]
			end

			if t.tx-1<1 then
				west={occupant="wall"}
			else
				west=level_grid[t.tx-1][t.ty]
			end

			if east.occupant!="wall" and west.occupant!="wall" then
				-- not boxed in, so pick a direction
				if rnd()<.5 then t.flip=true end
			else
				-- blocked on at least one side
				if east.occupant=="wall" then 
					if west.occupant!="wall" then
						t.flip=true 
					end
				end
			end

			add_sniper(t.tx,t.ty,t.flip)
		end
		
		-- turn left over sniper slots into bushes
		for t in all(snipers) do
			level_grid[t.tx][t.ty].occupant="wall"
			level_grid[t.tx][t.ty].spr=rnd_table(bush_sprites)
		end
	end
end


-- creates map plots based on a 8x8 sprite
bush_sprites={1,3,5}
function create_screen(mx,my, spritemap)
	for spx=0,7 do
		for spy=0,7 do
			local tilex=spx+1 + (mx-1)*8
			local tiley=spy+1 + (my-1)*8
			local pxc=spritemap[spx+1][spy+1]
			local tile={occupant="empty",w=true}
			
			--bush/wall
			if pxc==11 or pxc==3 then 
				tile.occupant="wall"
				tile.spr=rnd_table(bush_sprites)
				tile.w=false
			end
			
			-- rock wall
			if pxc==6 then 
				tile.occupant="wall"
				tile.spr=rnd_table({76,78})
				tile.w=false
			end
			
			-- sniper/bush
			if pxc==3 and current_level.snipers>0 then 
				tile.occupant="sniper"
				tile.spr=rnd_table(bush_sprites)
				tile.w=false
			end
			
			-- transport computer
			if pxc==12 then 
				tile.occupant="transport"
			end
			
			-- egg spawner
			if pxc==15 then 
				tile.occupant="spawn"
			end
			
			-- bomb detonator
			if pxc==14 then 
				tile.occupant="detonator"
			end
			
			-- queen
			if pxc==9 then 
				tile.occupant="queen"
			end
			
			

			-- player start; doesn't change tile attrs
			if pxc==8 then
				p_x,p_y=tile_to_px(tilex,tiley)
				p_cx=p_x+8
				p_cy=p_y+8
				p_tx,p_ty=tilex,tiley
			end

			
			for k,v in pairs(tile) do
				level_grid[tilex][tiley][k] = v
			end

		end
	end	
end


-- reads 8x8 sprite in spritesheet and returns x/y indexed table with colors
function read_spritelayout(sprx,spry)
	-- offset within spritesheet. layout sprites start at tile 0,64
	local ox=sprx*8
	local oy=112+(spry*8)
	local set={}
	
	for sx=0,7 do
		local pxx=sx+1
		set[pxx]={}
		
		for sy=0,7 do
			local pxy=sy+1
			set[pxx][pxy]=sget(sx+ox,sy+oy)
		end
	end

	return set
end

-- returns true if pixel coordinate is inbounds of entire map
-- px_inbounds(int_pixelx,int_pixely) 
function px_inbounds(pxx,pxy) 
	if pxx<map_wpx and pxx>1 and pxy<map_hpx and pxy>1 then
		return true
	end
	
	return false
	
end



-- #minimap

minimap_txt_scroll=100

function minimap_dot(x,y,c)
	x1=((x-1)*2)+minimap_x+7
	y1=((y-1)*2)+minimap_y+7
	x2=((x-1)*2)+2+minimap_x+7
	y2=((y-1)*2)+2+minimap_y+7

	rectfill(x1,y1, x2,y2, c)
end

function generate_minimap() 
	minimap={}
	radar_dots={}

	minimap_txt_bio=0
	minimap_txt_eggs=0
	minimap_radar=111
	minimap_x=0
	minimap_y=0
	
	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=level_grid[x][y]

			if plot.occupant=="body" or plot.occupant=="egg"  then
				add(minimap, {x=x,y=y,c=11})
				minimap_txt_bio+=1
				
				if plot.occupant=="egg" then minimap_txt_eggs+=1 end
			end
			
			if plot.occupant=="transport" then add(minimap, {x=x,y=y,c=12}) end
			
			if plot.occupant=="bomb" then add(minimap, {x=x,y=y,c=14}) end
		end
	end
	
	for a in all(get_aliens()) do
		add(minimap, {x=a.tx,y=a.ty,c=11})
		minimap_txt_bio+=1
	end

	local t=get_random_tile("egg")
	if not t then
		t=get_random_tile("transport")
	end
	
	minimap_nav=atan2(t.x-p_cx, t.y-p_cy)
	
	
	add(minimap, {x=p_tx,y=p_ty,c=10}) --player position
end


function minimap_update()

	if map_w>4 or map_h>4 then
		if btnl	then minimap_x+=1 end
		if btnr	then minimap_x-=1 end
		if btnu	then minimap_y+=1 end
		if btnd	then minimap_y-=1 end
	end

	minimap_radar-=.65
	
	if flr(minimap_radar)==78 then 
		radar_dots={}

		for a in all(get_aliens()) do
			if in_range(a.cx,a.cy, p_cx,p_cy, 64) then
				local rx,ry=get_line(106,95,7, atan2(a.cx-p_cx, a.cy-p_cy))
				add(radar_dots,{x=rx,y=ry})
			else
				if in_range(a.cx, a.cy, p_cx,p_cy, 128) then
					local rx,ry=get_line(106,95,15, atan2(a.cx-p_cx, a.cy-p_cy))
					add(radar_dots,{x=rx,y=ry})
				end
			end
		end
	end
	
	if minimap_radar<0 then minimap_radar=111 end

end

function minimap_draw()
	rectfill(0,0, 127,116, 0) --base grey
	
	rectfill(minimap_x+6,minimap_y+6, (map_tilew*2)+minimap_x+8,(map_tileh*2)+minimap_y+8, 3) --map bg
	rect(minimap_x+6,minimap_y+6, (map_tilew*2)+minimap_x+8,(map_tileh*2)+minimap_y+8, 11) --map border
	
	-- draw dots	
	for mm in all(minimap) do
		minimap_dot(mm.x,mm.y,mm.c)
	end
	
	
	rectfill(0,0, 127,5, 0) --bg cover
	rectfill(0,0, 3,113, 0) --bg cover
	rectfill(0,89, 127,116, 0) --bg cover
	rectfill(88,0, 127,116, 0) --bg cover
	

	rect(2,2, 125,114, 12) -- border frame
	rect(4,4, 87,86, 12) --map frame
	
	rect(89,4, 123,76, 12) --sidebar border
	
	rect(4,88, 87,112, 12) -- info border
	
	--rectfill(80,75, 123,112, 1)
	rectfill(89,78, 123,112, 1)
	
	local item="none"
	if p_st==2 then item="pulse rifle" end
	if p_st==3 then item="alien bait" end

	print("eggs:"..minimap_txt_eggs.."\n\ncargo:\n15"..eggs_collected.."\n\nnav:\n"..minimap_nav, 93, 9, 11)
	print("planet:"..current_level.name.."\n\nitem:"..item, 8,92, 11)
	
	
	
	circ(106,95,7,12)
	circ(106,95,14,12)
	pset(106,95,12)
	
	for d in all (radar_dots) do circfill(d.x,d.y,1,7) end
	
	if minimap_radar>78 then
		line(90,minimap_radar, 122,minimap_radar, 7)
	end
	
	
	
	rect(89,78, 123,112, 12) --radar border
	
end



-- #ticker
ticker_scrolling=false
ticker_text_now=""

function add_ticker_text(txt,clear)
	local list=split(txt)
	
	if clear then ticker_text={} ticker_scrolling=false end
	
	for t in all(list) do add(ticker_text,t) end
	
	if clear then ticker_next() end
end

function ticker_next()
	if #ticker_text>0 and not ticker_scrolling then
		minimap_txt_scroll=105
		ticker_text_now=ticker_text[1]
		del(ticker_text, ticker_text_now)
		ticker_scrolling=true
	end
end

function ticker_update()
	if ticker_scrolling then
		minimap_txt_scroll-=.8
			
		if minimap_txt_scroll<=-120 then ticker_scrolling=false end
	end
		
	ticker_next()

end

function ticker_common()
	local list=split("find alien eggs before they hatch;bait distracts adult aliens;the pulse rifle auto-aims;the pulse rifle has one shot;scan shows "..current_level.eggs.." eggs remaining;use \142 to scan area;camo aliens cannot be killed;camo alien attack paralyzes;scanner will recharge over time;scanning uses battery power;bait only lasts a few moments;newborn aliens search for bodies;use your items wisely;aliens will attack if you get too close")
	add_ticker_text(rnd_table(list))
end


function ticker_draw()
	rectfill(0,117, 127,127, 1) --text strip
	
	if ticker_scrolling then
		print(ticker_text_now, minimap_txt_scroll,120, 12)
	end

	-- chrome
	rectfill(90,117, 127,127, 5)
	rect(0,117, 90,127,5) 


	-- battery
	if minimap_battery>0 then pal(11,8) end
	spr(25, 94,120)
	pal()

	 --egg count
	spr(26, 118,119)
	print(current_level.eggs, 113,120, 6)
end


function make_blood()
	blood_t=0
	
	if #blood<45 then
		for n=0,15 do
			add(blood,{random(34,94),random(34,94),random(5,9)})
		end
	
		for n=0,18 do
			add(blood,{random(14,114),random(14,115),random(1,3)})
		end
	end
end



-- #game
-- current_level set in nextlevel_init()
function game_init()
	--current_level=levels[levelid]
	printh("level "..level_id)
	printh("eggs "..current_level.eggs)
	printh("bodies "..current_level.bodies)

	blood={}
	ticker_text = {}
	bullets     = {}
	actors      = {}
	
	minimap_x,minimap_y=4,4
	minimap_battery = 0
	map_mode        = false
	egg_timer       = sec(current_level.eggtimer)
	--egg_count       = 0
	
	
	p_init()
	generate_map(current_level.w,current_level.h)
	add_bodies(current_level.bodies)
	add_eggs(current_level.eggs)

	if finale then
		add_ticker_text("arrival on "..current_level.name..";scan shows "..current_level.eggs.." eggs in range;find eggs before they hatch",true)	
	else
		add_ticker_text("arrival on "..current_level.name..";find and arm 3 bombs;find detonator",true)
	end
	

	if level_id==1 then
		add_ticker_text("press \142 to scan area;press \151 to use item")	
	end
	
	
	
	--music(0)
	cart(game_update,game_draw)
end


function game_update()
	if p_dead then
		if btnxp or btnzp then _init() end
		
		if gt>=sec(12) then 
			add_ticker_text("game over;press \142 to continue")
			gt=0
		end
		
	else	
		for a in all(actors) do a.update(a) end

		
		-- #eggtimer
		if current_level.eggs>0 then
			egg_timer-=1
			if egg_timer<=0 then
				local t=get_random_tile("egg")
				
				if t then
					-- @sound hatch alert
					add_ticker_text("new life form detected",true)
					
					current_level.eggs-=1
					if current_level.eggs<=0 then
						add_ticker_text("no more eggs detected;return to transport beacon")
					else
						add_ticker_text(current_level.eggs.." eggs remaining")
					end
					
					add_hugger(t.tx,t.ty)
					set_tile_occupant(t.tx,t.ty,"empty")
					
				end
				
				egg_timer=current_level.eggtimer	
			end
		end
		
		
		if map_mode then
			minimap_update()
		end
		
		bullet_update()
		p_update()
		
		if gt>=sec(20) then -- toss in generic messages every 20 seconds
			--if eggs_collected>=20 then
				--add_ticker_text("mission accomplished;return to transport beacon",true)
			--else
				if current_level.eggs<=0 then
					-- @sound no egg alert
					add_ticker_text("no more eggs detected;return to transport beacon")
				else
					ticker_common()
				end
			--end
			
			gt=0
		end
	end
	
	ticker_update()
	
end


function game_draw()
	camera(p_cx-64, p_cy-64)
	
	if current_level.colors then
		swap_bright=current_level.colors[1]
		swap_dark=current_level.colors[2]
	end
	
	
	--grass map background
	for bgx=0,map_w-1 do
		for bgy=0,map_h-1 do
			map(0,0, bgx*127,bgy*127, 16,16)
		end
	end
	
	-- level screens
	palt(2,true)
	palt(0,false)
	
	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=level_grid[x][y]
			local px,py=tile_to_px(x,y)
			
			if plot.occupant=="body" then
				spr(9,px,py+3,2,1)
			end
			
			if plot.occupant=="egg" then
				spr(14,px,py,2,2)
			end
			
			if plot.occupant=="transport" then
				if p_transport then
					pal(13,8)
					pal(12,8)
				end
			
				spr(12,px,py,2,2)
			end
			
			if plot.occupant=="bomb" then
				if plot.bomb_st==1 then pal(11,9) end --orange, hover arming
				if plot.bomb_st==2 then pal(11,8) end --red, armed
				spr(110, px, py, 2,2)
			end
			
			if plot.occupant=="detonator" then
				if plot.detonator_st==1 then pal(11,9) end --orange, hover arming
				if plot.detonator_st==2 then pal(11,8) end --red, armed
				spr(108, px, py, 2,2)
			end
			
			
			-- only things that need color swapped based on level colors go below here
			--
			if swap_bright then
				pal(11,swap_bright)
				pal(3,swap_dark)
			end
			
			if plot.occupant=="wall" then
				spr(plot.spr, px, py, 2,2)
			end
			
			if plot.occupant=="sniper" then
				spr(42, px, py, 2,2, plot.flip)
			end
			
			
			
			
			
		end
	end
	

	-- level borders
	-- sides
	for m=0,map_tileh do
		spr(3, -15, (16*m), 2,2)
		spr(3, map_wpx, (16*m), 2,2)
	end
	
	--bun
	for m=-1,map_tilew do
		spr(3, (16*m), -15, 2,2)
		spr(3, (16*m),map_hpx, 2,2)
	end
	pal()
	
	
	
	palt(2,true)
	palt(0,false)
	-- non-player actors; aliens, items
	for a in all(actors) do
		a.draw(a)
	end
	
	bullet_draw()
	
	-- player
	if p_freeze>0 then pal(10,13) end
	p_draw()
	
	pal()
	
	
	
	-- minimap, user-controlled
	if map_mode then
		camera(0,0)
		minimap_draw()
	end
	
	
	-- ticker
	camera(0,0)
	ticker_draw()
	
	if p_dead then
		for b in all(blood) do
			circfill(b[1],b[2],b[3], 8)
		end
		
		if blood_t>sec(3) then
			make_blood()
		end
		blood_t+=1
	end
	
end




-- #scenes


-- #nextlevel
function nextlevel_init()
	level_id+=1
	daysout+=1
	p_transport=false
	
	local colors={{3,4},{11,9},{11,4},{15,14}}
	
	-- after level 5, maps are same always big, just new layout
	if level_id>#levels then
		local abc=split("a;b;c;d;e;f;g;h;i;j;k;l;m;n;o;p;q;r;s;t;u;w;v;y;z")
		local name=rnd_table(abc)..rnd_table(abc).."-"..random(75,850)

		current_level={name=name,w=5,h=6,bodies=10,eggs=5,eggtimer=45,aliens=6,snipers=6,colors=rnd_table(colors)}
	else
		current_level=levels[level_id]
	end
	
	
	if finale then
		current_level={name="pco 8",w=6,h=5,bombs=3,bodies=10,eggs=0,eggtimer=25,aliens=0,snipers=6,colors=rnd_table(colors)}
	end
	
	local scanlinev=78
	local scanlinev_dir=1
	local scanlineh=89
	local scanlineh_dir=1
	local t=31
	local nums={}
	
	function nextlevel_update()
		if btnzp or btnxp then
			game_init()
		end
		
		if t>30 then
			nums={}
			for n=0,8 do add(nums,rnd()) end
			t=0
		end
		
		t+=1
	end 

	function nextlevel_draw()
		rect(0,0, 127,127, 12) -- border frame
		rect(2,2, 87,93, 12) -- map frame
		
		
		circ(128,115, 30, 12)
		circ(128,110, 20, 12)
		
		line(89,scanlinev, 125,scanlinev, 7)
		line(scanlineh,80, scanlineh,125, 7)
		
		rect(89,2, 125,78, 12) --sidebar border
		rect(89,80, 125,125, 12) --sidebar border
		rect(88,79, 126,126, 0)
		
		rect(2,95, 87,125, 12) -- info border
		
		local numy=6
		for x in all(nums) do
			print(x, 93,numy, 11)
			numy+=8
		end
		
		print("next planet: "..current_level.name, 7,8, 10)
		
		
		if finale then
			-- last level directions
			spr(110, 5,18, 2,2)
			print("find 3 bombs\nwait to arm", 24,18, 7)
				
			spr(108, 5,41, 2,2)
			print("find detonator\nto start timer",24,41, 7)
				
			spr(12, 5,60, 2,2)
			print("wait on beacon\nto escape",24,61, 7)
		else
			-- normal directions
			spr(14, 5,18, 2,2)
			print("find alien eggs\n"..current_level.eggs.." detected", 24,22, 7)

			spr(12, 5,41, 2,2)
			print("stand on beacon\nwhen done",24,42, 7)
		end
		
		
		
		print("press \142 to start",7,85, 7)
		print("cargo: "..eggs_collected.."/20",7,100,7)
		
		local iconx=5
		local icony=107
		
		for n=1,20 do
			
			if n<=eggs_collected then pal(13,10) else pal(13,5) end
			spr(26,iconx,icony,1,1)
			iconx+=8
			
			if n==10 then
				iconx=5
				icony+=8
			end
		end
		pal()
		
		if flr(scanlinev)==78 then scanlinev_dir=1 end
		if flr(scanlinev)==125 then scanlinev_dir=-1 end
		if flr(scanlineh)==89 then scanlineh_dir=1 end
		if flr(scanlineh)==125 then scanlineh_dir=-1 end
		
		scanlinev+=.33*scanlinev_dir
		scanlineh+=.33*scanlineh_dir

	end
	
	
	cart(nextlevel_update,nextlevel_draw)
end



-- #victory
function victory_init()
	cart(victory_update,victory_draw)
end

function victory_update()
	if btnxp or btnzp then
		title_init()
	end
end 

function victory_draw()
	print("you won",0,0,7)
end



-- #story
story_init=function() --must be var for use in attract modes
	local sx=1
	local lspr=14

	function story_update()
		if (btnxp or btnzp) or (gt>sec(15)) then
			abstract=help_init
			title_init()
		end

		if gt>sec(4) then
			lspr=160
			if sx>=90 then lspr=128	end
			
			sx=min(sx+.5,130)
		end
	end 

	function story_draw()
		print("dylan burke is finishing the\njob his father failed to finish\non lv-426.\n\nyou know what that means and you\nmust stop him.\n\nthanks to some old friends\nstill within the company, you\nknow where he's heading.\n\nyou must travel to each planet\nand collect alien eggs before\nburke can get to them, then\ndestroy them all.", 1,5, 6)
		palt(2,true)
		spr(lspr,sx,105,2,2)
		if sx<90 then spr(9,90,110,2,1) end
		pal()
	end


	cart(story_update,story_draw)
end



-- #help
help_init=function(nextinit) --must be var for use in attract modes
	function help_update()
		if (btnxp or btnzp) or (gt>sec(15)) then
			abstract=story_init
			nextinit()
		end
	end
	
	function help_draw()
		-- left side
		palt(2,true)
		spr(14, 1,2, 2,2)
		print("find and collect alien\neggs before they hatch", 22,6, 7)

		spr(9, 1,25, 2,1)
		print("search bodies to\nequip weapon",22, 24,7)
		
		spr(12, 1,41, 2,2)
		print("stand on beacon to call\ndropship when done",22,42, 7)
		
		print("press \142 for map scan\n\npress \151 to use weapon", 22,62, 7)
		

		-- right side		
		print("avoid aliens", 22,88, 8)
		
		spr(160, 22,94, 2,2)    
		spr(128, 42,97, 2,2)
		spr(42, 65,97, 2,2)
		pal()
	end
	
	cart(help_update, help_draw)
end




-- #finale
function finale_init()
	finale=true
	
	function finale_story()
		print("story about having all the eggs", 1,1, 7)
		
		if btnzp or btnxp then
			nextlevel_init()
		end
	end
	
	
	cart(ef, finale_story)
end


-- #title
abstract=story_init
function title_init()
	finale=true
	nextinit=title_init
	level_id=0
	eggs_collected=20 --total eggs collected by player for game session
	daysout=0
	level_grid={}
	level_list={}
	blood={}
	actors={}
	levels={}
	
	-- #levels - define levels
	-- w/h=screen size; eggtimer=seconds to hatch; colors=array of primary,secondary
	add(levels,{name="jl78",w=2,h=3,bombs=0,bodies=2,eggs=1,eggtimer=30,aliens=0,snipers=0,colors={11,3}})
	add(levels,{name="col-b",w=3,h=4,bombs=0,bodies=3,eggs=2,eggtimer=30,aliens=2,snipers=0,colors={11,4}})
	add(levels,{name="mf 2018",w=4,h=4,bombs=0,bodies=4,eggs=3,eggtimer=40,aliens=3,snipers=2,colors={9,4}})
	add(levels,{name="roxi 9",w=5,h=4,bombs=0,bodies=5,eggs=4,eggtimer=45,aliens=4,snipers=3,colors={11,4}})
	add(levels,{name="pv-418",w=6,h=6,bombs=0,bodies=7,eggs=5,eggtimer=50,aliens=6,snipers=6,colors={14,2}})
	--add(levels,{name="mf2018",w=3,h=7,bodies=10,eggs=6,eggtimer=35,aliens=5,snipers=5,colors={11,3}})
	--add(levels,{name="p-co 8",w=6,h=4,bodies=6,eggs=4,eggtimer=45,aliens=5,snipers=7,colors={14,2}})
	
	
	
	cart(title_update,title_draw)
end

function title_update()
	if btnxp or btnzp then
		--help_init(nextlevel_init)
		nextlevel_init()	
	end
	
	if gt>sec(7) then abstract() end
end 

function title_draw()
	print("alien harvest\n\npres \142 to start",0,0,7)
end




-- #intro
function intro_init()
	local textc=0
	local wait=sec(10)
	
	function intro_draw()
		center_text("alien harvest "..ver,4,textc)
		center_text("(c)2017 brian vaughn",12,textc)
		
		center_text("design+code",25,textc)
		center_text("brian vaughn",33,textc)
		center_text("@morningtoast",41,textc)
		
		center_text("music+sound",55,textc)
		center_text("brian follick",63,textc)
		center_text("@gnarcade_vgm",71,textc)
		
		center_text("art+animation",84,textc)
		center_text("pinecone",92,textc)
		center_text("@pinecone",100,textc)
		
		center_text("original sprites",113,textc)
		center_text("http://bit.ly/h37fh",121,textc)
	
		
		if gt>8 then textc=5 end
		if gt>15 then textc=6 end
		if gt>30 then textc=7 end
		
		if gt>wait-60 then textc=6 end
		if gt>wait-60+15 then textc=5 end
		if gt>wait-60+30 then textc=0 end
		
		if gt>wait then 
			title_init() 
		end
		
		gt+=1
	end
	
	cart(ef,intro_draw)
end






-- #loop
function _init()
	printh("\n\n=====new load================================================\n\n")
	
	title_init()
	--story_init()
	--nextlevel_init()
end

function _update60()
	btnl=btn(0)
	btnr=btn(1)
	btnu=btn(2)
	btnd=btn(3)
	btnzp=btnp(4)
	btnxp=btnp(5)
	
	cart_update()

	gt+=1
end

function _draw()
	cls()
	cart_draw()

	
	-- debugging
	camera(0,0)
	local dbmem=flr((stat(0)/1024)*100).."%m / "..flr(((flr(stat(1)*100))/200)*100).."%c"
	print(dbmem,70,0,8)
	if debug then print(debug,1,1,7) end
end








--
-- #utility functions and libraries
--

function chg_st(o,ns) o.t=0 o.st=ns end
function rand(x) return flr(rnd(x)) end
function sec(f) return flr(f*60) end -- set fps here if you need

-- debug tools
debug=false
function debug_hitbox(x,y,hb) 
	rect(x+hb.x,y+hb.y, x+hb.x+hb.w,y+hb.y+hb.h, 11)
end

function highlight_tile(pxx,pxy,c)
	rect(pxx,pxy, pxx+15,pxy+15, c)
end


-- string splitter, returns array
-- split(string, delimter)
function split(s,dc)
	dc=dc or ";"
	local a={}
	local ns=""
	s=s..";"
	
	while #s>0 do
		local d=sub(s,1,1)
		if d==dc then
			add(a,ns)
			ns=""
		else
			ns=ns..d
		end
	
		s=sub(s,2)
	end
	
	return a
end	



-- center string on screen, assumes full viewport
function center_text(s,y,c) print(s,64-(#s*2),y,c) end



-- checks to see if value is in a table
-- in_table(needle, haystack)
function in_table(element, tbl)
  for _, value in pairs(tbl) do
    if value == element then
      return true
    end
  end
  return false
end

-- returns random pos value from provided table
function rnd_table(t)
	local r=flr(rnd(#t))+1
	return(t[r])
end
	
	
	
-- get dx/dy calculations for movement
function dir_calc(angle,speed)
	local dx=cos(angle)*speed
	local dy=sin(angle)*speed
	
	return dx,dy
end

-- returns x/y of point as measured from provided x/y with length and angle	
function get_line(x,y,dist,dir)
	fx = flr(cos(dir)*dist+x)
	fy = flr(sin(dir)*dist+y)
	
	return fx,fy
end


-- returns distance between two points
function distance(ox,oy, px,py)
  local a = abs(ox-px)/16
  local b = abs(oy-py)/16
  return sqrt(a^2+b^2)*16
end


-- get a random number between min and max
function random(min,max)
	n=flr(rnd(max-min))+min
	return n
end

-- round number to the nearest whole
function round(num, idp)
  local mult = 10^(idp or 0)
  return flr(num * mult + 0.5) / mult
end

------------------
-- #astar algorithm --
------------------
function find_path(start_index,target_index)
	local path={} -- list of node indexes that create path to goal, use to lookup tiles in level_list
	
	-- reset the level data
	for v in all(level_list) do
		v.p=0
		v.status=0
	end

	local start=level_grid[start_index.x][start_index.y]
	local target=level_grid[target_index.x][target_index.y]
	local open={start.n}
	local closed={}
	
	start.g=0
	start.h=abs(target.x-start.x)+abs(target.y-start.y)
	start.status=1
	
	
	
	-- while there are still nodes to check and target not found
	while #open>0 do
		local current=level_list[open[1]]
		
		for n in all(open) do
			if level_list[n].g+level_list[n].h<current.g+current.h then
				current=level_list[n]
			end
		end 
	
		add(closed,current.n)
		del(open,current.n)
		current.status=2
	
	
		-- neighbor check
		-- only look n/e/s/w ; no diagonals
		nchecks={
	        {x=current.tx, y=current.ty-1},
	        {x=current.tx, y=current.ty+1},
	        {x=current.tx+1, y=current.ty},
	        {x=current.tx-1, y=current.ty},        
	    }

		-- ignore diagonal neighbors
		for cxy in all(nchecks) do
			
			if cxy.x>=1 and cxy.x<=map_tilew and cxy.y>=1 and cxy.y<=map_tileh then
				local neighbor=level_grid[cxy.x][cxy.y]
				
				if neighbor.n==target.n then
					target.p=current.n
					add(closed,target.n)
					
					-- construct the final path
					path={}
					local temp={}
					local n=closed[#closed]
					
					while n!=start.n do
						add(temp,n)
						n=level_list[n].p
					end
					
					for i=#temp,1,-1 do
						add(path,temp[i])
					end
					
					return path
				end
				
				-- only if neighbor is open to explore (walkable)
				if neighbor.w then
					-- if neighbor not in open or closed list
					if neighbor.status==0 then
						neighbor.p=current.n
						neighbor.g=current.g+1
						neighbor.h=abs(target.x-neighbor.x)+abs(target.y-neighbor.y)
						neighbor.status=1
						add(open,neighbor.n)
						-- if neighbor in open list
					elseif neighbor.status==1 then
						if current.g+1<neighbor.g then
							neighbor.p=current.n
							neighbor.g=current.g+1
						end
					end
				end
			end
		end
	end

	return path
end




__gfx__
0000000000000000000000000000000000000000000000000b0000000000000000000000a0a0000aaa2222222222262200000000000c00000000000000000000
000000000000000b00000000000000000000000000300000bbb000000000000000000000a0a0aa0000222222222226220000000000c0c0000000000000000000
000000000000300b00000000000000b0000000000033000bb0b000000000000030000000aa0aaaaa02222222222aaa22000000000ccc00000000000000000000
000000000000300b000300b0000000bb00003300003330bb0bb00030003000303030030000000aaaa0aaa00a22aaaaa200000ddd00c000000000000000000000
0000000000b0030bb00300b0000000bbb0033000003330bb0bb03330000000000000000020aa0aa00aaaaaaa220aa0a2000cc0ddd00000000000000dd0000000
0000000000b0030bb0330bb0003330b0bb033000000000bbbb03303000000000000000002aa000aaa022222222aaaa2200cccc0d00000000000000dd0d000000
0000000000bb030bb0330bb0000330bb0b00000000bbb00bb0330330000000000000000020a02222aa022222222aa22200c0ccc00d00000000000dddd0d00000
00000000000b030bbb00bb000000300bb0bb00000bbbbbbbb00033000030030000000000220a02222aa022222222622200c0cccc0000000000b0dddd0d0d0000
00000000000bb00bbb00bb0000000bbb0bbbb000bb0000bbbbb030303030300300030000bbbbbbb00000000022226222000c0ccccccc00000000ddddd00d00b0
00000000000bb00bbb0bbb000000bb0bb0bbb0000bbbbbb0b0bb03300000000000000000b00000bb000dd0002226222200000000000000000b00dddd0d0d0000
000000003000bb0bbbb0bb000000b0bbb00bbb0000bbbb00bb0bb0300000000000000000b0b0b0bb00dd0d002226222200000d0ddd00000000b00dd0d0d000b0
000000000300bb0bbbb0b000000b0bbb03300b00000000b0bbb0b0000000000000000000b00000bb0dddd0d02226222200000000000000000b0b00dd0d000000
000000000330bbb0bbb00030000bbb0003300000000bb0bb0bb0b0000000000000030000bbbbbbb00ddd0dd02262222200d0ddddddddd00000b000000000b0b0
0000000000330bb0bbbb033000bb000000300000000b0bb000bbb0000000000003030030000000000dddd0d03262232200000000000000000000b000000b0000
0000000000000bbb0bbb00000000000000000000000bbb00000bb00003000030030303000000000000dddd00326232230c0cc0ccc0cc0c00000000b0b0000000
000000000000000000000000000000000000000000bbb000000b0000000000000000000000000000000000002333323200000000000000000000000000000000
2222222aa22222220000000000000000000000000000000000000000000000000000000000000000000003333333000000000000000000000000000000000000
222222aaaa2222220000000000000000000000000000000000000000000000000000000000000000000333333333330000000000000000000000000000000000
222222aa002222220000000000000000000000000000000000000000000000000000000000000000003333333300333000000000000000000000000000000000
22222a00aa2222220000000000000000000000000000000000000000000000000000000000000000033330000330033300000000000000000000000000000000
2222aaaa00a222220000000000000000000000000000000000000000000000000000000000000000033300bbb033333300000555550000000000000000000000
222aa0aaaaaa2222000000000000000000000000000000000000000000000000000000000000000033000b000b03330300005555555000000000000000000000
222aa0aaaa0a222200000000000000000000000000000000000000000000000000000000000000003300b0330b0000300005005000000000000aaa0000000000
222a000aaa00a2220000000000000000000000000000000000000000000000000000000000000000000b03330bb00000005505050000505000aaaaa00a0a0000
222aa0a0a0a0a2220000000000000000000000000000000000000000000000000000000000000000000b0330000033300050500005005050000aa0a000a0a000
2222a0aa0aa222220000000000000000000000000000000000000000000000000000000000000000000bb03330033033000000000005050000aaaa0aa8a0a000
222220aa0aa22222000000000000000000000000000000000000000000000000000000000000000000b00000333333030000000005555050000aa0008a0a8000
22222aa222aa2222000000000000000000000000000000000000000000000000000000000000000000bb0bb00000030005000005500005550008800a000a0800
2222aa2222aa2222000000000000000000000000000000000000000000000000000000000000000000bbbb0bb00000005050bb050b05a0bb0000a00880a0a000
2222aa22222aa2220000000000000000000000000000000000000000000000000000000000000000b00bb00b0000000050b5005b0b505b5508880a8888088880
22222aa2222222220000000000000000000000000000000000000000000000000000000000000000bb0000bb0bbb0000bb00b500b50b50500008808000800000
222222222222222200000000000000000000000000000000000000000000000000000000000000000bb00bbbbb0bb000000b00bb00bbb00b0000000000000000
222aa222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22aaaa22222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22aa0022222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000006660500000000000000000000000
2a00aa2aaaaa22220000000000000000000000000000000000000000000000000000000000000000000000000000000000066660550000000000000000000000
aa000aaa00aaaaa20000000000000000000000000000000000000000000000000000000000000000000000000000000000066060555000000000000000000000
aaa0aaaaaaaaaaa20000000000000000000000000000000000000000000000000000000000000000000000000000000000066660555000000000000000000000
22aaa000aa2222220000000000000000000000000000000000000000000000000000000000000000000000000000000000060060055500000000006660550000
22000a22a22222220000000000000000000000000000000000000000000000000000000000000000000000000000000000666666055500000000666660555000
220aaa22222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000600606055500000006666660555000
22a0a0a2222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000666666055550000006666660555500
22aa00aa222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000600066055550000006666660555500
22aa222a222222220000000000000000000000000000000000000000000000000000000000000000000000000000000006666066005555000066666660055500
2aa2222aa22222220000000000000000000000000000000000000000000000000000000000000000000000000000000006606606605555000066666666055550
aa02222aaa2222220000000000000000000000000000000000000000000000000000000000000000000000000000000006666666605555000066666666055550
0aa22222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000006666666605555000006666666055500
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000066666605550000000006666050000
222aa222222222a200000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000c000000000cc00000000
22aaaa2222222a22000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0ccccc0cc000000000cccc0000000
22aa00222222a222000000000000000000000000000000000000000000000000000000000000000000000000000000000ccc00000ccc000000000c1cc0000000
2a00aa22222a22220000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000c000000000cc1ccc000000
aa0000a222a22222000000000000000000000000000000000000000000000000000000000000000000000000000000000c000101000c00000000c1cccc000000
aaa0aa0aaa222222000000000000000000000000000000000000000000000000000000000000000000000000000000000c0010c0100c0000000cc1ccccc00000
20aa00000a222222000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c0c000c0000000c11111cc00000
200aaaaaa2222222000000000000000000000000000000000000000000000000000000000000000000000000000000000c0010c0100c00000000cccccc000000
2000000aa2222222000000000000000000000000000000000000000000000000000000000000000000000000000000000c000101000c00000b000c1cc0000000
20aa00a0022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000c00000b0000c1cc0000b00
20a00a2002222222000000000000000000000000000000000000000000000000000000000000000000000000000000000ccc00000ccc00000b000c1cc000b000
20a2a22a02222222000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0ccccc0cc00000000c111cc000000
2a02222aa222222200000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000c0000b000000b00b00b0
aa02222aaa222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0b0000b00000
2aa22222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222ddddd2220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222ddddddd220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222222d2000dd0d20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222ddd0dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222d2dd00d2d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222222dd0dd222d20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222d2ddd0dd222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222ddddd0dd22220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d22dddd000dddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2dd0d0dd000d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d22dd000dd2222d20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2dd22dd22dd222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222d2222d222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222dd22dd222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222222222ddd22220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222222f2222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222ff2f2ff222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222f222f22222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222ff222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222ffff222ff22220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222ffffffff0f2220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222fffffffff22220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222fff00ff0f2220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222f2f22f220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222f2f22f2220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb0000bb0bb00bbb0000fffb0000000000000fbbbbb0000000b00000000bfbfb00000bbb00000000b000fffb0000000000000f60000000000000000000000000
b000000bbff00fff0000ffb00000000000000ffb0000000000f3ffff0003fbfb00ff00000b0000b03000f3bb00bbbbb06ffffff00bbfbbb0bbb3ff6000000000
00000000bff00000b300bb00000000000fff00000000000000fbbbbb000bfbfb00fb00000bfffbb0b0f0f0000bffff300f0fff000bb66bb000fffff000000000
00000c0000000000000000000fff00000f6f0000000000000000000000000b000ff3000000bbb00000ffff0000f00fb00b0fb6000f36fff00fbbbbf000000000
00080000000003000bb000000f6f000b0f6fff000bbb300b0bbbff00030000000ffb0b000fffff000ff6f0000ff00ff0000ff6f00fb6f0000ffffff000000000
00000000bff00bfbbff0bbb00ffb30030fff6f000bfffffbbffb6f000fbff000bffbffbbbf6ffff300f6ff0303bfff000ffffff00ff6ff000fbfbbb000000000
b000000bbff00bfb0f60fffb0003b00b000fff000bfffffb0ff3ff000ff6f000bf3fffb0bffff6fb0ffff00b000bbbb00f6fff6000f0f000003ffff000000000
bb0000bbbbb00bb00ff0fffb0000000b000000000bb00bbb00b00000bbbff0b00b0000b0b000fffb0000000b000000000060000000000bb000b0000000000000
0000000000b00b0b0000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000bb0000b0000b0000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b66b00000bb00b00b0000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b00b00000bbb0000b00bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000bbb000b0b000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b000000b0006bb060b00000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b0000bbb0000bb0b0000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbb00000000b0bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000202000000000000000000000001000002020000000000000000000000000002020000020200000000000000000000020200000202000000000000000000000000020200000000000000000000000000000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000708000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001718000000000000070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0708000000000000000000171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1718000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000017180000000000000000000708000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001718000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000007080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007080000000017180800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000017180000000000171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000708000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000001718000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010d000006345043051234512345063450430512345123450634504305123451234506345043051234512345063450d3451234515345093450430515345153450934504305153451534509345043051534515345
010d00000b3450430517345173450b3450430517345173450b3450430517345173450b3450430517345173450e3450d3051a3451a3450e3450d3051a3451a3451e3451a345173451434510345123451a34517345
010d00000e773007003e6353e62526640266450e7733e6353e6153e6250e7430070026640266453e625007000e773007003e6353e62526640266450e7733e6353e6153e6250e7430070026640266453e6153e625
010d00000e773007003e6353e62526640266450e7733e6353e6153e6250e7430070026640266453e625007000e773007003e6353e62526640266450e7733e6352661526625266152662526625266352664526655
010d00000e773007003e6353e62526640266450e7733e6353e6153e6250e7430070026640266453e625007000e773007003e6353e62526640266450e7733e6353e6150e7733e6250e77326625266352664526655
010d00002536525305253652536500300003002036523365253602536526360263652836028365263602636026352263522634226342233602336525360253602535025352253422534225332253322532225322
010d000026365263002636526365003000030025365233652136021365253602536526360263652836028360283522835228342283422a3602a3602a3502a3522a3422a342253602536025352253522534225342
010d00002d3352d3002d3352d3350000028305283352a3352d3302d3352f3302f33528330283352a3302a3302a3322a3322a3322a3322c3302c3352d3302d3302d3322d3322d3322d3322d3322d3322d3322d332
010d00002f3352d3002f3352f33500000283052d3352c3352a3302a3352d3302d3352f3302f3352d3302d3302d3322d3322d3322d3322c3302c3302c3322c3322c3322c332283302833028332283322833228332
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00024344
00 01034344
00 00020507
00 01040608
00 00020507
02 01040608
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

