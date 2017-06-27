pico-8 cartridge // http://www.pico-8.com
version 10
__lua__

--
-- #globals and system needs
--
gt=0

ef=function() end
cart_update,cart_draw=ef,ef
cart=function(u,d)
	u=u or ef
	d=d or ef
	cart_update,cart_draw=u,d
	gt=0
end


--
-- #player
function p_init()
	p_x,p_y,p_spd=0,0,1
	p_cx,p_cy=p_x+8,p_y+8
	p_hbox={y=4,x=4,w=7,h=7}
	p_sflip=false
	p_freeze=0
	p_st=1 -- state: 1=unarmed, 2=gun, 3=beacon
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
			else
				p_st=3
				p_spr=96
			end

			set_tile_occupant(p_tx,p_ty,"empty")
		end
		
		-- when player gets to a body, switch modes
		if tile.occupant=="egg" then
			eggs_collected=min(eggs_collected+1,10)
			egg_count+=1
			current_level.eggs=min(current_level.eggs-1,0)

			set_tile_occupant(p_tx,p_ty,"empty")
			
			add_ticker_text("alien egg collected;"..current_level.eggs.." eggs remaining")
			
			
			if eggs_collected>=10 then
				add_ticker_text("mission accomplished;return to transport beacon immediately")
			end
		end
		
		-- player hits transport beacon
		if tile.occupant=="transport" and not p_transport then
			printh(p_transport)
			eggs_collected=min(eggs_collected+1,10)
			if current_level.eggs>0 then
				add_ticker_text("contacting dropship...;dropship unavailable",true)
			else
				add_ticker_text("contacting dropship...",true)
				p_transport_t=1
			end
			p_transport=true
		end
		
		if tile.occupant!="transport" and p_transport then
			p_transport=false
		end
		
		if p_transport_t>1 then 
			p_transport_t+=1
			
			if p_transport_t==100 then
				add_ticker_text("dropship en route")
			end
			
			if p_transport_t==300 then
				-- level complete
				-- #todo
			end
		end


	
		-- turn on minimap 
		if btnzp and minimap_battery<=0 then
			generate_minimap()
			map_mode=true
		end

		
		-- use item
		if btnxp then
			-- beacon
			if p_st==3 then
				add_beacon(p_tx,p_ty)
				p_st=1
				p_spr=32
			end


			-- fire gun
			if p_st==2 then
				
				-- create player bullet object
				local targets={}
				local obj={x=p_cx,y=p_cy,c=10}
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
					for a in all(actors) do
						if a.id==2 or a.id==1 then
							if in_range(self.x,self.y, a.cx,a.cy, 10) then
								chg_st(a,99)
								del(bullets,self)
							end
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
			minimap_battery=600
			map_mode=false
		end
	end -- /map_mode
end

function p_draw()
	spr(p_spr, p_x,p_y, 2,2, p_sflip)
	--debug_hitbox(p_x,p_y,p_hbox)
end




-- #bullets
-- common actions for all bullets. creation object is within actor update
function bullet_update()
	for b in all(bullets) do
		b.x+=b.dx
		b.y+=b.dy

		if px_inbounds(b.x,b.y) then 
			local t=get_px_tile(b.x,b.y)
			if t.occupant=="wall" then
				if in_range(b.x,b.y, t.cx,t.cy, 12) then
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
	for b in all(bullets) do 
		circfill(b.x,b.y, 3, b.c)
	end
end







--
-- #actors
-- npcs and ai


-- #beacon - attracts aliens for limited time
-- adds beacon actor to map
function add_beacon(tx,ty)
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
						if self.t>300 then -- release alien after 5 seconds
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
		
			
			if self.t>300 then
				del(actors,self)
			end
			
			self.t+=1
		end,
		draw=function(self)
			spr(9, self.x+4,self.y, 1,2)
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
			
			if self.st==99 and self.t>180 then
				del(actors,self)
			end
			
			self.t+=1
		end,
		draw=function(self)
			

			if self.st!=99 then
				if self.chase then pal(15,8) end -- switch to red hugger

				spr(72,self.x,self.y,2,2,self.flip)

				--[[ pathing highlighting debug
				if self.st>0 then
					for n in all(self.navpath) do
						local t=level_list[n]
						highlight_tile(t.x,t.y,12)
						rect(t.cx-6,t.cy-6, t.cx+6,t.cy+6, 8)
					end	
				end
				]]
			else
				spr(40,self.x,self.y,2,2)
			end
			
			
			--pset(self.cx,self.cy,8)
			--highlight_tile(self.x,self.y,15)
			--debug_hitbox(self.x,self.y,self.hbox)
			
			--[[ pathing highlighting debug
			if self.st>0 then
				for n in all(self.navpath) do
					local t=level_list[n]
					highlight_tile(t.x,t.y,12)
					rect(t.cx-6,t.cy-6, t.cx+6,t.cy+6, 8)
				end	
			end
			]]
			
			
		end
	}
	
	obj.x,obj.y=tile_to_px(tx,ty)

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
		chase=false,
		navpath={},
		beacon=false,
		foo={},
		update=function(self)
			update_walker(self)
			
			-- within a beacon, go there and sleep
			if self.st==10 then
				local heading   = atan2(self.beacon.cx-self.x, self.beacon.cy-self.y) 
				self.dx,self.dy = dir_calc(heading, 1) -- wander speed
				self.flip=sprite_flip(heading)
				self.chase=false
				
				chg_st(self,11)
			end
			
			if self.st==11 then
				if not in_range(self.beacon.cx,self.beacon.cy, self.cx,self.cy, 16) then
					if not move_is_blocked(self.x,self.y, self.dx,self.dy, self.hbox) then
						self.x+=self.dx
						self.y+=self.dy
					end
				end
			end
			
			if self.st==99 and self.t>180 then
				del(actors,self)
			end
			
			self.t+=1
		end,
		draw=function(self)
			if self.st!=99 then
				if self.chase then pal(13,8) end -- switch to red when in chase

				spr(1,self.x,self.y,2,2,self.flip)


				--[[ pathing highlighting debug
				if self.st>0 then
					for n in all(self.navpath) do
						local t=level_list[n]
						highlight_tile(t.x,t.y,12)
						--rect(t.cx-6,t.cy-6, t.cx+6,t.cy+6, 8)
					end	
				end
				]]
			else
				-- dead bones
				spr(40,self.x,self.y,2,2)
			end
			
			
		end
	}
	
	obj.x,obj.y=tile_to_px(tx,ty)

	add(actors, obj)
end


-- #sniper
function add_sniper(tx,ty,flip)
	local obj={
		id=4,
		dx=0,dy=0,
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
					local obj={
						dx=4,x=self.x+16,
						c=13,dy=0,
						y=self.y+8,
						update=function(b)
							if b.x>=p_cx-8 and b.x<=p_cx+8 then
								del(bullets,b)
								p_freeze=100
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
				if self.t>60 then
					local t=set_tile_occupant(self.tx,self.ty, "wall")
					t.spr=rnd_table({3,34,68})
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
	

	-- defaults of hugger	
	local wander_speed=1
	local chase_speed=1.5
	local detect_range=25
	local escape_range=35

	if id==2 then -- alien
		wander_speed=.75
		chase_speed=1.2
		detect_range=40
		escape_range=48
	end
	
	
	


	-- alien is always looking for player. this will skip the delay-find state of huggers
	if id==2 then
		if in_range(p_cx,p_cy, self.cx,self.cy, detect_range) then
			if not self.chase then
				chg_st(self,4)
			end
		else
			self.chase=false
		end
	end


	-- caught the player; end state and game over
	if self.tx==p_tx and self.ty==p_ty then
		chg_st(self,98) --debug
		printh("alien tile "..self.tx..","..self.ty)
		printh("player tile "..p_tx..","..p_ty)
		printh("player dead")
	end
	

	-- initial pathfinding
	if self.st==0 then
		self.chase=false
		self.speed=wander_speed
		
		if self.t<2 then
			local near=false

			--hugger
			if id==1 then
				near=nearest_tile_oftype(self.cx,self.cy,"body")
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
		if self.t>120 then
			chg_st(self,1)
		end
	end
	
	
	-- get heading towards next waypoint
	if self.st==1 then
		self.dest=level_list[self.navpath[self.waypoint]]
		self.dest.x,self.dest.y=tile_to_px(self.dest.tx,self.dest.ty)	

		local heading   = atan2(self.dest.x-self.x, self.dest.y-self.y) 
		self.dx,self.dy = dir_calc(heading, self.speed) -- wander speed
		self.flip=sprite_flip(heading)

		chg_st(self,2)
	end
	
	
	-- movement towards waypoint
	if self.st==2 then
		self.x+=self.dx
		self.y+=self.dy
		
		-- if actor is chasing player but player escapes, stop and re-pathfind
		if self.chase and not in_range(p_cx,p_cy, self.cx,self.cy, escape_range) then
			--self.chase=false
			--self.waypoint=#self.navpath
			chg_st(self,0)
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
		if in_range(p_cx,p_cy, self.cx,self.cy, detect_range+10) then
			chg_st(self,4)
		else
			if self.t>150 then
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
		self.speed=chase_speed --chase speed
		self.wpcount=99 --so there are no stops along the way
		self.chase=true
		chg_st(self,1)
	end

end


-- update logic for ai that finds targets and wanders: huggers and aliens
-- 

function pathfind(startx,starty,goaltx,goalty)
	printh("new path to "..goaltx..","..goalty)
	printh("player tile "..p_tx..","..p_ty)
	local navpath=find_path({x=startx,y=starty}, {x=goaltx,y=goalty})
	local endpoint=level_list[navpath[#navpath]]
	
	return navpath,endpoint,1
end


function sprite_flip(d)
	if d>.25 and d<.75 then return true end
	return false
end




function add_bodies(q)
	for n=1,q do
		local t=get_random_tile("empty")
		set_tile_occupant(t.tx,t.ty, "body")
		
		printh("body at "..t.tx..","..t.ty)
	end
end


function add_eggs(q)
	for n=1,q do
		local t=get_random_tile("spawn")
		set_tile_occupant(t.tx,t.ty, "egg")
	end
end






-- returns true if an object is withing square range of another; pixels only
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

-- returns random tile object of specified occupant type
-- get_random_tile(str_occupantname)
function get_random_tile(occupant)
	local list=filter_tiles(occupant)
	
	if #list>0 then
		local n=rand(#list)+1
		return list[n]
	end
	
	return false
end

-- returns tile object based on tile coordinate
-- get_tile(int_tilex,int_tiley)
function get_tile(tx,ty)
	if tx<=map_tilew and tx>0 and ty<=map_tileh and ty>0 then
		return level_grid[tx][ty]
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
-- tile_to_px(int_tilex,int_tiley)
function tile_to_px(tx,ty)
	local px=(tx*16)-16
	local py=(ty*16)-16
	return px,py
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
			t.x,t.y=tile_to_px(tx,ty)
			
			if t.occupant==occupant then
				add(list,t)
			end
		end
	end

	return list
end

-- Returns array of actors that are either huggers or aliens
function get_aliens()
	local t={}
	for a in all(actors) do
		if a.id==1 or a.id==2 then add(t,a) end
	end
	
	return t
end


-- returns object of tile that is closest to provided pixel coordinate
-- nearest_tile_oftype(int_pixelx,int_pixely, str_occupanttype)
function nearest_tile_oftype(x,y,oftype)
	return find_nearest(x,y, filter_tiles(oftype))
end

-- finds nearest object based on x/y pixel coordinates
-- list objects must have x/y values!!
-- find_nearest(int_pixelX,int_pixelY, tbl_items)
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

	return n
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
	create_screen(rand(map_w)+1,rand(map_h)+1, read_spritelayout(0,0))
	printh(p_x)
	printh(rand(map_w)+1)
	printh(rand(map_h)+1)
	
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
	
	
	-- add snipers to level
	if #snipers>0 then
		printh("snipers")
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
			level_grid[t.tx][t.ty].spr=rnd_table({3,34,68})
		end
	end
end


-- creates map plots based on a 8x8 sprite
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
				tile.spr=rnd_table({3,34,68})
				tile.w=false
			end
			
			-- rock wall
			if pxc==6 then 
				tile.occupant="wall"
				tile.spr=rnd_table({38,70})
				tile.w=false
			end
			
			-- sniper/bush
			if pxc==3 and current_level.snipers>0 then 
				tile.occupant="sniper"
				tile.spr=rnd_table({3,34,68})
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

			-- player start; doesn't change tile attrs
			if pxc==8 then
				p_x,p_y=tile_to_px(tilex,tiley)
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
	local oy=64+(spry*8)
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
	x1=((x-1)*2)
	y1=((y-1)*2)
	x2=((x-1)*2)+2
	y2=((y-1)*2)+2

	rectfill(x1,y1, x2,y2, c)
end

function generate_minimap() 
	minimap={}

	minimap_txt_bio=0
	minimap_txt_eggs=0
	minimap_radar=0
	
	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=level_grid[x][y]

			if plot.occupant=="body" or plot.occupant=="egg"  then
				add(minimap, {x=x,y=y,c=11})
				minimap_txt_bio+=1
				
				if plot.occupant=="egg" then minimap_txt_eggs+=1 end
			end
			
			if plot.occupant=="transport" then add(minimap, {x=x,y=y,c=12}) end
		end
	end
	
	for a in all(get_aliens()) do
		add(minimap, {x=a.tx,y=a.ty,c=11})
		minimap_txt_bio+=1
	end

	add(minimap, {x=p_tx,y=p_ty,c=10}) --player position
end


function minimap_update()
	minimap_radar+=1
	if minimap_radar>35 then 
		
		radar_dots={}
		
		for a in all(get_aliens()) do
			if in_range(a.cx,a.cy, p_cx,p_cy, 64) then
				local rx,ry=get_line(106,64,13, atan2(a.cx-p_cx, a.cy-p_cy))
				add(radar_dots,{x=rx,y=ry})
			else
				if in_range(a.cx, a.cy, p_cx,p_cy, 128) then
					local rx,ry=get_line(106,64,9, atan2(a.cx-p_cx, a.cy-p_cy))
					add(radar_dots,{x=rx,y=ry})
				end
			end
		end
	end
	
	if minimap_radar>130 then minimap_radar=0 end
end

function minimap_draw()
	rectfill(0,0, 127,116, 5) --base grey
	
	--sidebar
	rectfill(87,45, 125,84, 1)
	pset(106,64,12)
	circ(106,64,8,12)
	circ(106,64,17,12)
	
	circ(106,64,minimap_radar,7) -- growing circle
	
	for d in all (radar_dots) do
		circfill(d.x,d.y,1,7)
	end
	
	print("eggs: "..minimap_txt_eggs.."\n\nbios: "..minimap_txt_bio.."\n\ncargo: "..egg_count, 87, 4, 7)
	
	
	-- chrome
	rectfill(85,0, 127,45, 5)
	rect(85,45, 127,85,5)
	rect(86,45, 126,85,5)
	rectfill(0,85, 127,116, 5) --base grey
	rect(0,0, 85,85, 5)
	line(0,115,127,115, 0)

	--level minimap; 116 is lower limit
	rectfill(1,1, 84,84, 0) --full bg, blue
	rectfill(2,2, (map_tilew*2)+2,(map_tileh*2)+2, 3) --level bg, black
	rect(1,1, (map_tilew*2)+3,(map_tileh*2)+3, 11) --border

	-- draw dots	
	for mm in all(minimap) do
		minimap_dot(mm.x+1,mm.y+1,mm.c)
	end
	
	local item="none"
	if p_st==2 then item="pulse rifle" end
	if p_st==3 then item="alien bait" end

	print("planet: "..current_level.name.."\n\nitem: "..item, 4, 90, 7)
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
	local list=split("bait only works on adult aliens;"..current_level.eggs.." eggs remaining;use \142 to scan area;camo aliens cannot be killed;camo alien attack paralyzes;scanner will recharge over time;scanning uses battery power;bait only lasts a few moments;baby aliens search for bodies;use your items wisely;aliens will attack if you get too close")
	add_ticker_text(rnd_table(list)..";")
	printh("generic text")
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
	spr(23, 96,120)
	pal()

	 --egg count
	spr(16, 110,119)
	print(eggs_collected,120,120, 6)
end


-- #levels - define levels

levels={}
levels[1]={name="pv418",w=2,h=3,bodies=2,eggs=1,eggtimer=480,snipers=0,colors=false}




-- #game
function game_init(levelid)
	current_level=levels[levelid]
	
	ticker_text = {}
	bullets     = {}
	actors      = {}
	
	minimap_x,minimap_y=4,4
	minimap_battery = 0
	map_mode        = false
	egg_timer       = current_level.eggtimer
	egg_count       = 0
	
	
	p_init()
	generate_map(current_level.w,current_level.h)
	add_bodies(current_level.bodies)
	add_eggs(current_level.eggs)
	
	add_ticker_text("arrival on "..current_level.name..";scan shows "..current_level.eggs.." eggs in vicinity;find eggs before they hatch")
	
	
	if levelid==1 then
		add_ticker_text("press \142 to scan area;press \151 to use item;")	
	end
	
	cart(game_update,game_draw)
end


function game_update()
	for a in all(actors) do
		a.update(a)
	end
	
	
	-- #eggtimer
	egg_timer-=1
	if egg_timer<=0 then
		local t=get_random_tile("egg")
		if t then
			add_ticker_text("egg hatch detected;avoid close proximity",true)
			
			current_level.eggs-=1
			if current_level.eggs<=0 then
				add_ticker_text("no more eggs detected;return to transport beacon immediately")
			else
				add_ticker_text(current_level.eggs.." eggs remaining")
			end
			
			add_hugger(t.tx,t.ty)
			set_tile_occupant(t.tx,t.ty,"empty")
			egg_timer=current_level.eggtimer	
		end
	end

	
	if gt>=1200 then -- toss in generic messages every 8 seconds 
		if current_level.eggs<=0 then
			add_ticker_text("no more eggs detected;return to transport beacon immediately")
		else
			ticker_common()
		end
		
		gt=0
	end
	
	if map_mode then
		minimap_update()
	end
	
	bullet_update()
	ticker_update()
	p_update()

end


function game_draw()
	camera(p_cx-64, p_cy-64)
	
	if current_level.colors then
		local swap_bright=current_level.colors[1]
		local swap_dark=current_level.colors[2]
		
		
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
				spr(7,px,py+3,2,1)
			end
			
			if plot.occupant=="transport" then
				spr(10,px,py,2,2)
			end
			
			if plot.occupant=="egg" then
				spr(36,px,py,2,2)
			end
			
			
			
			if swap_bright then
				pal(11,swap_bright)
				pal(3,swap_dark)
			end
			
			if plot.occupant=="wall" then
				spr(plot.spr, px, py, 2,2)
			end
			
			if plot.occupant=="sniper" then
				spr(66, px, py, 2,2)
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

	-- non-player actors; aliens, items
	for a in all(actors) do
		a.draw(a)
	end
	--pal()
	
	
	-- player
	--palt(2,true)
	--palt(0,false)
	
	if p_freeze>0 then pal(10,13) end
	
	bullet_draw()
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
	
end




-- #scenes


-- #nextlevel
function scene_nextlevel()
	cart(nextlevel_update,nextlevel_draw)
end

function nextlevel_update()
	
end 

function nextlevel_draw()
	
end


-- #title
function scene_title()
	cart(title_update,title_draw)
end

function title_update()
	
end 

function title_draw()
	
end


-- #gameover
function scene_gameover()
	cart(gameover_update,gameover_draw)
end

function gameover_update()
	
end 

function gameover_draw()
	
end




-- #loop
function _init()
	printh("\n\n=====new load================================================\n\n")
	
	
	eggs_collected=0 --total eggs collected by player for game session
	level_grid={}
	level_list={}

	game_init(1)
end

function _update60()
	btnl=btn(0)
	btnr=btn(1)
	btnu=btn(2)
	btnd=btn(3)
	--btnz=btn(4)
	--btnx=btn(5)

	--btnlp=btnp(0)
	--btnrp=btnp(1)
	--btnup=btnp(2)
	--btndp=btnp(3)
	btnzp=btnp(4)
	btnxp=btnp(5)
	
	cart_update()
	

	gt+=1
end

function _draw()
	cls()
	cart_draw()

	
	-- memory debug
	camera(0,0)
	print(flr((stat(0)/1024)*100).."%",100,0,8)
end








--
-- #utility functions and libraries
--

function chg_st(o,ns) 
	o.t=0 o.st=ns 
	printh("change state: "..ns)
end

function rand(x) return flr(rnd(x)) end

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
	n=round(rnd(max-min))+min
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
0000000022222222ddddd22200000000000000000000000000000000a0a0000aaa2222220000060000000000000c000000000000000000000000000000000000
000000002222222ddddddd2200000000000000000000000000000000a0a0aa0000222222000006000000000000c0c00000000000000000000000000000000000
00000000222222d2000dd0d2000000b0000000000000000030000000aa0aaaaa02222222000aaa00000000000ccc000000000000000000000000000000000000
0000000022222222ddd0dddd000000bb00003300003000303030030000000aaaa0aaa00a00aaaaa000000ddd00c0000000000000000000000000000000000000
0000000022222d2dd00d2d0d000000bbb0033000000000000000000020aa0aa00aaaaaaa000aa0a0000cc0ddd000000000000000000000000000000000000000
00000000222222dd0dd222d2003330b0bb03300000000000000000002aa000aaa022222200aaaa0000cccc0d0000000000000000000000000000000000000000
00000000222d2ddd0dd22222000330bb0b000000000000000000000020a02222aa022222000aa00000c0ccc00d00000000000000000000000000000000000000
000000002222ddddd0dd22220000300bb0bb00000030030000000000220a02222aa022220000600000c0cccc0000000000000000000000000000000000000000
000000002d22dddd000dddd000000bbb0bbbb0003030300300030000bbbbbbb00000000000006000000c0ccccccc000000000000000000000000000000000000
000dd0002d2dd0d0dd000d0d0000bb0bb0bbb0000000000000000000b00000bb0000000000060000000000000000000000000000000000000000000000000000
00dd0d00d22dd000dd2222d20000b0bbb00bbb000000000000000000b0b0b0bb000000000006000000000d0ddd00000000000000000000000000000000000000
0dddd0d02dd22dd22dd22222000b0bbb03300b000000000000000000b00000bb0000000000060000000000000000000000000000000000000000000000000000
0ddd0dd022222d2222d22222000bbb00033000000000000000030000bbbbbbb0000000000060000000d0ddddddddd00000000000000000000000000000000000
0dddd0d022222dd22dd2222200bb0000003000000000000003030030000000000000000030600300000000000000000000000000000000000000000000000000
00dddd00222222222ddd2222000000000000000003000030030303000000000000000000306030030c0cc0ccc0cc0c0000000000000000000000000000000000
00000000222222222222222200000000000000000000000000000000000000000000000003333030000000000000000000000000000000000000000000000000
2222222aa22222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222222aaaa2222220000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222222aa002222220000300b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222a00aa2222220000300b000300b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222aaaa00a2222200b0030bb00300b00000000dd000000000000000000000000000055555000000000000000000000000000000000000000000000000000000
222aa0aaaaaa222200b0030bb0330bb0000000dd0d00000000000000000000000000555555500000000000000000000000000000000000000000000000000000
222aa0aaaa0a222200bb030bb0330bb000000dddd0d0000000000066605500000005005000000000000aaa000000000000000000000000000000000000000000
222a000aaa00a222000b030bbb00bb0000b0dddd0d0d00000000666660555000005505050000505000aaaaa00a0a000000000000000000000000000000000000
222aa0a0a0a0a222000bb00bbb00bb000000ddddd00d00b000066666605550000050500005005050000aa0a000a0a00000000000000000000000000000000000
2222a0aa0aa22222000bb00bbb0bbb000b00dddd0d0d00000006666660555500000000000005050000aaaa0aa8a0a00000000000000000000000000000000000
222220aa0aa222223000bb0bbbb0bb0000b00dd0d0d000b000066666605555000000000005555050000aa0008a0a800000000000000000000000000000000000
22222aa222aa22220300bb0bbbb0b0000b0b00dd0d000000006666666005550005000005500005550008800a000a080000000000000000000000000000000000
2222aa2222aa22220330bbb0bbb0003000b000000000b0b000666666660555505050bb050b05a0bb0000a00880a0a00000000000000000000000000000000000
2222aa22222aa22200330bb0bbbb03300000b000000b0000006666666605555050b5005b0b505b5508880a888808888000000000000000000000000000000000
22222aa22222222200000bbb0bbb0000000000b0b00000000006666666055500bb00b500b50b5050000880800080000000000000000000000000000000000000
2222222222222222000000000000000000000000000000000000006666050000000b00bb00bbb00b000000000000000000000000000000000000000000000000
222222aa222222220000033333330000000000000b00000000000000000000002222222222222222000000000000000000000000000000000000000000000000
22222aaaa2222222000333333333330000300000bbb0000000000000000000002222222222222222000000000000000000000000000000000000000000000000
22aa2aa00222222200333333330033300033000bb0b0000000006660500000002222222222222222000000000000000000000000000000000000000000000000
22a0a00aa22222220333300003300333003330bb0bb000300006666055000000222222f222222222000000000000000000000000000000000000000000000000
222aaaa00a222222033300bbb0333333003330bb0bb0333000066060555000002222ff2f2ff22222000000000000000000000000000000000000000000000000
22aa0aaaaaa2222233000b000b033303000000bbbb03303000066660555000002222f222f2222222000000000000000000000000000000000000000000000000
2aaa000aa0a222223300b0330b00003000bbb00bb03303300006006005550000222ff22222222222000000000000000000000000000000000000000000000000
a0a00aa00002aa22000b03330bb000000bbbbbbbb00033000066666605550000222ffff222ff2222000000000000000000000000000000000000000000000000
a0aa0aaaaaaaaaa2000b033000003330bb0000bbbbb030300060060605550000222ffffffff0f222000000000000000000000000000000000000000000000000
a00aa0aa0002aa22000bb033300330330bbbbbb0b0bb03300066666605555000222fffffffff2222000000000000000000000000000000000000000000000000
2aa0000a0a02222200b000003333330300bbbb00bb0bb03000600066055550002222fff22ff2f222000000000000000000000000000000000000000000000000
2220aa000aa2222200bb0bb000000300000000b0bbb0b000066660660055550022222222f2f22f22000000000000000000000000000000000000000000000000
222aa0222aa2222200bbbb0bb0000000000bb0bb0bb0b00006606606605555002222222f2f22f222000000000000000000000000000000000000000000000000
222aa02222aa2222b00bb00b00000000000b0bb000bbb00006666666605555002222222222222222000000000000000000000000000000000000000000000000
2222aa2222222222bb0000bb0bbb0000000bbb00000bb00006666666605555002222222222222222000000000000000000000000000000000000000000000000
22222222222222220bb00bbbbb0bb00000bbb000000b000000066666605550002222222222222222000000000000000000000000000000000000000000000000
222aa222222222a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22aaaa2222222a220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22aa00222222a2220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a00aa22222a22220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa0000a222a222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaa0aa0aaa2222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20aa00000a2222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
200aaaaaa22222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000aa22222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20aa00a0022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20a00a20022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20a2a22a022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a02222aa22222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa02222aaa2222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2aa22222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb0000bb0bb00bbb0000fffb0000000000000fbbbbb0000000b00000000bfbfb00000bbb00000000b000fffb0000000000000f60000000000000000000000000
b000000bbff00fff0000ffb00000000000000ffb0000000000f3ffff0003fbfb00ff00000b0000b03000f3bb00bbbbb06ffffff00bbfbbb0bbb3ff6000000000
00000000bff00000b300bb00000000000fff00000000000000fbbbbb000bfbfb00fb00000bfffbb0b0f0f0000bffff300f0fff000bb66bb000fffff000000000
00000c0000000000000000000fff00000f6f0000000000000000000000000b000ff3000000bbb00000ffff0000f00fb00b0fb6000f36fff00fbbbbf000000000
00000000000003000bb000000f6f000b0f6fff000bbb300b0bbbff00030000000ffb0b000fffff000ff6f0000ff00ff0000ff6f00fb6f0000ffffff000000000
00608000bff00bfbbff0bbb00ffb30030fff6f000bfffffbbffb6f000fbff000bffbffbbbf6ffff300f6ff0303bfff000ffffff00ff6ff000fbfbbb000000000
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

__gff__
0000000202000000000000000000000001000002020000000000000000000000000002020000020200000000000000000000020200000202000000000000000000000000020200000000000000000000000000000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000050600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000151600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001516000000000000050600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0506000000000000000000151600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000015160000000000000000000506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005060000000000050600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000015160000000000151600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000050600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000151600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000001516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
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
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

