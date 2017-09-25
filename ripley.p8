pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

ver="v1.0"

gt=0
ef=function() end
cart=function(u,d) cart_update,cart_draw=u,d gt=0 end
cart(ef,ef)

str_wall,str_empty="wall","empty"

--
-- #player

function p_update()
	p_cx=p_x+8
	p_cy=p_y+8
	
	p_tx,p_ty=px_to_tile(p_cx,p_cy)
	p_dx,p_dy,p_xdir,p_ydir=0,0,0,0
	

	local tile=get_tile(p_tx,p_ty)

	if not map_mode then
		mini_batt=max(mini_batt-1,0)
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
		if tile.occ=="body" then
			if rnd()<.5 then
				p_st,p_spr=2,64
				tckr("rifle equipped",true)
			else
				p_st,p_spr=3,96
				tckr("bait equipped",true)
			end

			tile_occ(p_tx,p_ty)
		end
		
		-- when player gets to a body, switch modes
		if tile.occ=="egg" then
			
			eggs_collected=min(eggs_collected+1,20)
			curlvl.eggs=max(curlvl.eggs-1,0)

			if eggs_collected<20 then
				tile_occ(p_tx,p_ty)

				tckr("alien egg collected",true)
			else
				if tile_t==0 then
					tckr("cargo bay is full;return to transport beacon",true)
				end
			end
			tile_t+=1
		else
			tile_t=0
		end
		
		-- #bombarm
		-- player must hover to arm bomb
		-- bomb_st: 0=unarmed;1=onhover;2=armed
		
		if tile.occ=="bomb" then
			local msg="bomb armed successfully"
			if tile.bomb_st<2 then
				if bomb_t==0 then 
					tckr("arming bomb, stand by",true) 
				end

				tile.bomb_st=1
				
				if bomb_t==sec(3) then 
					tile.bomb_st=2 
					curlvl.bombs=max(0,curlvl.bombs-1)
					tckr(msg,true) 
					if curlvl.bombs>0 then
						tckr(curlvl.bombs.." unarmed bombs remain") 
					else
						tckr("all bombs armed;find detonator to start countdown") 
					end
					--@sound bomb armed success
				end
			else
				if bomb_t==0 then 
					tckr(msg,true) 
				end
			end
			
			bomb_t+=1
		else
			bomb_t=0
		end
		
		
		-- #detonator
		-- player must hover to trigger
		-- detonator_st: 0=unarmed;1=onhover;2=armed
		
		if tile.occ=="detonator" then
			if curlvl.bombs==0 then
				if detonator_st<2 then
					if detonator_t==0 then tckr("entering detonation code",true) end

					detonator_st=1

					if detonator_t==sec(4) then 
						detonator_st,detonator_t=2,0
						tckr("countdown initiated;detonation in 30 seconds;return to transport beacon",true)
						countdown=sec(30)
						--@sound bomb armed success
					end
				else
					if detonator_t==0 then tckr("countdown active;return to transport beacon",true) end
				end
			else 
				if detonator_t==0 then tckr("find and arm all bombs first",true) end
			end
			
			detonator_t+=1
		else
			if detonator_st==1 then
				tckr("detonation sequence canceled",true)
				detonator_st=0
			end
			detonator_t=0
		end
		
		
		-- #transport
		-- player hits transport beacon
		if tile.occ=="transport" then
			transport_st=1
			
			if curlvl.eggs>0 and eggs_collected<20 and transport_t==0 then
				-- @sound buzzer
				tckr("dropship unavailable;find remaining eggs",true)
			end
			
			if (curlvl.eggs<=0 or eggs_collected==20) then
				if transport_t==0 then
					tckr("dropship landing, stay at beacon;leaving "..curlvl.name,true)
				end
				
				if transport_t==sec(9) then
					if eggs_collected==20 then
						finale_init()
					else
						nextlevel_init()	
					end
					
				end
			end
			
			transport_t+=1
		else
			if transport_st==1 then
				tckr("dropship canceled",true)
				transport_st=0
			end
			
			transport_t=0
		end
		

	
		-- turn on minimap 
		if btnzp then
			if mini_batt<=0 then
				generate_minimap()
				map_mode=true
			else
				-- @sound buzzer
				tckr("scanner recharging",true)
			end
		end
		
		-- use item
		if btnxp then
			-- beacon
			if p_st==3 then
				-- @sound bait noise
				add_bait(p_tx,p_ty)
				p_st,p_spr=1,32
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
				
				p_st,p_spr=1,32
			end

		end
		
	else
		
		if btnzp then
			mini_batt=sec(8)
			map_mode=false
			clear_minimap()
		end
	end
		
	
	
end

function p_draw()
	spr(p_spr, p_x,p_y, 2,2, p_sflip)
end




-- #bullets
function bullet_update()
	for b in all(bullets) do
		b.x+=b.dx
		b.y+=b.dy

		if px_inbounds(b.x,b.y) then 
			local t=get_px_tile(b.x,b.y)
			local px,py,cx,cy=tile_to_px(t.tx,t.ty)
			if t.occ==str_wall then
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








-- #actors
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

			if self.tile.occ=="body" then
				tile_occ(self.tx,self.ty)
				tckr("new alien detected;avoid close proximity")
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
				if self.chase then pal(13,8) end
				spr(128,self.x,self.y,2,2,self.flip)
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
			
			if self.st==2 then
				if self.t>sec(1) then
					local t=tile_occ(self.tx,self.ty, str_wall)
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
			tckr("you are dead;you collected "..eggs_collected..";press \142 to continue",true)
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
					near=get_random_tile(str_empty) 
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
					chg_st(self,3)
				else
					chg_st(self,1)
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
					if tile.occ=="body" then
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
		self.speed=self.chase_spd
		self.wpcount=99
		self.chase=true
		chg_st(self,1)
	end

end


-- update logic for ai that finds targets and wanders: huggers and aliens
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
	tile_not_near(q, str_empty, "body", 10, 8)
end

-- (quantity, sourcetype, typeoccupant, distancefromtype, distancefromplayer, callback)
function tile_not_near(q, src, occ, od, pd, f)
	for n=0,q do
		local try=1
		
		while try>0 do
			local t=get_random_tile(src)
			local list=filter_tiles(occ)
			
			if #list>0 then
				for n in all(list) do
					if not in_range(n.tx,n.ty, t.tx,t.ty, od) then
						if not in_range(t.tx,t.ty, p_tx,p_ty, pd) then
							tile_occ(t.tx,t.ty, occ)
							if f then f(t.tx,t.ty) end
							try=0
						end
					end
				end
			else
				if not in_range(t.tx,t.ty, p_tx,p_ty, pd) then
					tile_occ(t.tx,t.ty, occ)
					if f then f(t.tx,t.ty) end
					try=0
				end
			end
		end
	end
	
end


function add_eggs(q)
	tile_not_near(q, "spawn", "egg", 10, 10)
	
	if finale then
		tile_not_near(curlvl.bombs, "spawn", "bomb", 16, 16, function(tx,ty)
			set_tile_attr(tx,ty, "bomb_st", 0)
		end)
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




-- #tile

-- tile_occ(int_tilex,int_tiley, str_nameofoccupant)
function tile_occ(tx,ty, style)
	return set_tile_attr(tx,ty, "occ", style)
end

function set_tile_attr(tx,ty, key, value)
	grid[tx][ty][key]=value
	return grid[tx][ty]
end

-- get_random_tile(str_occupantname)
function get_random_tile(occ)
	local list=filter_tiles(occ)
	
	if #list>0 then
		local n=rand(#list)+1
		local t=list[n]
		t.x,t.y,t.cx,t.cy=tile_to_px(t.tx,t.ty)
		return t
	end
	
	return false
end

-- get_tile(int_tilex,int_tiley)
function get_tile(tx,ty)
	if tx<=map_tilew and tx>0 and ty<=map_tileh and ty>0 then
		local t=grid[tx][ty]
		t.x,t.y,t.cx,t.cy=tile_to_px(tx,ty)
		
		return t
	end
end

-- get_px_tile(int_pixelx,int_pixely)
function get_px_tile(pxx,pxy)
	tx,ty=px_to_tile(pxx,pxy)
	return get_tile(tx,ty)
end


-- px_to_tile(int_pixelx,int_pixely)
function px_to_tile(pxx,pxy)
	local tx=flr(pxx/16)+1
	local ty=flr(pxy/16)+1
	return tx,ty
end

-- #tile_to_px(int_tilex,int_tiley)
function tile_to_px(tx,ty)
	local px=(tx*16)-16
	local py=(ty*16)-16
	local cx=px+8
	local cy=py+8
	return px,py,cx,cy
end


-- #move_is_blocked(int_objpixelx,int_objpixely, int_objpixeldx,int_objpixeldy, tbl_objhitbox)
function move_is_blocked(px,py, dx,dy, hbox)
	local check={}
	
	function blocktile(t) 
		if t.occ==str_wall or t.occ=="sniper" then return true end
		return false
	end
	
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
		if blocktile(get_tile(t1x,t1y)) then
			return true
		else
			local t2x,t2y=px_to_tile(xr+dx,yt+dy)
			if blocktile(get_tile(t2x,t2y)) then
				return true
			else
				local t3x,t3y=px_to_tile(xl+dx,yb+dy)
				if blocktile(get_tile(t3x,t3y)) then
					return true
				else
					local t4x,t4y=px_to_tile(xr+dx,yb+dy)
					if blocktile(get_tile(t4x,t4y)) then
						return true
					end
				end
			end
		end
		
	
		check={}
		return false
	else
		check={}
		return true
	end
end


-- filter_tiles(str_occupant)
function filter_tiles(occ)
	local list={}
	
	for tx=1,map_tilew do
		for ty=1,map_tileh do
			local t=grid[tx][ty]
			t.x,t.y,t.cx,t.cy=tile_to_px(tx,ty)
			
			if t.occ==occ then
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


-- find_nearest(int_pixelx,int_pixely, tbl_items)
function find_nearest(x,y,list)
	local d=9999
	local n=false
	
	for t in all(list) do
		local far=distance(t.x,t.y, x,y)

		if far<d then
			d=far
			n=t
		end
	end

	return n,d
end





-- #map
-- gen_map(int_screenwidth, int_screenheight)
function gen_map(w,h)
	
	-- map settings
	map_w,map_h=w,h
	map_wpx,map_hpx=map_w*128,map_h*128
	map_tilew,map_tileh=map_w*8,map_h*8
	force_eggs=0
	
	-- seed grid with all empty
	-- coordinates are for 16x16px blocks; 8 per screen
	grid={}
	level_list={}
	local snipers={}

	for x=1,map_tilew do
		grid[x]={}
		
		for y=1,map_tileh do
			grid[x][y]={
				tx=x,ty=y,
				n=0,f=0,g=0,h=0,p=0,status=0, --pathfinding vars
				occ=str_empty,
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

	
	if finale then
		queen_x=map_w
		queen_y=rand(map_h)+1
		
		create_screen(1,rand(map_h)+1, read_spritelayout(0,0))
		create_screen(queen_x,queen_y, read_spritelayout(0,1))
	else
		create_screen(rand(map_w)+1,rand(map_h)+1, read_spritelayout(0,0))
	end
	
	local n=1
	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=grid[x][y]
			
			level_list[n]=plot
			plot.n=n
			n+=1
			
			-- add sniper aliens in places where there is dark green
			if plot.occ=="sniper" then
				add(snipers,plot)
			end
		end
	end
	
	
	-- add random aliens, not too close to player
	local aliens_added=0
	while aliens_added<curlvl.aliens do
		local t=get_random_tile(str_empty)
		
		if not in_range(t.tx,t.ty, p_tx,p_ty, 8) then
			add_alien(t.tx,t.ty)
			aliens_added+=1
		end
	end

	-- add snipers to level
	if #snipers>0 then
		for n=0,curlvl.snipers do
			local t=rnd_table(snipers)
			del(snipers,t)

			if t.tx+1>map_tilew then
				et={occ=str_wall}
			else
				et=grid[t.tx+1][t.ty]
			end

			if t.tx-1<1 then
				wt={occ=str_wall}
			else
				wt=grid[t.tx-1][t.ty]
			end

			if et.occ!=str_wall and wt.occ!=str_wall then
				if rnd()<.5 then t.flip=true end
			else
				if et.occ==str_wall then 
					if wt.occ!=str_wall then
						t.flip=true 
					end
				end
			end

			add_sniper(t.tx,t.ty,t.flip)
		end
		
		-- turn left over sniper slots into bushes
		for t in all(snipers) do
			grid[t.tx][t.ty].occ=str_wall
			grid[t.tx][t.ty].spr=rnd_table(bush_sprites)
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
			local tile={occ=str_empty,w=true}
			local bspr=rnd_table(bush_sprites)
			
			--bush/rock wall
			if pxc==11 or pxc==3 or pxc==6 then 
				tile.occ=str_wall
				tile.spr=bspr
				tile.w=false
				
				if pxc==6 then tile.spr=rnd_table({76,78}) end
			end

			-- sniper/bush
			if pxc==3 and curlvl.snipers>0 then 
				tile.occ="sniper"
				tile.spr=bspr
				tile.w=false
			end
			
			-- transport computer
			if pxc==12 then 
				tile.occ="transport"
			end
			
			-- egg spawner
			if pxc==15 then 
				tile.occ="spawn"
			end
			
			-- egg spawner
			if pxc==2 then 
				tile.occ="egg"
				force_eggs+=1
			end
			
			-- bomb detonator
			if pxc==14 then 
				tile.occ="detonator"
				detonator_st=0
				detonator_t=0
			end
			
			-- queen
			if pxc==9 then 
				tile.occ="queen"
			end
			
			

			-- player start; doesn't change tile attrs
			if pxc==8 then
				p_x,p_y=tile_to_px(tilex,tiley)
				p_cx=p_x+8
				p_cy=p_y+8
				p_tx,p_ty=tilex,tiley
			end

			
			for k,v in pairs(tile) do
				grid[tilex][tiley][k] = v
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

-- px_inbounds(int_pixelx,int_pixely) 
function px_inbounds(pxx,pxy) 
	if pxx<map_wpx and pxx>1 and pxy<map_hpx and pxy>1 then
		return true
	end
	
	return false
	
end



-- #minimap

--

function mini_dot(x,y,c)
	x1=((x-1)*2)+mini_x+7
	y1=((y-1)*2)+mini_y+7
	--x2=((x-1)*2)+2+mini_x+7
	--y2=((y-1)*2)+2+mini_y+7

	--rectfill(x1,y1, x2,y2, c)
	print("+",x1,y1-1,c)
end

function clear_minimap()
	minimap={}
	radar_dots={}
end

function generate_minimap() 
	clear_minimap()
	

	mini_x,mini_y,mini_radar=0,0,111

	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=grid[x][y]

			if plot.occ=="body" or plot.occ=="egg"  then
				add(minimap, {x=x,y=y,c=11})
			end
			
			if plot.occ=="transport" then add(minimap, {x=x,y=y,c=12}) end
		end
	end
	
	for a in all(get_aliens()) do
		add(minimap, {x=a.tx,y=a.ty,c=11})
	end
	
	add(minimap, {x=p_tx,y=p_ty,c=8})
	
	printh(#minimap)
end


function mini_update()
	--[[
	if map_w>4 or map_h>4 then
		if btnl	then mini_x+=1 end
		if btnr	then mini_x-=1 end
		if btnu	then mini_y+=1 end
		if btnd	then mini_y-=1 end
	end

	mini_radar-=.65
	
	if flr(mini_radar)==78 then 
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
	
	if mini_radar<0 then mini_radar=111 end
	]]
end

function mini_draw()
	laptop(1)
	
	--rectfill(0,0, 127,116, 0)
	
	rectfill(mini_x+6,mini_y+6, (map_tilew*2)+mini_x+8,(map_tileh*2)+mini_y+8, 3)
	rect(mini_x+6,mini_y+6, (map_tilew*2)+mini_x+8,(map_tileh*2)+mini_y+8, 11)
	
	for mm in all(minimap) do mini_dot(mm.x,mm.y,mm.c) end
	
	print("+you",92,100,8)
	print("+beacon",92,108,12)
	print("+bio",92,116,11)
	
	--[[
	rectfill(0,0, 127,5, 0)
	rectfill(0,0, 3,113, 0)
	rectfill(0,89, 127,116, 0)
	rectfill(88,0, 127,116, 0)
	

	rect(2,2, 125,114, 12)
	rect(4,4, 87,86, 12)
	
	rect(89,4, 123,76, 12)
	
	rect(4,88, 87,112, 12)
	
	rectfill(89,78, 123,112, 1)
	
	local item="none"
	if p_st==2 then item="pulse rifle" end
	if p_st==3 then item="alien bait" end

	print("eggs:"..curlvl.eggs.."\n\n\ncargo:\n"..eggs_collected, 93, 9, 11)
	print("planet:"..curlvl.name.."\n\nitem:"..item, 8,92, 11)
	]]
	
	--[[
	circ(106,95,7,12)
	circ(106,95,14,12)
	pset(106,95,12)
	
	for d in all (radar_dots) do circfill(d.x,d.y,1,7) end
	
	if mini_radar>78 then
		line(90,mini_radar, 122,mini_radar, 7)
	end
	]]
	
	
	--rect(89,78, 123,112, 12)
	
end



-- #ticker
mini_txt_scroll=100
tckr_scrolling=false
tckr_text_now=""

function tckr(txt,clear)
	local list=split(txt)
	
	if clear then tckr_text={} tckr_scrolling=false end
	
	for t in all(list) do add(tckr_text,t) end
	
	if clear then tckr_next() end
end

function tckr_next()
	if #tckr_text>0 and not tckr_scrolling then
		mini_txt_scroll=105
		tckr_text_now=tckr_text[1]
		del(tckr_text, tckr_text_now)
		tckr_scrolling=true
	end
end

function tckr_update()
	if tckr_scrolling then
		mini_txt_scroll-=.8
			
		if mini_txt_scroll<=-120 then tckr_scrolling=false end
	end
		
	tckr_next()

end




function tckr_draw()
	rectfill(0,117, 127,127, 1)
	
	if tckr_scrolling then
		print(tckr_text_now, mini_txt_scroll,120, 12)
	end

	rectfill(90,117, 127,127, 5)
	rect(0,117, 90,127,5) 


	if mini_batt>0 then pal(11,8) end
	spr(25, 94,120)
	pal()


	if finale then
		print(time_to_text(countdown), 106,120, 6)
	else
		spr(26, 118,119)
		print(curlvl.eggs, 113,120, 6)
	end
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
function game_init()
	blood={}
	tckr_text = {}
	bullets   = {}
	actors    = {}

	minimap     = {}
	mini_x,mini_y=4,4
	mini_batt = 0

	map_mode        = false
	egg_timer       = sec(curlvl.eggtimer)
	
	
	p_dead=false
	p_x,p_y,p_spd=0,0,1
	p_cx,p_cy=p_x+8,p_y+8
	p_hbox={y=4,x=4,w=7,h=7}
	p_sflip=false
	p_freeze=0
	p_st=1 -- state: 1=unarmed, 2=gun, 3=bait
	p_spr=32
	transport_t=0
	
	-- @debug
	curlvl={name="foo",w=5,h=6,bodies=10,eggs=0,eggtimer=45,aliens=0,snipers=0,colors={11,3}}
	
	gen_map(curlvl.w,curlvl.h)
	
	--add_bodies(curlvl.bodies)
	--add_eggs(curlvl.eggs)
	curlvl.eggs+=force_eggs
	
	local arrival="arrival on "..curlvl.name
	if finale then
		tckr(arrival..";find and arm 3 bombs;find detonator to start countdown",true)
	else
		tckr(arrival..";find eggs before they hatch;scan shows "..curlvl.eggs.." eggs in range",true)	
	end
	

	if level_id==1 then
		tckr("press \142 to scan area;press \151 to use weapon")	
	end
	
	cart(game_update,game_draw)
end


function game_update()
	
	if p_dead then
		if btnxp or btnzp then _init() end
		
		if gt>=sec(12) then 
			tckr("game over;press \142 to continue")
			gt=0
		end
		
	else	
		--for a in all(actors) do a.update(a) end

		
		-- #eggtimer
		local nomore="no more eggs detected;return to transport beacon";
		if curlvl.eggs>0 then
			egg_timer-=1
			if egg_timer<=0 then
				local t=get_random_tile("egg")
				
				
				-- @sound hatch alert
				tckr("new life form detected",true)

				curlvl.eggs-=1

				if not finale then
					if curlvl.eggs<=0 then
						tckr(nomore)
					else
						tckr(curlvl.eggs.." eggs remaining")
					end
				end

				add_hugger(t.tx,t.ty)
				tile_occ(t.tx,t.ty)

				egg_timer=sec(curlvl.eggtimer)
			end
		end
		
		if finale and detonator_st==2 then
			countdown-=1
		end
		
		if map_mode then
			mini_update()
		else
			--bullet_update()
		end
		
		
		p_update()
		
		
	end
	
	--tckr_update()
	
end


function game_draw()
	camera(p_cx-64, p_cy-64)
	
	if curlvl.colors then
		swap_bright=curlvl.colors[1]
		swap_dark=curlvl.colors[2]
	end
	
	
	--[[grass map background
	for bgx=0,map_w-1 do
		for bgy=0,map_h-1 do
			map(0,0, bgx*127,bgy*127, 16,16)
		end
	end]]
	
	-- level screens
	palt(2,true)
	palt(0,false)
	
	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=grid[x][y]
			local px,py=tile_to_px(x,y)
			

			
			
			if plot.occ=="body" then
				spr(9,px,py+3,2,1)
			end
			
			if plot.occ=="egg" then
				spr(14,px,py,2,2)
			end
			
			if plot.occ=="transport" then
				if transport_st==1 then
					pal(13,8)
					pal(12,8)
				end
			
				spr(12,px,py,2,2)
			end
			
			if plot.occ=="bomb" then
				if plot.bomb_st==2 then pal(11,8) end
				spr(110, px, py, 2,2)
			end
			
			if plot.occ=="detonator" then
				if plot.detonator_st==2 then pal(11,8) end
				spr(108, px, py, 2,2)
			end
			
			if plot.occ=="queen" then
				pal(11,1) pal(3,1)
				zspr(42,2,2,px-16,py-8, 2, 1)
			end
			
			
			-- only things that need color swapped based on level colors go below here
			if swap_bright then
				pal(11,swap_bright)
				pal(3,swap_dark)
			end
			
			if plot.occ==str_wall then
				spr(plot.spr, px, py, 2,2)
			end
			
			if plot.occ=="sniper" then
				spr(42, px, py, 2,2, plot.flip)
			end
			
			
			if plot.occ==99 then
				spr(7, px, py, 2,2)
			end
		
		end
	end
	
	

	-- level borders
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
	--for a in all(actors) do a.draw(a) end
	
	bullet_draw()
	
	-- player
	if p_freeze>0 then pal(10,13) end
	p_draw()
	pal()
	
	
	
	
	
	
	-- ticker
	camera(0,0)
	tckr_draw()
	
	if p_dead then
		for b in all(blood) do
			circfill(b[1],b[2],b[3], 8)
		end
		
		if blood_t>sec(3) then
			make_blood()
		end
		blood_t+=1
	end
	
	
	-- minimap, user-controlled
	if map_mode then mini_draw() end
	
	
	
	
end




-- #scenes
function laptop(hide)
	rectfill(0,0,128,128,0)
	rect(0,0, 127,127, 12)
	rect(2,2, 125,93, 12)

	rect(89,95, 125,125, 12)
	rect(2,95, 87,125, 12)

	if not hide then zspr(74,2,2,90,103, 2, 1) end
	
	print("cargo: "..eggs_collected.."/20",7,100,7)
		
	local ix=5
	local iy=107

	for n=1,20 do
		if n<=eggs_collected then pal(13,10) end
		spr(26,ix,iy,1,1) pal()
		ix+=8

		if n==10 then ix=5 iy+=8 end
	end
end


-- #nextlevel
function nextlevel_init()
	level_id+=1
	p_transport=false
	
	local colors={{3,4},{11,9},{11,4},{15,14}}
	
	-- after level 5, maps are same always big, just new layout
	if level_id>#levels then
		local abc=split("a;b;c;d;e;f;g;h;i;j;k;l;m;n;o;p;q;r;s;t;u;w;v;y;z")
		local name=rnd_table(abc)..rnd_table(abc).."-"..random(75,850)

		curlvl={name=name,w=5,h=6,bodies=10,eggs=5,eggtimer=45,aliens=6,snipers=6,colors=rnd_table(colors)}
	else
		curlvl=levels[level_id]
	end
	
	if finale then
		curlvl={name="pco 8",w=7,h=4,bombs=3,bodies=10,eggs=0,eggtimer=25,aliens=3,snipers=6,colors=rnd_table(colors)}
	end
	
	
	
	function nextlevel_update()
		if btnzp or btnxp then 
			printh(1)
			game_init() 
		end
	end 

	function nextlevel_draw()
		--laptop()
		
		center_text("landing on: "..curlvl.name, 8, 10)
		
		local ax=32
		local txta="wait at transport\nbeacon to leave planet"
		if finale then
			spr(110, 8,17, 2,2)
			print("find and arm\n3 remote bombs", ax,21, 7)
				
			spr(108, 8,38, 2,2)
			print("find detonator to\nstart countdown",ax,41, 7)
				
			spr(12, 8,60, 2,2)
			print(txta,ax,61, 7)
		else
			spr(14, 8,18, 2,2)
			print("find "..curlvl.eggs.." alien eggs\nbefore they hatch", ax,22, 7)

			spr(12, 8,41, 2,2)
			print(txta,ax,42, 7)
		end
		
		print("press \142 to start",ax,83, 7)
		
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







-- #help
help_init=function() --must be var for use in attract modes
	function help_update()
		if btnxp or btnzp then cart(help_last, help_p2) end
	end
	
	function help_last()
		if btnxp or btnzp then title_init() end
	end
	
	function help_p1()
		-- left side
		palt(2,true)
		spr(14, 1,2, 2,2)
		print("find and collect alien\neggs before they hatch", 22,6, 7)

		spr(9, 1,25, 2,1)
		print("search bodies to\nequip weapons",22, 24,7)
		
		spr(12, 1,41, 2,2)
		print("stand on beacon to\nleave planet",22,42, 7)
		
		print("press \142 for map scan\n\npress \151 to use weapon\n\n\nwatch message ticker\nfor help and tips", 22,65, 7)
		
		pal()
	end
	
	function help_p2()
		-- left side
		palt(2,true)
		spr(64, 1,2, 2,2)
		print("gun has one shot\nauto-aims at aliens", 22,6, 7)

		spr(96, 1,25, 2,2)
		print("bait will distract\naliens briefly",22, 24,7)
		
		print("avoid aliens", 22,44, 8)
		
		
		spr(160, 1,53, 2,2) 
		print("facehuggers find bodies\nto become aliens",22,55, 7)
		
		spr(128, 1,73, 2,2) 
		print("aliens search and chase\nwhen you are near",22,73, 7)

		
		spr(42, 1,93, 2,2) 
		print("jungle aliens hide\nbriefly paralyze you",22,93, 7)
		-- right side		
		
		
		   
		
		
		pal()
	end
	
	cart(help_update, help_p1)
end







-- #title
function title_init()
	finale=false
	level_id=0
	eggs_collected=0
	countdown=sec(30)
	grid={}
	level_list={}
	blood={}
	actors={}
	levels={}
	
	-- #levels - define levels
	-- w/h=screen size; eggtimer=seconds to hatch; colors=array of primary,secondary
	add(levels,{name="jl78",w=6,h=5,bombs=0,bodies=2,eggs=0,eggtimer=9999,aliens=0,snipers=0,colors={11,3}})
	add(levels,{name="col-b",w=3,h=4,bombs=0,bodies=3,eggs=2,eggtimer=30,aliens=2,snipers=0,colors={11,4}})
	add(levels,{name="mf 2018",w=4,h=4,bombs=0,bodies=4,eggs=4,eggtimer=40,aliens=3,snipers=2,colors={9,4}})
	add(levels,{name="roxi 9",w=5,h=4,bombs=0,bodies=5,eggs=4,eggtimer=45,aliens=4,snipers=3,colors={11,4}})
	add(levels,{name="pv-418",w=6,h=6,bombs=0,bodies=7,eggs=5,eggtimer=50,aliens=6,snipers=6,colors={14,2}})
	
	cart(title_update,title_draw)
end

function title_update()
	if btnzp then nextlevel_init() end
	if btnxp then help_init() end
end 

function title_draw()
	print("alien harvest\n\npres \142 to start\npress \151 for help",0,0,7)
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
	local dbmem=flr((stat(0)/1024)*100).."%m / "..stat(1).."%c"
	--flr(((flr(stat(1)*100))/200)*100)
	print(dbmem,70,0,8)
	if debug then print(debug,1,1,7) end
end








-- #utility
function zspr(n,w,h,dx,dy,dz,fx,fy)
  sx = 8 * (n % 16)
  sy = 8 * flr(n / 16)
  sw = 8 * w
  sh = 8 * h
  dw = sw * dz
  dh = sh * dz

  sspr(sx,sy,sw,sh, dx,dy,dw,dh, fx,fy)
end

function time_to_text(time)
	local mins=0
	local secs=flr(time/60) --seconds
	local micro=time%60
	
	while secs>=60 do
		mins+=1
		secs-=60
	end
	
	if micro<10 then micro="0"..micro end
	if mins<10 then mins="0"..mins end
	if secs<=0 then
		secs="00" 
	elseif secs<10 then 
		secs="0"..secs
	end

	return secs..":"..micro
end


function chg_st(o,ns) o.t=0 o.st=ns end
function rand(x) return flr(rnd(x)) end
function sec(f) return flr(f*60) end -- set fps here if you need


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



function center_text(s,y,c) print(s,64-(#s*2),y,c) end



-- in_table(needle, haystack)
function in_table(element, tbl)
  for _, value in pairs(tbl) do
    if value == element then
      return true
    end
  end
  return false
end


function rnd_table(t)
	local r=flr(rnd(#t))+1
	return(t[r])
end
	
	
	

function dir_calc(angle,speed)
	local dx=cos(angle)*speed
	local dy=sin(angle)*speed
	
	return dx,dy
end

function get_line(x,y,dist,dir)
	fx = flr(cos(dir)*dist+x)
	fy = flr(sin(dir)*dist+y)
	
	return fx,fy
end


function distance(ox,oy, px,py)
  local a = abs(ox-px)/16
  local b = abs(oy-py)/16
  return sqrt(a^2+b^2)*16
end


function random(min,max)
	n=flr(rnd(max-min))+min
	return n
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return flr(num * mult + 0.5) / mult
end

-- #astar
function find_path(start_index,target_index)
	local path={}
	
	for v in all(level_list) do
		v.p=0
		v.status=0
	end

	local start=grid[start_index.x][start_index.y]
	local target=grid[target_index.x][target_index.y]
	local open={start.n}
	local closed={}
	
	start.g=0
	start.h=abs(target.x-start.x)+abs(target.y-start.y)
	start.status=1
	
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

		nchecks={
	        {x=current.tx, y=current.ty-1},
	        {x=current.tx, y=current.ty+1},
	        {x=current.tx+1, y=current.ty},
	        {x=current.tx-1, y=current.ty},        
	    }

		for cxy in all(nchecks) do
			
			if cxy.x>=1 and cxy.x<=map_tilew and cxy.y>=1 and cxy.y<=map_tileh then
				local neighbor=grid[cxy.x][cxy.y]
				
				if neighbor.n==target.n then
					target.p=current.n
					add(closed,target.n)

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
				
				if neighbor.w then
					if neighbor.status==0 then
						neighbor.p=current.n
						neighbor.g=current.g+1
						neighbor.h=abs(target.x-neighbor.x)+abs(target.y-neighbor.y)
						neighbor.status=1
						add(open,neighbor.n)
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
222aa222222222220000000000000000000000000000000000000000000000000000000000000000aa0770aa1770aa0000000000000000000000000000000000
22aaaa22222222220000000000000000000000000000000000000000000000000000000000000000aa0770aa1770aa0000000000000000000000000000000000
22aa00222222222200000000000000000000000000000000000000000000000000000000000000000aa00aaaa00aa00000006660500000000000000000000000
2a00aa2aaaaa222200000000000000000000000000000000000000000000000000000000000000000aa00aaaa00aa00000066660550000000000000000000000
aa000aaa00aaaaa2000000000000000000000000000000000000000000000000000000000000000000aaaa00aaaa000000066060555000000000000000000000
aaa0aaaaaaaaaaa2000000000000000000000000000000000000000000000000000000000000000000aaaa00aaaa000000066660555000000000000000000000
22aaa000aa2222220000000000000000000000000000000000000000000000000000000000000000000aa0770aa0000000060060055500000000006660550000
22000a22a22222220000000000000000000000000000000000000000000000000000000000000000000aa0770aa0000000666666055500000000666660555000
220aaa22222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000600606055500000006666660555000
22a0a0a2222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000666666055550000006666660555500
22aa00aa222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000600066055550000006666660555500
22aa222a222222220000000000000000000000000000000000000000000000000000000000000000000000000000000006666066005555000066666660055500
2aa2222aa22222220000000000000000000000000000000000000000000000000000000000000000000000000000000006606606605555000066666666055550
aa02222aaa2222220000000000000000000000000000000000000000000000000000000000000000000000000000000006666666605555000066666666055550
0aa22222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000006666666605555000006666666055500
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000066666605550000000006666050000
222aa222222222a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22aaaa2222222a220000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000
22aa00222222a2220000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000
2a00aa22222a22220000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000c00000c00000
aa0000a222a222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c00000000000cc00000cc0000
aaa0aa0aaa2222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0000000000000ccccc000000
20aa00000a222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccc00000000c0a0a0c00000
200aaaaaa222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000c0000000c00a00c00000
2000000aa222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000c0a0aa000c0000000c0a0a0c00000
20aa00a00222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000c00a00aa0c0000000c00a00c00000
20a00a200222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000c0000000c0a0a0c00000
20a2a22a02222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccc00000b000ccccc0000b0
2a02222aa222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000c000b00cc00000cc0000
aa02222aaa22222200000000000000000000000000000000000000000000000000000000000000000000000000000000b0c0000b00000c0b0b00c000b0c00b00
2aa2222222222222000000000000000000000000000000000000000000000000000000000000000000000000000000000bc00b00000b0cb0000000b0000b0000
222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000b00b000b0b0b0000bb000b000b000
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
00000c00000000000000ff000fff00000f6f00000fff00000000000000000b000ff3000000bbb00000ffff0000f00fb00b0fb6000f36fff00fbbbbf000000000
00080000000003000bb000000f6f000b0f6fff000bbb300b0bbbff00030000000ffb0b000fffff000ff6f0000ff00ff0000ff6f00fb6f0000ffffff000000000
00000000bff00bfbbff0bbb00ffb30030fff6f000bfffffbbffb6ff00fbff000bffbffbbbf6ffff300f6ff0303bfff000ffffff00ff6ff000fbfbbb000000000
b000000bbff00bfb0f60fffb0003bf0b000fff000bfffffb0ff3ff000ff6f000bf3fffb0bffff6fb0ffff00b000bbbb00f6fff6000f0f000003ffff000000000
bb0000bbbbb00bb00ff0fffb0000ff0b000000000bb00bbb00b00000bbbff0b00b0000b0b000fffb0000000b000000000060000000000bb000b0000000000000
b00000b000b00b0b0000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0022000000b0000b0000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020000b0000bb00b00b0000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000009b0000bbb0000b00bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0000b0000bbb000b0b000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000020b00006bb060b00000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020200000000bb0b0000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b00000b000000b0bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000202000000000000000000000001000002020000000000000000000000000002020000020200000000000000000000020200000202000000000000000000000000020200000000000000000000000000000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000070800000000000005060102030405060506030403040506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000171800000000000015161112131415161516131413141516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000708000000000000000000000003040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001718000000000000070800000013140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0708000000000000000000171800000001020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1718000000000000000000000000000011120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007080000000000000000000011120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000017180000000000000000000705060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001715160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000007080000000003040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007080000000017180800000013140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000017180000000000171800000005060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000070800000000000000000000000015160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000171800000000000000000000000005060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000708000000000015160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

