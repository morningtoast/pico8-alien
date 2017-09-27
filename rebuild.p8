pico-8 cartridge // http://www.pico-8.com
version 10
__lua__

ver="v1.0"

ef=function() end
cart=function(u,d) cart_update,cart_draw=u,d gt=0 end
cart(ef,ef)

-- constants
p_hbox={y=4,x=4,w=7,h=7}
gt=0


-- #player
function p_update()
	if not mini_mode and p_freeze==0 then
		mini_batt=max(mini_batt-1,0)
		
		p_cx=p_x+8
		p_cy=p_y+8
		
	    p_tx,p_ty=px_to_tile(p_cx,p_cy)
		p_dx,p_dy,p_xdir,p_ydir=0,0,0,0
	    
		--debug=p_tx..","..p_ty
		
	    local tile=get_tile(p_tx,p_ty)
		
		if btnl	then p_xdir=-1 p_flip=true end
		if btnr	then p_xdir=1 p_flip=false end
		if btnu	then p_ydir=-1 end
		if btnd	then p_ydir=1 end
	
		p_dx=p_spd*p_xdir
		p_dy=p_spd*p_ydir
	
		if not move_is_blocked(p_x,p_y, p_dx,p_dy, p_hbox) then
			p_x+=p_dx
			p_y+=p_dy	
		end
	    
	    p_tiles(tile)

		-- actions
		if btnxp and p_st==2 then
			-- @sound bullet noise
			p_bullet()
			p_st,p_spr=1,32
		end
	
		if btnxp and p_st==3 then
			-- @sound bait noise
			add_bait(p_cx,p_cy)
			p_st,p_spr=1,32
		end
		
		if btnzp then
			if mini_batt<=0 then
				mini_mode=true
				gen_mini()
			else
				tkr("scanner battery recharging",true)
			end
		end
	else
		-- in mini mode
		if btnzp and p_freeze==0 then
			mini_mode=false
			mini_batt=sec(7)
		end
	end --end mini_mode check
	
	
	if p_freeze>0 then
		p_freeze=max(0,p_freeze-1)
	end
end

function p_draw()
	if p_freeze>0 then pal(10,13) end
	spr(p_spr, p_x,p_y, 2,2, p_flip)
end


function p_tiles(tile)
	-- when player gets to a body, switch modes
	if tile.o==4 then
		if rnd()<.5 then
			p_st,p_spr=2,64
			tkr("pulse rifle equipped",true)
		else
			p_st,p_spr=3,96
			tkr("bait equipped",true)
		end

		tile_attr(p_tx,p_ty)
	end
	
	
	-- when player gets to a egg
	if tile.o==3 then
		eggs_collected=min(eggs_collected+1,20)
		curlvl.eggs=max(curlvl.eggs-1,0)

		if eggs_collected<20 then
			tile_attr(p_tx,p_ty)

			tkr("alien egg collected",true)
		else
			if tile_t==0 then
				tkr("cargo bay is full;return to transport beacon",true)
			end
		end
		tile_t+=1
	else
		tile_t=0
	end
	
	
	-- #transport
	-- player hits transport beacon
	if tile.o==6 then
		transport_st=1
		
		if curlvl.eggs>0 and eggs_collected<20 and transport_t==0 then
			-- @sound buzzer
			tkr("dropship unavailable;find remaining eggs",true)
		end
		
		if (curlvl.eggs<=0 or eggs_collected==20) then
			if transport_t==0 then
				tkr("dropship landing, stay at beacon;leaving "..curlvl.name,true)
			end
			
			if transport_t==sec(9) then
				if eggs_collected==20 then
					--finale_init()
				else
					start_init()	
				end
				
			end
		end
		
		transport_t+=1
	else
		if transport_st==1 then
			tkr("dropship canceled",true)
			transport_st=0
		end
		
		transport_t=0
	end
end

function p_bullet()
	-- create player bullet object
	local targets={}
	local obj={x=p_cx,y=p_y+5,c=10}
	local heading=0
	
	if p_flip then heading=.5 end

	for a in all(actors) do
		if a.id<3 then -- only target huggers and aliens, not snipers
			if in_range(a.cx,a.cy, p_cx,p_cy, 60) then
				add(targets,a)
			end
		end
	end

	if #targets>0 then
		local target = find_nearest(p_cx,p_cy, targets)
		heading      = atan2(target.cx-p_cx, target.cy-p_cy) 
	end

	obj.dx,obj.dy = dir_calc(heading, 3)
	obj.update=function(self)
		for a in all(actors) do
			if a.id<3 and in_range(self.x,self.y, a.cx,a.cy, 10) then
				chg_st(a,99)
				del(bullets,self)
			end
		end
	end
	

	add(bullets,obj)	
end


function p_dead()
	-- @sound death blow, only once
	blood_t=make_blood()
	tkr("game over;press \142 to continue",true)
	gt=0
	gameover=true
	level_list={}
	p_spr=46
end




-- #level #start
function start_init()
	level_id+=1
	
	local levels={
		{name="tester",w=6,h=6,bombs=0,bodies=10,eggs=5,eggtimer=30,aliens=5,snipers=5,colors={11,3}},
		{name="jl-78",w=3,h=3,bombs=0,bodies=2,eggs=1,eggtimer=40,aliens=0,snipers=0,colors={11,3}},
		{name="col-b",w=4,h=4,bombs=0,bodies=3,eggs=2,eggtimer=35,aliens=1,snipers=0,colors={11,4}},
		{name="pv-418",w=5,h=4,bombs=0,bodies=5,eggs=4,eggtimer=35,aliens=3,snipers=1,colors={14,2}},
		{name="gva-1106",w=6,h=3,bombs=0,bodies=7,eggs=5,eggtimer=40,aliens=4,snipers=3,colors={9,4}}
	}
	
	
	if level_id>4 then
		local colors={{3,4},{11,9},{11,4},{15,14}}
		local abc=split("a;b;c;d;e;f;g;h;i;j;k;l;m;n;o;p;q;r;s;t;u;w;v;y;z")
		local name=rnd_table(abc)..rnd_table(abc).."-"..random(75,850)
		local mw=random(3,6)
		local mh=random(3,6)
		local me=random(4,6)
		local mb=me+random(1,3)
		local ma=random(2,5)
		local ms=random(3,6)
		
		if level_id>10 then
			--if mw<5 then mh=max(7,mh+1) end
			if mh<5 then mw=max(7,mw+1) end
			
			me+=1
			mb+=1
		end
		
		curlvl={name=name,w=mw,h=mh,bodies=mb,eggs=me,eggtimer=35,aliens=ma,snipers=ms,bombs=0,colors=rnd_table(colors)}	
	else
		curlvl=levels[level_id]
	end
	
	
	function start_update()
		if btnzp or btnxp then play_init() end
	end
	
	
	function start_draw()
		draw_console()
		
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
	
	cart(start_update,start_draw)
	
end


function draw_console(nologo)
	rectfill(0,0,128,128,0)
	rect(0,0, 127,127, 12)
	rect(2,2, 125,93, 12)

	rect(89,95, 125,125, 12)
	rect(2,95, 87,125, 12)

	if not nologo then zspr(74,2,2,90,103, 2, 1) end
	
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




-- #game play 
memhi=0
function play_init()
	
	
	-- vars that need reset per level
	p_x,p_y,p_spd,p_spr=64,64,1,32
	p_cx,p_cy=p_x+8,p_y+8
	p_st,p_flip,p_freeze=0,false,0 -- state: 1=unarmed, 2=gun, 3=bait
	egg_hatch=sec(curlvl.eggtimer)
	transport_st=0
	
	tkr_x=105
	tkr_end=105
	tkr_log={}
	
	
	mini_mode=false
	mini_batt=0
	
	actors={}
	bullets={}

	gen_map(curlvl.w,curlvl.h)
	
	memhi=0
	
	local arrival="arrival on "..curlvl.name
	if finale then
		tkr(arrival..";find and arm 3 bombs;find detonator to start countdown",true)
	else
		tkr(arrival..";find eggs before they hatch;scan shows "..curlvl.eggs.." eggs in range",true)	
	end
	
	if curlvl.snipers>0 then
		tkr("jungle alien attacks paralyze")
	end

	if level_id==1 then
		tkr("press \142 to scan area;press \151 to use weapon")	
	end
			
	cart(play_update,play_draw)
end

function play_update()
	if curlvl.eggs>0 then
		egg_hatch=max(0,egg_hatch-1)
		
		if egg_hatch<=0 then
			local t=get_random_tile(3)

			curlvl.eggs-=1
			egg_hatch=sec(curlvl.eggtimer)
			
			add_hugger(t.tx,t.ty)
			tile_attr(t.tx,t.ty)

			
			tkr("new life form detected",true)
			
			if not finale then
				if curlvl.eggs<=0 then
					tkr("no eggs detected;return to transport beacon")
				else
					tkr(curlvl.eggs.." eggs remaining")
				end
			end
		end
	end
	
	
	if not gameover then
		for a in all(actors) do 
			a.update(a)
			a.t+=1
		end

		p_update()
	else
		--#dead gameover
		if btnzp and gt>=sec(1) then
			title_init()	
		end
		
		if blood_t>sec(4) then
			blood_t=make_blood()
		end
		
		if gt==sec(10) then
			tkr("game over;press \142 to continue",true)
		end
		
		blood_t+=1
	end

	bullet_update()
	tkr_update()
end

function play_draw()
	camera(p_cx-64, p_cy-64)
	palt(2,true)
	palt(0,false)

	draw_map()
	
	bullet_draw()
	p_draw()
	for a in all(actors) do a.draw(a) end
	pal()
	
	camera(0,0)
	tkr_draw()

	if mini_mode then draw_mini() end
	
	
	if gameover then
		for b in all(blood) do circfill(b[1],b[2],b[3], 8) end
	end
end




function make_blood()
	if #blood<45 then
		for n=0,15 do
			add(blood,{random(34,94),random(34,94),random(5,9)})
		end
	
		for n=0,18 do
			add(blood,{random(14,114),random(14,115),random(1,3)})
		end
	end	
	
	return 0
end


-- #ticker

function tkr(t,c)
	local list=split(t)
	if c then tkr_log={} end
	for t in all(list) do 
		add(tkr_log,{t,(#t*4)}) 
	end
	if c then tkr_next() end
end

function tkr_next()
	tkr_txt=tkr_log[1][1]
	tkr_end=0-tkr_log[1][2]
	printh(tkr_txt)
	del(tkr_log, tkr_log[1])
	tkr_x=105 
end

function tkr_update()
	if tkr_x>tkr_end then
		tkr_x-=.8
			
		if tkr_x<=tkr_end and #tkr_log>0 then tkr_next() end
	end
end

function tkr_draw()
	rectfill(0,117, 127,127, 1)
	
	if tkr_x>tkr_end then print(tkr_txt, tkr_x,120, 12) end

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




-- #minimap
-- 0=empty;1=wall;2=spawn;3=egg;4=body;5=sniper;6=beacon;7=bomb;8=detonator;9=queen;99=grass
function gen_mini() 
	minimap={}

	mini_x,mini_y=0,0

	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=grid[x][y]

			if plot.o==4 or plot.o==3 then add(minimap, {x=x,y=y,c=11}) end
			if plot.o==6 then add(minimap, {x=x,y=y,c=12}) end
		end
	end
	
	for a in all(actors) do
		if a.id<3 then add(minimap, {x=a.tx,y=a.ty,c=11}) end
	end
	
	add(minimap, {x=p_tx,y=p_ty,c=8})
end


function draw_mini()
	draw_console(1)
	
	rectfill(mini_x+6,mini_y+6, (map_tilew*2)+mini_x+8,(map_tileh*2)+mini_y+8, 3)
	rect(mini_x+6,mini_y+6, (map_tilew*2)+mini_x+8,(map_tileh*2)+mini_y+8, 11)
	
	for dot in all(minimap) do
		x1=((dot.x-1)*2)+mini_x+7
		y1=((dot.y-1)*2)+mini_y+7
		print("+",x1,y1-1,dot.c)
	end
	
	print("+you",92,100,8)
	print("+beacon",92,108,12)
	print("+bio",92,116,11)
end



-- #title
function title_init()
	finale=false
	level_id=0
	eggs_collected=0
	gameover=false
	grid={}
	level_list={}
	blood={}
	levels={}
	
	-- #levels - define levels
	-- w/h=screen size; eggtimer=seconds to hatch; colors=array of primary,secondary
	
	

	
	function title_update()
		if btnzp then start_init() end
		if btnxp then help_init() end
	end 
	
	function title_draw()
		print("alien harvest\n\npres \142 to start\npress \151 for help",0,0,7)
	end
	
	cart(title_update,title_draw)
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
		print("jungle aliens attack\nparalyzes you. cannot kill",22,93, 7)

		pal()
	end
	
	cart(help_update, help_p1)
end







-- #bullets
function bullet_update()
	for b in all(bullets) do
		b.x+=b.dx
		b.y+=b.dy

		if b.x<map_wpx and b.x>1 and b.y<map_hpx and b.y>1 then
			local t=get_px_tile(b.x,b.y)
			if t.o==1 then
				local px,py,cx,cy=tile_to_px(t.tx,t.ty)
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
-- #bait3
function add_bait(x,y)
	local obj={
		id=3,
		x=x,y=y,
		cx=x+8,cy=y+8,
		t=0,
		update=function(self)
			for a in all(actors) do
				if a.id==2 then
					if in_range(a.cx,a.cy, self.cx,self.cy, 50) then
						local release=sec(5)-self.t
						
						chg_st(a,10)
						a.bait={x=self.cx,y=self.cy,release=release}
					end
				end
			end
		
			
			if self.t>sec(6) then del(actors,self) end
		end,
		draw=function(self)
			spr(11, self.x,self.y, 1,2)
		end
	}	

	
	add(actors,obj)
end

-- #sniper4
function add_sniper(tx,ty)
	local obj={
		id=4,
		tx=tx,ty=ty,
		flip=false,
		st=1,t=1,
		update=function(self)
			local ox=self.x+16
			local oy=self.y+4
			
			if self.flip then
				ox=self.x-32
				oy=self.y+4
			end
			
			if self.st==1 then

				if in_box(p_cx,p_cy, ox,oy, 32,8) then
					--printh("sniped!")
					
					-- @sound sniper shot
					local obj={
						dx=4,x=self.x+16,y=self.y+8,
						c=13,dy=0,
						update=function(b)
							if in_range(b.x,b.y, p_cx,p_cy, 8) then
								p_freeze=sec(3)
								del(bullets,b)
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
					local t=tile_attr(self.tx,self.ty,"o",1)
					t.s=rnd_table(bush_sprites)
					del(actors,self)
				end
			end
		end,
		draw=ef
	}
	
	
	if tx+1>map_tilew then
		et={o=1}
	else
		et=grid[tx+1][ty]
	end
	
	if tx-1<1 then
		wt={o=1}
	else
		wt=grid[tx-1][ty]
	end

	if et.o!=1 and wt.o!=1 then
		if rnd()<.5 then obj.flip=true end
	else
		if et.o==1 then 
			obj.flip=true
		end
	end
	
	obj.x,obj.y=tile_to_px(tx,ty)
	tile_attr(tx,ty,"flip",obj.flip)

	add(actors, obj)
end


-- #hugger
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
		tile={},
		update=function(self)
			alien_update(self)

			if self.tile.o==4 then
				tile_attr(self.tx,self.ty)
				add_alien(self.tx,self.ty)
				del(actors,self)
			end
			
			if self.st==99 and self.t>sec(3) then
				del(actors,self)
			end
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
		bait=false,
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
		
			alien_update(self)
			
			-- within bait range, go there and sleep
			if self.st==10 then
				local heading   = atan2(self.bait.x-self.x, self.bait.y-self.y) 
				self.dx,self.dy = dir_calc(heading, 1) -- wander speed
				self.flip=sprite_flip(heading)
				self.chase=false
				
				chg_st(self,11)
			end
			
			if self.st==11 then
				if not in_range(self.bait.x,self.bait.y, self.cx,self.cy, 10) then
					if not move_is_blocked(self.x,self.y, self.dx,self.dy, self.hbox) then
						self.x+=self.dx
						self.y+=self.dy
					end
				end
				
				if self.t>=self.bait.release then
					self.bait=false
					chg_st(self,0)
				end
			end
			
			if self.st==99 and self.t>sec(3) then
				del(actors,self)
			end
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


-- #walker - common logic for alien actors that move around the map
function alien_update(self)
	-- self is actor object - id: 1=hugger, 2=alien
	local id=self.id
	local dest={}
	
	self.cx=self.x+8
	self.cy=self.y+8
	self.tx,self.ty=px_to_tile(self.cx,self.cy)
	self.tile=get_tile(self.tx,self.ty)

	-- caught the player; end state and game over
	if self.st<99 then
		if in_range(self.cx,self.cy, p_cx,p_cy, 10) then
			chg_st(self,98)
			p_dead()
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
				near=find_nearest(self.x,self.y, filter_tiles(4))
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
					near=get_random_tile(0) 
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
					if tile.o==4 then
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







-- #map
-- 0=empty;1=wall;2=spawn;3=egg;4=body;5=sniper;6=beacon;7=bomb;8=detonator;9=queen;99=grass
function draw_map()
	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=grid[x][y]
			local px,py=tile_to_px(x,y)
			
			if plot.o==1 then
				pal(11,curlvl.colors[1])
				pal(3,curlvl.colors[2])
				spr(plot.s, px, py, 2,2)
				
			end
			
			if plot.o==4 then
				spr(9,px,py+3,2,1)
			end
            
            if plot.o==3 then
				spr(14,px,py,2,2)
			end
            
            if plot.o==5 then
				spr(42,px,py, 2,2, plot.flip)
			end
				
			if plot.o==6 then
				if transport_st==1 then pal(12,8) pal(13,8) end
				spr(12,px,py,2,2)
			end
			
			if plot.o==99 then
				spr(7,px,py,2,1)
			end
		end
	end
	
	
	-- map edges
	for m=0,map_tileh do
		spr(3, -15, (16*m), 2,2)
		spr(3, map_wpx, (16*m), 2,2)
	end
	
	for m=-1,map_tilew do
		spr(3, (16*m), -15, 2,2)
		spr(3, (16*m),map_hpx, 2,2)
	end
	
	--[[ debug grid
	for n=0,map_tilew do line(n*16,0, n*16,map_hpx, 5) end
	for n=0,map_tileh do line(0,n*16, map_wpx,n*16, 5) end
	for n=0,map_w do line(n*128,0, n*128,map_hpx, 6) end
	for n=0,map_h do line(0,n*128, map_wpx,n*128, 6) end
	]]
end


function gen_map(w,h)
	map_w,map_h=w,h
	map_wpx,map_hpx=map_w*128,map_h*128
	map_tilew,map_tileh=map_w*8,map_h*8
	map_eggs=0
	grid={}
	level_list={}
	
	-- seed grid with all empty
	-- coordinates are for 16x16px blocks; 8 per screen
	
	
	for x=1,map_tilew do
		grid[x]={}
		
		for y=1,map_tileh do
			grid[x][y]={
				tx=x,ty=y,
				n=0,f=0,g=0,h=0,p=0,status=0, --pathfinding vars
				o=0,s=0,
				w=true --is space walkable? true=open,false=blocked
			}
		end
	end
	
	for mx=1,map_w do
		for my=1,map_h do
			create_screen(mx,my, flr(rnd(14))+1,0)
		end
	end
	
	
	create_screen(rand(map_w)+1,rand(map_h)+1, 0,0)
	
	
	local n=1
	local snipers={}
	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=grid[x][y]
			
			level_list[n]=plot
			plot.n=n
			n+=1
			
			-- build list of possible sniper tiles
			if plot.o==5 then add(snipers,plot) end
		end
	end
    
    -- add sniper tiles, pull from pool
    if #snipers>0 then
		for n=1,curlvl.snipers do
			local t=rnd_table(snipers)

            add_sniper(t.tx,t.ty)
            del(snipers,t)
		end
		
		-- turn left over sniper slots into bushes
		for t in all(snipers) do
			grid[t.tx][t.ty].o=1
			grid[t.tx][t.ty].s=rnd_table(bush_sprites)
		end
	end
    
    
    if finale then
    	add_tiles(curlvl.bombs, 2,7, 256,400) --bombs
    end

    add_tiles(curlvl.bodies, 0,4, 100,70) --bodies
    add_tiles(curlvl.eggs, 2,3, 130,130) --eggs

    
    -- add random aliens, not too close to player
	local ac=0
	while ac<curlvl.aliens do
		local t=get_random_tile(0)
		
		if not in_range(t.x,t.y, p_cx,p_cy, 150) then
			add_alien(t.tx,t.ty)
			ac+=1
		end
	end
    
    
    --grass
	local empty=filter_tiles(0)
	local half=flr(((map_w*8)*(map_h*8))*.2)
	for n=0,half do
		local t=rnd_table(empty)
		t.o=99
		t.h=rand(2)+1
	end
	
end


bush_sprites={1,3,5}
function create_screen(mx,my, lx,ly)
	function read_spritelayout(sprx,spry)
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
	
	
	local smap=read_spritelayout(lx,ly)
	for spx=0,7 do
		for spy=0,7 do
			local tilex=spx+1 + (mx-1)*8
			local tiley=spy+1 + (my-1)*8
			local pxc=smap[spx+1][spy+1]
			local tile={o=0,w=true}
			local bspr=rnd_table(bush_sprites)
			
			--bush/rock wall
			if pxc==11 or pxc==3 or pxc==6 then 
				tile.o=1
				tile.s=bspr
				tile.w=false
				
				if pxc==6 then tile.s=rnd_table({76,78}) end
			end

			-- sniper/bush
			if pxc==3 and curlvl.snipers>0 then 
				tile.o=5
				tile.s=bspr
				tile.w=false
			end
			
			-- transport beacon
			if pxc==12 then 
				tile.o=6
			end
			
			-- egg spawn pool
			if pxc==15 then 
				tile.o=2
			end
			
			-- egg
			if pxc==2 then 
				tile.o=2
				map_eggs+=1
			end
			
			-- bomb detonator
			if pxc==14 then 
				tile.o=8
				detonator_st=0
				detonator_t=0
			end
			
			-- queen
			if pxc==9 then 
				tile.o=9
			end
			
			-- player start position
			if pxc==8 then
				p_x,p_y,p_cx,p_cy=tile_to_px(tilex,tiley)
				p_tx,p_ty=tilex,tiley
				
			end
			
			for k,v in pairs(tile) do grid[tilex][tiley][k]=v end

		end
	end	
end






-- #loop

function _init()
	printh("BOOT ----------------------------------------------")
	title_init()
	
end


function _update60()
	btnl=btn(0)
	btnr=btn(1)
	btnu=btn(2)
	btnd=btn(3)
	btnzp=btnp(4)
	btnxp=btnp(5)
	
	cart_update()

	gt=min(25000,gt+1)
end


function _draw()
	cls()
	cart_draw()


	
	
	
	-- debug memory
	camera(0,0)
	local mem=stat(1)
	print(flr((stat(0)/1024)*100).."%m\n"..mem.."\n"..debug,100,0,8)
	if mem>memhi then memhi=mem debug=mem end
end




-- #utilities
debug=0

function chg_st(o,ns) o.t=0 o.st=ns end
function rand(x) return flr(rnd(x)) end
function sec(f) return flr(f*60) end -- set fps here if you need
function center_text(s,y,c) print(s,64-(#s*2),y,c) end

function sprite_flip(d)
	if d>.25 and d<.75 then return true end
	return false
end

function random(min,max)
	n=flr(rnd(max-min))+min
	return n
end

function rnd_table(t)
	local r=flr(rnd(#t))+1
	return(t[r])
end

function distance(ox,oy, px,py)
	local a = abs(ox-px)/16
	local b = abs(oy-py)/16
	return sqrt(a^2+b^2)*16
end

function dir_calc(angle,speed)
	local dx=cos(angle)*speed
	local dy=sin(angle)*speed
	
	return dx,dy
end

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

-- tile_to_px(int_tilex,int_tiley)
function tile_to_px(tx,ty)
	local px=(tx*16)-16
	local py=(ty*16)-16
	local cx=px+8
	local cy=py+8
	return px,py,cx,cy
end

-- px_to_tile(int_pixelx,int_pixely)
function px_to_tile(pxx,pxy)
	local tx=flr(pxx/16)+1
	local ty=flr(pxy/16)+1
	return tx,ty
end

-- get_tile(int_tilex,int_tiley)
function get_tile(tx,ty)
	if tx<=map_tilew and tx>0 and ty<=map_tileh and ty>0 then
		local t=grid[tx][ty]
		--t.x,t.y,t.cx,t.cy=tile_to_px(tx,ty)
		
		return t
	end
end

function get_px_tile(pxx,pxy)
	tx,ty=px_to_tile(pxx,pxy)
	return get_tile(tx,ty)
end

-- filter_tiles(occupantId)
function filter_tiles(o)
	local list={}
	
	for tx=1,map_tilew do
		for ty=1,map_tileh do
			local t=grid[tx][ty]
			t.x,t.y,t.cx,t.cy=tile_to_px(tx,ty)
			t.tx,t.ty=tx,ty
			if t.o==o then
				add(list,t)
			end
		end
	end

	return list
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


-- #in_range(int_needlex,int_needley, int_haystackx,int_haystacky, int_distance)
function in_range(ax,ay, bx,by, rng)
	--[[
	printh("seeing if "..ax..","..ay.." is in range of "..bx..","..by.." w distance of "..rng)
	printh("...is "..ax..">="..bx-rng)
	printh("...is "..ax.."<="..bx+rng)
	printh("...is "..ay..">="..by-rng)
	printh("...is "..ay.."<="..by+rng)
	]]
	
	if ax>=bx-rng and ax<=bx+rng and ay>=by-rng and ay<=by+rng then
		--printh("IN RANGE")
		return true
	end
	
	--printh("NOT in range")
	
	return false
end

-- tile_attr(x,y, keyName, value)
function tile_attr(tx,ty, key, value)
	if not key then	key="o" value=0 end
	
	grid[tx][ty][key]=value
	return grid[tx][ty]
end

-- get_random_tile(occupantId)
function get_random_tile(occ)
	local list=filter_tiles(occ)
	
	if #list>0 then
		return rnd_table(list)
	end
	
	return false
end

function zspr(n,w,h,dx,dy,dz,fx,fy)
  sx = 8 * (n % 16)
  sy = 8 * flr(n / 16)
  sw = 8 * w
  sh = 8 * h
  dw = sw * dz
  dh = sh * dz

  sspr(sx,sy,sw,sh, dx,dy,dw,dh, fx,fy)
end

-- add_tiles(quantity, sourceTileId, occupantId, distanceOccupantId, distanceFromPlayer, callback)
function add_tiles(q, src, occ, od, pd, f)
	for n=1,q do
		local try=1
		local list=filter_tiles(occ)
		while try>0 do
			local t=get_random_tile(src)
			
			if #list>0 then
				for n in all(list) do
					if try>0 then
						if not in_range(t.x,t.y, p_cx,p_cy, pd) then
							if not in_range(t.x,t.y, n.x,n.y, od) then
								tile_attr(t.tx,t.ty, "o", occ)
								if f then f(t.tx,t.ty) end
								try=0
							end
						end
					end
				end
			else
				if not in_range(t.x,t.y, p_cx,p_cy, pd) then
					tile_attr(t.tx,t.ty, "o", occ)
					if f then f(t.tx,t.ty) end
					try=0
				end
			end
		end
	end
end

-- point in hitbox
-- #in_box(x,y, objX,objY,objHitbox)
function in_box(x,y, ox,oy,ow,oh)
	if x>=ox and x<=ox+ow and y>=oy and y<=oy+oh then
		return true
	end
	
	return false
end

-- #move_is_blocked(int_objpixelx,int_objpixely, int_objpixeldx,int_objpixeldy, tbl_objhitbox)
function move_is_blocked(px,py, dx,dy, hbox)
	function blocktile(t) 
		if t.o==1 or t.o==5 then return true end
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
		
		return false
	else
		return true
	end
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
001000000d7700c7700a7001270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

